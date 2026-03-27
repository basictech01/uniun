package handlers

import (
	"context"
	"fmt"

	fn "fiatjaf.com/nostr"

	"uniun-backend/logger"
	"uniun-backend/router"
)

// EventHandler handles incoming EVENT messages from gateways.
type EventHandler struct {
	eventRouter *router.EventRouter
}

// NewEventHandler constructs an EventHandler with all dependencies wired.
func NewEventHandler(
	eventRouter *router.EventRouter,
) *EventHandler {
	return &EventHandler{
		eventRouter: eventRouter,
	}
}

// HandleEvent processes a single incoming event from a gateway.
// Called by Khatru for every ["EVENT", event] message received.
//
// Returns an error if the event should be rejected — Khatru sends
// ["OK", id, false, err.Error()] back to the gateway.
// Returns nil on success — Khatru sends ["OK", id, true, ""].
func (h *EventHandler) HandleEvent(ctx context.Context, event fn.Event) error {
	// route the event through store + channel logic
	result := h.eventRouter.Route(ctx, event)
	if !result.OK {
		logger.Warn("event rejected",
			logger.String("event_id", fn.HexEncodeToString(event.ID[:])[:8]),
			logger.String("reason", result.Reason),
		)
		return fmt.Errorf("%s", result.Reason)
	}

	return nil
}
