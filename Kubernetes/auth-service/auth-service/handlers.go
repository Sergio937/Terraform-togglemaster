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

type CreateKeyRequest struct {
	Name string `json:"name"`
}

type CreateKeyResponse struct {
	Name    string `json:"name"`
	Key     string `json:"key"`
	Message string `json:"message"`
}

// ---------- Handlers ----------

func (a *App) healthHandler(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
	})
}

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
		log.Printf("Falha validação key (hash: %s...): %v", keyHash[:6], err)
		writeError(w, http.StatusUnauthorized, "Chave inválida ou inativa")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{
		"message": "Chave válida",
	})
}

func (a *App) createKeyHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "Método não permitido")
		return
	}

	defer func() {
		if err := r.Body.Close(); err != nil {
			log.Printf("erro ao fechar request body: %v", err)
		}
	}()

	var req CreateKeyRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Corpo inválido")
		return
	}

	if strings.TrimSpace(req.Name) == "" {
		writeError(w, http.StatusBadRequest, "name é obrigatório")
		return
	}

	newKey, err := generateAPIKey()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Erro ao gerar chave")
		return
	}

	newKeyHash := hashAPIKey(newKey)

	var newID int
	err = a.DB.QueryRow(
		"INSERT INTO api_keys (name, key_hash) VALUES ($1,$2) RETURNING id",
		req.Name,
		newKeyHash,
	).Scan(&newID)

	if err != nil {
		log.Printf("erro DB: %v", err)
		writeError(w, http.StatusInternalServerError, "Erro ao salvar chave")
		return
	}

	writeJSON(w, http.StatusCreated, CreateKeyResponse{
		Name:    req.Name,
		Key:     newKey,
		Message: "Keep this key secure! You won't see it again.",
	})
}

// ---------- Middleware ----------

func (a *App) masterKeyAuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")

		if !strings.HasPrefix(authHeader, "Bearer ") {
			writeError(w, http.StatusForbidden, "Não autorizado")
			return
		}

		keyString := strings.TrimPrefix(authHeader, "Bearer ")

		if keyString != a.MasterKey {
			writeError(w, http.StatusForbidden, "Não autorizado")
			return
		}

		next.ServeHTTP(w, r)
	})
}
