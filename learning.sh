#!/bin/bash

# ============================================================================
# Cyber Challenge Manager
# A gamified task management system for cybersecurity training
# ============================================================================

set -euo pipefail

# Configuration globale
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$HOME/.cyber_challenge"
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly BIN_DIR="$SCRIPT_DIR/bin"

# Import des modules
source "$LIB_DIR/config.sh"
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/mission.sh"
source "$LIB_DIR/stats.sh"
source "$LIB_DIR/timer.sh"

# ============================================================================
# Fonctions principales
# ============================================================================

check_dependencies() {
  local missing_deps=()

  for dep in gum jq bc; do
    if ! command -v "$dep" &>/dev/null; then
      missing_deps+=("$dep")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    ui_error "Dépendances manquantes: ${missing_deps[*]}"
    ui_info "Installation: sudo pacman -S ${missing_deps[*]}"
    exit 1
  fi
}

show_main_menu() {
  ui_info "Sélectionnez votre activité :"

  local choice
  choice=$(gum choose \
    --cursor="➤ " \
    --selected.foreground="#00ff00" \
    --cursor.foreground="#0099ff" \
    "🔥 Challenge TryHackMe" \
    "📚 Documentation CVE" \
    "🦠 Analyse de malware" \
    "🏴‍☠️ CTF Practice" \
    "🔍 Veille sécurité" \
    "📊 Statistiques" \
    "⚙️  Configuration" \
    "🚪 Quitter")

  echo "$choice"
}

handle_menu_choice() {
  local choice=$1

  case "$choice" in
  "🔥 Challenge TryHackMe")
    mission_create "Challenge TryHackMe"
    ;;
  "📚 Documentation CVE")
    mission_create "Documentation CVE"
    ;;
  "🦠 Analyse de malware")
    mission_create "Analyse de malware"
    ;;
  "🏴‍☠️ CTF Practice")
    mission_create "CTF Practice"
    ;;
  "🔍 Veille sécurité")
    mission_create "Veille sécurité"
    ;;
  "📊 Statistiques")
    stats_display
    ;;
  "⚙️  Configuration")
    show_config_menu
    ;;
  "🚪 Quitter")
    ui_success "Session terminée"
    exit 0
    ;;
  esac
}

show_config_menu() {
  ui_header "Configuration"

  local config_choice
  config_choice=$(gum choose \
    "🎯 Modifier les durées par difficulté" \
    "🔄 Réinitialiser les statistiques" \
    "🗂️  Voir les fichiers de configuration" \
    "↩️  Retour au menu principal")

  case "$config_choice" in
  "🎯 Modifier les durées par difficulté")
    config_modify_durations
    ;;
  "🔄 Réinitialiser les statistiques")
    if gum confirm "Êtes-vous sûr de vouloir réinitialiser toutes les statistiques ?"; then
      stats_reset
      ui_success "Statistiques réinitialisées"
    fi
    ;;
  "🗂️  Voir les fichiers de configuration")
    ui_info "Dossier de configuration : $CONFIG_DIR"
    gum input --placeholder "Appuyez sur Entrée pour continuer..."
    ;;
  esac
}

main_loop() {
  while true; do
    ui_header "Cyber Challenge Manager"

    # Afficher la mission en cours si elle existe
    mission_display_current

    local choice
    choice=$(show_main_menu)
    handle_menu_choice "$choice"

    echo
    sleep 0.5
  done
}

# ============================================================================
# Point d'entrée principal
# ============================================================================

main() {
  # Vérifications préliminaires
  check_dependencies
  config_init

  # Créer les dossiers nécessaires
  mkdir -p "$CONFIG_DIR" "$BIN_DIR"

  # Démarrer la boucle principale
  main_loop
}

# Gestion des signaux
trap 'ui_warning "Interruption détectée. Session fermée."; exit 130' INT TERM

# Lancer le programme
main "$@"
