// Package main implements the feature flag evaluation service.
package main

import "fmt"

// --- Estruturas de Dados ---

// Flag espelha a resposta do flag-service
type Flag struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	IsEnabled   bool   `json:"is_enabled"`
}

// TargetingRule espelha a resposta do targeting-service
type TargetingRule struct {
	Rules     Rule   `json:"rules"` // O objeto JSONB
	FlagName  string `json:"flag_name"`
	ID        int    `json:"id"`
	IsEnabled bool   `json:"is_enabled"`
}

// Rule é o objeto JSONB aninhado
type Rule struct {
	Value interface{} `json:"value"` // ex: 50
	Type  string      `json:"type"`  // ex: "PERCENTAGE"
}

// CombinedFlagInfo é a estrutura que salvamos no cache
type CombinedFlagInfo struct {
	Flag *Flag
	Rule *TargetingRule
}

// NotFoundError é um erro customizado
type NotFoundError struct {
	FlagName string
}
func (e *NotFoundError) Error() string {
	return fmt.Sprintf("flag ou regra '%s' não encontrada", e.FlagName)
}