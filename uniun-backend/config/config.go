package config

import (
	"os"
	"strconv"
)

type Config struct {
	// Server
	Port    string
	DevMode bool

	// BoltDB
	BoltDBPath string

	// MySQL
	MySQLDSN string

	// Relay
	RelayName        string
	RelayDescription string
	RelayPort        string
}

var C Config

func Load() {
	C = Config{
		Port:             getEnv("PORT", "8080"),
		DevMode:          getBoolEnv("DEV_MODE", true),
		BoltDBPath:       getEnv("BOLTDB_PATH", "./data/uniun.db"),
		MySQLDSN:         getEnv("MYSQL_DSN", "user:password@tcp(127.0.0.1:3307)/uniun?parseTime=true"),
		RelayName:        getEnv("RELAY_NAME", "Uniun Relay"),
		RelayDescription: getEnv("RELAY_DESCRIPTION", "Uniun social relay"),
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

func getBoolEnv(key string, fallback bool) bool {
	val := os.Getenv(key)
	if val == "" {
		return fallback
	}
	parsed, err := strconv.ParseBool(val)
	if err != nil {
		return fallback
	}
	return parsed
}
