package router

import (
	"context"
	"fmt"

	fn "fiatjaf.com/nostr"

	"uniun-backend/channels"
	"uniun-backend/logger"
)

// Result carries the outcome of routing an event.
type Result struct {
	OK     bool
	Reason string
}

func accept() Result {
	return Result{OK: true}
}

func reject(reason string) Result {
	return Result{OK: false, Reason: reason}
}

// EventRouter routes incoming events to the correct components.
type EventRouter struct {
	channels *channels.Manager
}

// NewEventRouter constructs an EventRouter with all dependencies wired.
func NewEventRouter(
	channels *channels.Manager,
) *EventRouter {
	return &EventRouter{
		channels: channels,
	}
}

// Route processes a single incoming event:
//  1. Kind-specific routing
//
// Persistence is handled by Khatru's eventstore via `relay.UseEventstore(...)`.
func (r *EventRouter) Route(ctx context.Context, event fn.Event) Result {
	logger.Debug("routing event",
		logger.String("event_id", fn.HexEncodeToString(event.ID[:])[:8]),
		logger.String("pubkey", fn.HexEncodeToString(event.PubKey[:])[:8]),
		logger.Int("kind", int(event.Kind)),
	)

	// Kind-specific routing
	switch event.Kind {
	case 40:
		r.channels.RegisterChannel(event)

	case 41:
		if err := r.channels.UpdateChannelMeta(event); err != nil {
			logger.Warn("router: channel meta update rejected",
				logger.String("event_id", fn.HexEncodeToString(event.ID[:])[:8]),
				logger.Err(err),
			)
			return reject(fmt.Sprintf("restricted: %s", err.Error()))
		}

	case 42:
		r.channels.BroadcastToChannel(event)

	case 1, 1063:
		// image yet to be implemented
	}

	logger.Debug("router: event accepted",
		logger.String("event_id", fn.HexEncodeToString(event.ID[:])[:8]),
		logger.Int("kind", int(event.Kind)),
	)

	return accept()
}
