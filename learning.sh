#!/bin/bash

# ============================================================================
# Learning Challenge Manager
# A gamified task management system for cybersecurity training
# ============================================================================

set -euo pipefail

# Configuration globale
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$HOME/.learning_challenge"
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly BIN_DIR="$SCRIPT_DIR/bin"

# Import des modules
source "$LIB_DIR/config.sh"
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/mission.sh"
source "$LIB_DIR/stats.sh"
source "$LIB_DIR/timer.sh"
source "$LIB_DIR/punishment.sh"

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
  echo
  echo -e "${CYAN}Sélectionnez votre activité :${NC}"
  echo

  gum choose \
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
    "🚪 Quitter"
}

handle_menu_choice() {
  local choice="$1"

  # Version plus tolérante - utilise des patterns
  case "$choice" in
  *"Challenge TryHackMe"*)
    echo "TryHackMe sélectionné !"
    mission_create "Challenge TryHackMe"
    ;;
  *"Documentation CVE"*)
    echo "CVE sélectionné !"
    mission_create "Documentation CVE"
    ;;
  *"Analyse de malware"*)
    echo "Malware sélectionné !"
    mission_create "Analyse de malware"
    ;;
  *"CTF Practice"*)
    echo "CTF sélectionné !"
    mission_create "CTF Practice"
    ;;
  *"Veille sécurité"*)
    echo "Veille sélectionnée !"
    mission_create "Veille sécurité"
    ;;
  *"Statistiques"*)
    stats_display
    ;;
  *"Configuration"*)
    show_config_menu
    ;;
  *"Quitter"*)
    ui_success "Session terminée"
    exit 0
    ;;
  *)
    echo "DEBUG: Choix non reconnu: '$choice'"
    echo "DEBUG: Longueur: ${#choice} caractères"
    printf "DEBUG: Hex dump: "
    printf '%s' "$choice" | xxd -p
    echo
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
    gum input --placeholder "Appuyez sur Entrée pour continuer..." >/dev/null
    ;;
  esac
}

main_loop() {
  while true; do
    ui_header "Learning Challenge Manager"

    # Afficher la mission en cours si elle existe
    mission_display_current

    # Obtenir le choix de l'utilisateur
    local choice
    if ! choice=$(show_main_menu); then
      ui_warning "Sélection annulée"
      continue
    fi

    # Traiter le choix
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

  # Message de bienvenue
  echo
  ui_success "Learning Challenge Manager initialisé"
  echo

  # Démarrer la boucle principale
  main_loop
}

# Gestion des signaux
trap 'echo; ui_warning "Interruption détectée. Session fermée."; exit 130' INT TERM

# Lancer le programme
main "$@"
