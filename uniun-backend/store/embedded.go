package store

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	fn "fiatjaf.com/nostr"
	"fiatjaf.com/nostr/eventstore/boltdb"

	"uniun-backend/config"
	"uniun-backend/logger"
)

// EmbeddedStore wraps BoltDB.
// Khatru owns all writes — this struct only handles init and reads.
type EmbeddedStore struct {
	backend *boltdb.BoltBackend
}

// NewEmbeddedStore initializes the BoltDB backend.
// Creates the data directory if it does not exist.
func NewEmbeddedStore() (*EmbeddedStore, error) {
	path := config.C.BoltDBPath

	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("embedded store: create data dir: %w", err)
	}

	backend := &boltdb.BoltBackend{Path: path}
	if err := backend.Init(); err != nil {
		return nil, fmt.Errorf("embedded store: init boltdb: %w", err)
	}

	logger.Info("embedded store: boltdb initialized",
		logger.String("path", path),
	)

	return &EmbeddedStore{backend: backend}, nil
}

// Backend exposes the underlying BoltBackend so server/relay.go
// can call relay.UseEventstore(store.Backend(), 500).
func (s *EmbeddedStore) Backend() *boltdb.BoltBackend {
	return s.backend
}

// Khatru owns all writes — this struct only handles init and reads.
func (s *EmbeddedStore) Save(_ context.Context, _ *fn.Event) error { return nil }

func (s *EmbeddedStore) Delete(_ context.Context, _ string) error { return nil }

func (s *EmbeddedStore) Close() error { return nil }

// Query returns events matching the given filter from BoltDB.
// Used by QueryHandler for historical event lookup on REQ.
func (s *EmbeddedStore) Query(_ context.Context, filter fn.Filter) ([]*fn.Event, error) {
	maxLimit := 500 // or filter.Limit if set; just pick a sane ceiling
	seq := s.backend.QueryEvents(filter, maxLimit)

	results := make([]*fn.Event, 0)
	for evt := range seq { // NOTE: one variable only
		e := evt // make a copy
		results = append(results, &e)
	}
	return results, nil
}
