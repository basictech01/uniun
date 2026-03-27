package handlers

import (
	"context"

	fn "fiatjaf.com/nostr"

	"uniun-backend/channels"
	"uniun-backend/logger"
	"uniun-backend/store"
)

// QueryHandler handles REQ messages from gateways.
type QueryHandler struct {
	embedded    store.EventStore
	chanManager *channels.Manager
}

// NewQueryHandler constructs a QueryHandler with all dependencies wired.
func NewQueryHandler(
	embedded store.EventStore,
	chanManager *channels.Manager,
) *QueryHandler {
	return &QueryHandler{
		embedded:    embedded,
		chanManager: chanManager,
	}
}

// HandleReq processes a single REQ from a gateway:
//  1. Query BoltDB for historical events matching the filter
//  2. Stream each matching event back via writeEvent
//  3. Send EOSE
//  4. If filter has #e tags, register as channel subscriber for live events
func (h *QueryHandler) HandleReq(
	ctx context.Context,
	subID string,
	connID string,
	filter fn.Filter,
	writeEvent func(fn.Event),
	writeEOSE func(),
) {
	logger.Debug("handling REQ",
		logger.String("conn_id", connID[:8]),
		logger.String("sub_id", subID[:8]),
		logger.Int("kinds_count", len(filter.Kinds)),
	)

	// 1. Query BoltDB for historical events
	events, err := h.embedded.Query(ctx, filter)
	if err != nil {
		logger.Error("query handler: embedded store query failed",
			logger.String("conn_id", connID[:8]),
			logger.String("sub_id", subID[:8]),
			logger.Err(err),
		)
		// send EOSE even on error so the client is not left hanging
		writeEOSE()
		return
	}

	logger.Debug("query handler: historical events found",
		logger.String("conn_id", connID[:8]),
		logger.String("sub_id", subID[:8]),
		logger.Int("count", len(events)),
	)

	// 2. Stream historical events back to the gateway
	for _, event := range events {
		writeEvent(*event)
	}

	// 3. Send EOSE — signals end of stored events
	writeEOSE()

	// 4. Register as channel subscriber if filter targets channels via #e
	channelIDs := extractChannelIDs(filter)
	if len(channelIDs) == 0 {
		// not a channel subscription — nothing more to do
		return
	}

	// confirm this is a kind-42 subscription
	if !filterIncludesKind(filter, 42) {
		logger.Debug("query handler: #e tag present but kind 42 not in filter, skipping channel sub",
			logger.String("conn_id", connID[:8]),
		)
		return
	}

	h.chanManager.Subscribe(connID, subID, channelIDs, writeEvent)

	logger.Info("query handler: channel subscription registered",
		logger.String("conn_id", connID[:8]),
		logger.String("sub_id", subID[:8]),
		logger.Int("channel_count", len(channelIDs)),
	)
}

// MaybeSubscribeToChannels registers a live channel subscription (kind 42 + #e tags).
// This is intended to be called from the relay's OnRequest hook (REQ handling).
func (h *QueryHandler) MaybeSubscribeToChannels(connID, subID string, filter fn.Filter, writeEvent func(fn.Event)) {
	channelIDs := extractChannelIDs(filter)
	if len(channelIDs) == 0 {
		return
	}

	if !filterIncludesKind(filter, fn.Kind(42)) {
		return
	}

	h.chanManager.Subscribe(connID, subID, channelIDs, writeEvent)
}

// HandleClose processes a ["CLOSE", subID] from a gateway.
func (h *QueryHandler) HandleClose(connID, subID string) {
	logger.Debug("handling CLOSE",
		logger.String("conn_id", connID[:8]),
		logger.String("sub_id", subID[:8]),
	)

	h.chanManager.Unsubscribe(connID, subID)
}

// extractChannelIDs pulls the #e tag values from a filter.
// These are the channel IDs the client wants to subscribe to.
func extractChannelIDs(filter fn.Filter) []string {
	eTags, ok := filter.Tags["e"]
	if !ok || len(eTags) == 0 {
		return nil
	}
	return eTags
}

// filterIncludesKind reports whether a given kind is present in the filter.
// An empty Kinds slice means all kinds are accepted.
func filterIncludesKind(filter fn.Filter, kind fn.Kind) bool {
	if len(filter.Kinds) == 0 {
		return true
	}
	for _, k := range filter.Kinds {
		if k == kind {
			return true
		}
	}
	return false
}
