package main

import (
	"context"
	"net"
	"os"
	"os/signal"
	"path"
	"strconv"
	"syscall"
	"time"

	"github.com/fiatjaf/eventstore/badger"
	"github.com/fiatjaf/eventstore/mysql"
	"github.com/fiatjaf/khatru"
	"github.com/fiatjaf/khatru/blossom"
	"github.com/nbd-wtf/go-nostr"
)

var (
	relay           *khatru.Relay
	liveConnections int
	startTime       time.Time
)

func main() {
	LoadConfig()
	InitGlobalLogger()

	relay = khatru.NewRelay()

	relay.Info.Name = config.RelayName
	relay.Info.Description = config.RelayDescription
	relay.Info.Icon = config.RelayIcon
	relay.Info.Contact = config.RelayContact
	relay.Info.PubKey = config.RelayPublicKey
	relay.Info.URL = config.RelayURL
	relay.Info.Banner = config.RelayBanner

	relay.OnConnect = append(relay.OnConnect, func(_ context.Context) {
		liveConnections++
	})

	relay.OnDisconnect = append(relay.OnDisconnect, func(_ context.Context) {
		liveConnections--
	})

	// --- badger (primary store) ---
	badgerDB := badger.BadgerBackend{
		Path: path.Join(config.WorkingDirectory, "/db"),
	}
	if err := badgerDB.Init(); err != nil {
		Fatal("can't setup badger db", "err", err.Error())
	}

	// --- mysql (secondary mirror) ---
	var mysqlDB *mysql.MySQLBackend
	if config.MySQLDSN != "" {
		mysqlDB = &mysql.MySQLBackend{DatabaseURL: config.MySQLDSN}
		if err := mysqlDB.Init(); err != nil {
			Error("can't setup mysql db — continuing without mysql", "err", err.Error())
			mysqlDB = nil
		}
	}

	// --- wire khatru hooks ---
	relay.StoreEvent = append(relay.StoreEvent, badgerDB.SaveEvent)
	relay.QueryEvents = append(relay.QueryEvents, badgerDB.QueryEvents)
	relay.DeleteEvent = append(relay.DeleteEvent, badgerDB.DeleteEvent)
	relay.ReplaceEvent = append(relay.ReplaceEvent, badgerDB.ReplaceEvent)
	relay.CountEvents = append(relay.CountEvents, badgerDB.CountEvents)

	if mysqlDB != nil {
		relay.StoreEvent = append(relay.StoreEvent, mysqlDB.SaveEvent)
		relay.DeleteEvent = append(relay.DeleteEvent, mysqlDB.DeleteEvent)
		relay.ReplaceEvent = append(relay.ReplaceEvent, mysqlDB.ReplaceEvent)
	}

	relay.RejectEvent = append(relay.RejectEvent, RejectEvent)
	relay.RejectFilter = append(relay.RejectFilter, RejectFilter)

	// --- blossom (media storage) ---
	bl := blossom.New(relay, config.RelayURL)
	bl.Store = blossom.EventStoreBlobIndexWrapper{Store: &badgerDB, ServiceURL: bl.ServiceURL}

	if config.AzureForBlossom {
		if err := initAzureBlossom(bl); err != nil {
			Error("can't init azure blossom — media uploads will fail", "err", err.Error())
		}
	}

	startTime = time.Now()

	Info("Serving", "address", net.JoinHostPort(config.RelayBind, strconv.Itoa(config.RelayPort)))
	if err := relay.Start(config.RelayBind, config.RelayPort); err != nil {
		Fatal("can't start the server", "err", err)
	}

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM, os.Interrupt)

	sig := <-sigChan

	Info("Received signal: Initiating graceful shutdown", "signal", sig.String())
	badgerDB.Close()
	if mysqlDB != nil {
		mysqlDB.Close()
	}
	relay.Shutdown(context.Background())
}

// RejectEvent — placeholder for application-level event rejection rules.
func RejectEvent(_ context.Context, event *nostr.Event) (reject bool, msg string) {
	_ = event
	return false, ""
}

// RejectFilter — placeholder for application-level filter rejection rules.
func RejectFilter(_ context.Context, filter nostr.Filter) (reject bool, msg string) {
	_ = filter
	return false, ""
}
