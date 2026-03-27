package server

import (
	"context"
	"fmt"
	"iter"
	"net/http"

	fn "fiatjaf.com/nostr"
	"fiatjaf.com/nostr/khatru"

	"uniun-backend/channels"
	"uniun-backend/config"
	"uniun-backend/handlers"
	"uniun-backend/logger"
	"uniun-backend/router"
	"uniun-backend/store"
)

// Relay holds all top-level components of the relay server.
type Relay struct {
	khatru      *khatru.Relay
	embedded    *store.EmbeddedStore
	chanManager *channels.Manager
}

// NewRelay constructs and wires all components.
// Returns an error if any component fails to initialize.
func NewRelay() (*Relay, error) {
	// 1. embedded store
	embedded, err := store.NewEmbeddedStore()
	if err != nil {
		return nil, fmt.Errorf("relay: init embedded store: %w", err)
	}

	// 2. mysql store
	// mysql, err := store.NewMySQLStore()
	// if err != nil {
	// 	return nil, fmt.Errorf("relay: init mysql store: %w", err)
	// }

	// 3. channel manager
	chanManager := channels.NewManager()

	// 5. event router
	eventRouter := router.NewEventRouter(chanManager)

	// 6. handlers
	eventHandler := handlers.NewEventHandler(eventRouter)
	queryHandler := handlers.NewQueryHandler(embedded, chanManager)

	// 7. khatru relay
	k := khatru.NewRelay()
	k.Info.Name = config.C.RelayName
	k.Info.Description = config.C.RelayDescription

	// wire connection lifecycle hooks
	k.OnConnect = func(ctx context.Context) {
		logger.Info("gateway connected",
			logger.String("ip", khatru.GetIP(ctx)),
		)
	}
	k.OnDisconnect = func(ctx context.Context) {
		ws := khatru.GetConnection(ctx)
		if ws != nil {
			connKey := fmt.Sprintf("%p", ws)
			chanManager.UnsubscribeAll(connKey)
		}
		logger.Info("gateway disconnected",
			logger.String("ip", khatru.GetIP(ctx)),
		)
	}

	// wire event hook — khatru calls this for every valid ["EVENT", ...]
	k.OnEvent = func(ctx context.Context, event fn.Event) (bool, string) {
		logger.Info("event received",
			logger.String("event_id", fn.HexEncodeToString(event.ID[:])[:8]),
			logger.String("pubkey", fn.HexEncodeToString(event.PubKey[:])[:8]),
			logger.Int("kind", int(event.Kind)),
		)

		if err := eventHandler.HandleEvent(ctx, event); err != nil {
			return true, err.Error() // true = rejected
		}
		return false, "" // false = accepted
	}

	// wire query hook — khatru calls this for every ["REQ", ...]
	k.QueryStored = func(ctx context.Context, filter fn.Filter) iter.Seq[fn.Event] {
		return func(yield func(fn.Event) bool) {
			events, err := embedded.Query(ctx, filter)
			if err != nil {
				logger.Error("query: embedded store query failed", logger.Err(err))
				return
			}
			for _, e := range events {
				if !yield(*e) {
					return
				}
			}
		}
	}

	// wire request hook — runs for every REQ filter
	// we use this to register live channel subscriptions (kind 42 + #e tags).
	k.OnRequest = func(ctx context.Context, filter fn.Filter) (bool, string) {
		ws := khatru.GetConnection(ctx)
		if ws == nil {
			return false, ""
		}
		connKey := fmt.Sprintf("%p", ws)

		subID := khatru.GetSubscriptionID(ctx)
		writeEvent := func(event fn.Event) {
			sid := subID
			ws.WriteJSON(fn.EventEnvelope{SubscriptionID: &sid, Event: event})
		}

		queryHandler.MaybeSubscribeToChannels(connKey, subID, filter, writeEvent)
		return false, ""
	}

	// wire khatru's own eventstore for its internal use
	k.UseEventstore(embedded.Backend(), 500)

	return &Relay{
		khatru:      k,
		embedded:    embedded,
		chanManager: chanManager,
	}, nil
}

// Start begins listening for WebSocket connections.
func (relay *Relay) Start() error {
	addr := ":" + config.C.Port

	logger.Info("relay starting",
		logger.String("addr", addr),
		logger.String("name", config.C.RelayName),
	)

	mux := http.NewServeMux()
	mux.Handle("/", relay.khatru)

	return http.ListenAndServe(addr, mux)
}

// Close shuts down all stores cleanly.
func (relay *Relay) Close() {
	logger.Info("relay stopped cleanly")
}
