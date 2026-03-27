package store

import (
	"context"

	fn "fiatjaf.com/nostr"
)

// EventStore is the contract every storage backend must fulfill.
type EventStore interface {
	// Save persists an event. Returns nil on success, error on failure.
	// Must be idempotent — saving the same event ID twice should not error.
	Save(ctx context.Context, event *fn.Event) error
	Query(ctx context.Context, filter fn.Filter) ([]*fn.Event, error)
	Delete(ctx context.Context, eventID string) error
	Close() error
}
