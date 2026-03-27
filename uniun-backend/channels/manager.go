package channels

import (
	"encoding/json"
	"fmt"
	"sync"
	"time"

	fn "fiatjaf.com/nostr"

	"uniun-backend/logger"
)

// ChannelMeta holds the relay-side state of a channel.
type ChannelMeta struct {
	ID            string    // kind-40 event ID
	Name          string    // from kind-40 content
	CreatorPubKey fn.PubKey // pubkey that created the channel
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

// Manager is the central registry for channels and their live subscribers.
// It owns all subscription state — ConnectionStore only owns connection identity.
type Manager struct {
	mu       sync.RWMutex
	channels map[string]*ChannelMeta // channelID → meta
	subs     map[string]*Subscriber  // connID → subscriber (one per connection)
}

// NewManager constructs an empty Manager.
func NewManager() *Manager {
	return &Manager{
		channels: make(map[string]*ChannelMeta),
		subs:     make(map[string]*Subscriber),
	}
}

// RegisterChannel handles an incoming kind-40 event.
// Idempotent — if the channel already exists the call is a no-op.
func (m *Manager) RegisterChannel(event fn.Event) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if _, exists := m.channels[fn.HexEncodeToString(event.ID[:])]; exists {
		logger.Debug("channel already registered, skipping",
			logger.String("channel_id", fn.HexEncodeToString(event.ID[:])[:8]),
		)
		return
	}

	name := extractChannelName(event)

	m.channels[fn.HexEncodeToString(event.ID[:])] = &ChannelMeta{
		ID:            fn.HexEncodeToString(event.ID[:]),
		Name:          name,
		CreatorPubKey: event.PubKey,
		CreatedAt:     time.Unix(int64(event.CreatedAt), 0),
		UpdatedAt:     time.Unix(int64(event.CreatedAt), 0),
	}

	logger.Info("channel registered",
		logger.String("channel_id", fn.HexEncodeToString(event.ID[:])[:8]),
		logger.String("name", name),
		logger.String("creator", fn.HexEncodeToString(event.PubKey[:])[:8]),
	)
}

// UpdateChannelMeta handles an incoming kind-41 event.
// Only the original creator pubkey may update the channel metadata.
func (m *Manager) UpdateChannelMeta(event fn.Event) error {
	channelID := extractRootETag(event)
	if channelID == "" {
		return fmt.Errorf("channel manager: kind-41 missing root e-tag")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	ch, exists := m.channels[channelID]
	if !exists {
		return fmt.Errorf("channel manager: channel %s not found", channelID[:8])
	}

	if ch.CreatorPubKey != event.PubKey {
		return fmt.Errorf("channel manager: pubkey %s is not the creator of channel %s",
			fn.HexEncodeToString(event.PubKey[:])[:8], channelID[:8])
	}

	name := extractChannelName(event)
	ch.Name = name
	ch.UpdatedAt = time.Unix(int64(event.CreatedAt), 0)

	logger.Info("channel metadata updated",
		logger.String("channel_id", channelID[:8]),
		logger.String("name", name),
	)

	return nil
}

// Subscribe registers a connection as a subscriber to one or more channels.
// If the connection already has an active subscription it is replaced.
func (m *Manager) Subscribe(connID, subID string, channelIDs []string, writeFn func(fn.Event)) {
	m.mu.Lock()
	defer m.mu.Unlock()

	// replace existing subscription silently — client sent CLOSE before this
	// but we handle it defensively here too
	if old, exists := m.subs[connID]; exists {
		logger.Debug("replacing existing subscription",
			logger.String("conn_id", connID[:8]),
			logger.String("old_sub_id", old.SubID[:8]),
			logger.String("new_sub_id", subID[:8]),
		)
	}

	m.subs[connID] = NewSubscriber(connID, subID, channelIDs, writeFn)

	logger.Info("gateway subscribed to channels",
		logger.String("conn_id", connID[:8]),
		logger.String("sub_id", subID[:8]),
		logger.Int("channel_count", len(channelIDs)),
	)
}

// Unsubscribe removes a specific subscription by subID from a connection.
// Called when the client sends ["CLOSE", subID].
func (m *Manager) Unsubscribe(connID, subID string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	sub, exists := m.subs[connID]
	if !exists {
		return
	}

	// only remove if the subID matches — don't remove a newer subscription
	// that replaced this one
	if sub.SubID != subID {
		return
	}

	delete(m.subs, connID)

	logger.Info("gateway unsubscribed",
		logger.String("conn_id", connID[:8]),
		logger.String("sub_id", subID[:8]),
	)
}

// UnsubscribeAll removes all subscriptions for a connection.
// Called when the gateway disconnects.
func (m *Manager) UnsubscribeAll(connID string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if _, exists := m.subs[connID]; !exists {
		return
	}

	delete(m.subs, connID)

	logger.Debug("all subscriptions removed for connection",
		logger.String("conn_id", connID[:8]),
	)
}

// BroadcastToChannel pushes a kind-42 event to all subscribers watching
// the channel identified by the event's root e-tag.
// Each write is non-blocking — a slow subscriber does not stall others.
func (m *Manager) BroadcastToChannel(event fn.Event) {
	channelID := extractRootETag(event)
	if channelID == "" {
		logger.Warn("broadcast: kind-42 missing root e-tag",
			logger.String("event_id", fn.HexEncodeToString(event.ID[:])[:8]),
		)
		return
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	sent := 0
	for _, sub := range m.subs {
		if !sub.WatchesChannel(channelID) {
			continue
		}

		// capture loop variable for goroutine
		s := sub
		go func() {
			s.WriteEvent(event)
		}()

		sent++
	}

	logger.Debug("broadcast complete",
		logger.String("channel_id", channelID[:8]),
		logger.String("event_id", fn.HexEncodeToString(event.ID[:])[:8]),
		logger.Int("recipients", sent),
	)
}

// GetChannel returns the metadata for a channel by ID.
// Returns nil if the channel does not exist.
func (m *Manager) GetChannel(channelID string) *ChannelMeta {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.channels[channelID]
}

// extractChannelName pulls the name field from a kind-40 or kind-41
// event's content JSON. Returns empty string if not present.
func extractChannelName(event fn.Event) string {
	var content map[string]any
	if err := json.Unmarshal([]byte(event.Content), &content); err != nil {
		return ""
	}
	name, _ := content["name"].(string)
	return name
}

// extractRootETag returns the value of the first e-tag marked "root".
// Returns empty string if not found.
func extractRootETag(event fn.Event) string {
	for _, tag := range event.Tags {
		if len(tag) >= 4 && tag[0] == "e" && tag[3] == "root" {
			return tag[1]
		}
	}
	return ""
}
