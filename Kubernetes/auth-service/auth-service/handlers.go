// Package main implements the authentication service.
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
)

// ---------- Helpers ----------

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("json encode error: %v", err)
	}
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{
		"error": msg,
	})
}

// ---------- DTOs ----------

// CreateKeyRequest represents the structure for the body of the key creation request.
type CreateKeyRequest struct {
	Name string `json:"name"`
}

// CreateKeyResponse represents the structure for the response of the key creation.
type CreateKeyResponse struct {
	Name    string `json:"name"`
	Key     string `json:"key"`
	Message string `json:"message"`
}

// ---------- Handlers ----------

// healthHandler is a simple health check endpoint
func (a *App) healthHandler(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
	})
}

// validateKeyHandler verifica se uma chave de API é válida
func (a *App) validateKeyHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")

	if !strings.HasPrefix(authHeader, "Bearer ") {
		writeError(w, http.StatusUnauthorized, "Authorization header inválido")
		return
	}

	keyString := strings.TrimPrefix(authHeader, "Bearer ")

	if keyString == "" {
		writeError(w, http.StatusUnauthorized, "Chave não fornecida")
		return
	}

	keyHash := hashAPIKey(keyString)

	var id int
	err := a.DB.QueryRow(
		"SELECT id FROM api_keys WHERE key_hash = $1 AND is_active = true",
		keyHash,
	).Scan(&id)

	if err != nil {
		log.Printf("Falha na validação da chave (hash: %s...): %v", keyHash[:6], err)
		writeError(w, http.StatusUnauthorized, "Chave de API inválida ou inativa")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{
		"message": "Chave válida",
	})
}

// createKeyHandler cria uma nova chave de API
func (a *App) createKeyHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "Método não permitido")
		return
	}

	defer r.Body.Close()

	var req CreateKeyRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Corpo da requisição inválido")
		return
	}

	if strings.TrimSpace(req.Name) == "" {
		writeError(w, http.StatusBadRequest, "O campo 'name' é obrigatório")
		return
	}

	newKey, err := generateAPIKey()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao gerar a chave")
		return
	}

	newKeyHash := hashAPIKey(newKey)

	var newID int
	err = a.DB.QueryRow(
		"INSERT INTO api_keys (name, key_hash) VALUES ($1, $2) RETURNING id",
		req.Name,
		newKeyHash,
	).Scan(&newID)

	if err != nil {
		log.Printf("Erro ao salvar a chave no banco: %v", err)
		writeError(w, http.StatusInternalServerError, "Erro ao salvar a chave")
		return
	}

	log.Printf("Nova chave criada (ID: %d, Name: %s)", newID, req.Name)

	writeJSON(w, http.StatusCreated, CreateKeyResponse{
		Name:    req.Name,
		Key:     newKey,
		Message: "Keep this key secure! You won't be able to see it again.",
	})
}

// ---------- Middleware ----------

// masterKeyAuthMiddleware protege endpoints com MASTER_KEY
func (a *App) masterKeyAuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")

		if !strings.HasPrefix(authHeader, "Bearer ") {
			writeError(w, http.StatusForbidden, "Acesso não autorizado")
			return
		}

		keyString := strings.TrimPrefix(authHeader, "Bearer ")

		if keyString != a.MasterKey {
			writeError(w, http.StatusForbidden, "Acesso não autorizado")
			return
		}

		next.ServeHTTP(w, r)
	})
}
