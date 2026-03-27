package main

import (
	"os"
	"os/signal"
	"syscall"

	"uniun-backend/config"
	"uniun-backend/logger"
	"uniun-backend/server"
)

func main() {
	// 1. load config first — everything else depends on it
	config.Load()

	// 2. initialize logger — must be before any component that logs
	logger.Init(config.C.DevMode)
	defer logger.Sync()

	logger.Info("starting uniun relay",
		logger.String("name", config.C.RelayName),
		logger.String("port", config.C.Port),
	)

	// 3. construct relay — wires all components
	relay, err := server.NewRelay()
	if err != nil {
		logger.Fatal("failed to initialize relay",
			logger.Err(err),
		)
	}

	// 4. listen for OS shutdown signals
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	// 5. start relay in a goroutine so we can listen for shutdown
	serverErr := make(chan error, 1)
	go func() {
		if err := relay.Start(); err != nil {
			serverErr <- err
		}
	}()

	// 6. block until shutdown signal or server error
	select {
	case sig := <-quit:
		logger.Info("shutdown signal received",
			logger.String("signal", sig.String()),
		)
	case err := <-serverErr:
		logger.Fatal("relay server error",
			logger.Err(err),
		)
	}

	// 7. clean shutdown
	relay.Close()
}
