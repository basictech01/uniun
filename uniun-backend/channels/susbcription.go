package channels

import (
	"time"

	fn "fiatjaf.com/nostr"
)

// Subscriber represents one active REQ subscription from a gateway
// listening to one or more channels.
//
// One gateway connection sends all subscribed channel IDs in a single
// #e filter array. When the client updates its channel list it sends
// CLOSE on the old subID then a new REQ — so one connection has at
// most one active channel subscription at a time.
type Subscriber struct {
	// ConnID is the gateway connection UUID from ConnectionContext.
	ConnID string

	// SubID is the Nostr subscription ID from the REQ frame.
	// Used to address ["EVENT", subID, event] responses back to the client.
	SubID string

	// ChannelIDs is the set of channel IDs this subscriber watches.
	// Populated from the #e tag array in the REQ filter.
	ChannelIDs map[string]bool

	// WriteEvent is the function Khatru provides to send an event
	// back to this specific WS connection.
	WriteEvent func(event fn.Event)

	// SubscribedAt records when this subscription was registered.
	SubscribedAt time.Time
}

// NewSubscriber constructs a Subscriber from a REQ.
func NewSubscriber(connID, subID string, channelIDs []string, writeFn func(fn.Event)) *Subscriber {
	ids := make(map[string]bool, len(channelIDs))
	for _, id := range channelIDs {
		ids[id] = true
	}
	return &Subscriber{
		ConnID:       connID,
		SubID:        subID,
		ChannelIDs:   ids,
		WriteEvent:   writeFn,
		SubscribedAt: time.Now(),
	}
}

// WatchesChannel reports whether this subscriber listens to a given channel.
func (s *Subscriber) WatchesChannel(channelID string) bool {
	return s.ChannelIDs[channelID]
}
