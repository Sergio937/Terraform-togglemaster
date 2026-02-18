package main

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

const apiKeyPrefix = "tm_key_"
const apiKeyBytes = 32 // 256 bits de entropia

// generateAPIKey cria uma string aleatória segura
func generateAPIKey() (string, error) {
	b := make([]byte, apiKeyBytes)

	n, err := rand.Read(b)
	if err != nil {
		return "", fmt.Errorf("failed to generate random bytes: %w", err)
	}

	if n != apiKeyBytes {
		return "", fmt.Errorf("insufficient random bytes read")
	}

	return apiKeyPrefix + hex.EncodeToString(b), nil
}

// hashAPIKey calcula o hash SHA-256 de uma chave
func hashAPIKey(key string) string {
	sum := sha256.Sum256([]byte(key))
	return hex.EncodeToString(sum[:])
}
