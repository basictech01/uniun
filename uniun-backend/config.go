package main

import (
	"os"
	"strconv"
)

type Config struct {
	// Server
	RelayBind string
	RelayPort int
	RelayURL  string

	// Relay metadata (NIP-11)
	RelayName        string
	RelayDescription string
	RelayIcon        string
	RelayContact     string
	RelayPublicKey   string
	RelayBanner      string

	// Storage
	WorkingDirectory string
	MySQLDSN         string

	// Azure Blossom
	AzureForBlossom      bool
	AzStorageAccountName string
	AzStorageAccountKey  string
	AzBlossomContainer   string

	// Logging
	LogLevel string
}

var config Config

func LoadConfig() {
	config = Config{
		RelayBind:        getEnv("RELAY_BIND", "0.0.0.0"),
		RelayPort:        getIntEnv("RELAY_PORT", 8080),
		RelayURL:         getEnv("RELAY_URL", "ws://localhost:8080"),
		WorkingDirectory: getEnv("WORKING_DIR", "."),
		MySQLDSN:         getEnv("MYSQL_DSN", ""),

		RelayName:        getEnv("RELAY_NAME", "Uniun Relay"),
		RelayDescription: getEnv("RELAY_DESCRIPTION", "Uniun social relay"),
		RelayIcon:        getEnv("RELAY_ICON", ""),
		RelayContact:     getEnv("RELAY_CONTACT", ""),
		RelayPublicKey:   getEnv("RELAY_PUBKEY", ""),
		RelayBanner:      getEnv("RELAY_BANNER", ""),

		AzureForBlossom:      getBoolEnv("AZURE_FOR_BLOSSOM", false),
		AzStorageAccountName: getEnv("AZURE_STORAGE_ACCOUNT_NAME", ""),
		AzStorageAccountKey:  getEnv("AZURE_STORAGE_ACCOUNT_KEY", ""),
		AzBlossomContainer:   getEnv("AZURE_BLOSSOM_CONTAINER", "blossom"),

		LogLevel: getEnv("LOG_LEVEL", "info"),
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

func getIntEnv(key string, fallback int) int {
	val := os.Getenv(key)
	if val == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(val)
	if err != nil {
		return fallback
	}
	return parsed
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
