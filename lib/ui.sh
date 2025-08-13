#!/bin/bash

# ============================================================================
# UI Module - Interface utilisateur et affichage
# ============================================================================

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# ============================================================================
# Fonctions d'affichage
# ============================================================================

ui_clear() {
  clear
}

ui_header() {
  local title=${1:-"Learning Challenge Manager"}
  ui_clear
  echo -e "${PURPLE}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  printf "║%*s║\n" 62 "$(printf "%*s" $(((62 + ${#title}) / 2)) "$title")"
  echo "║                    Professional Training System              ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

ui_success() {
  local message=$1
  echo -e "${GREEN}✅ $message${NC}"
}

ui_error() {
  local message=$1
  echo -e "${RED}❌ $message${NC}" >&2
}

ui_warning() {
  local message=$1
  echo -e "${YELLOW}⚠️  $message${NC}"
}

ui_info() {
  local message=$1
  echo -e "${CYAN}ℹ️  $message${NC}"
}

ui_divider() {
  echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
}

# Affichage stylé avec gum
ui_box() {
  local title=$1
  local content=$2
  local border_color=${3:-"#4A90E2"}

  # Séparer le contenu par les \n
  local lines
  IFS=$'\n' read -ra lines <<<"$(echo -e "$content")"

  gum style \
    --border double \
    --margin "1 2" \
    --padding "1 2" \
    --border-foreground "$border_color" \
    "$title" \
    "" \
    "${lines[@]}"
}

ui_mission_box() {
  local activity=$1
  local difficulty=$2
  local time=$3
  local border_color="#FF6B6B"

  gum style \
    --border double \
    --margin "1 2" \
    --padding "1 2" \
    --border-foreground "$border_color" \
    "🎯 MISSION GÉNÉRÉE" \
    "" \
    "📋 Activité: $activity" \
    "⚡ Difficulté: $difficulty" \
    "⏰ Temps imparti: $time" \
    "" \
    "💀 Échec = Pénalité appliquée"
}

ui_current_mission() {
  local activity=$1
  local difficulty=$2
  local time_remaining=$3
  local border_color="#FFA500"

  gum style \
    --border normal \
    --margin "1 0" \
    --padding "1 1" \
    --border-foreground "$border_color" \
    "⚠️  MISSION ACTIVE" \
    "📋 $activity ($difficulty)" \
    "⏰ Temps restant: $time_remaining"
  echo
}

ui_stats_box() {
  local total=$1
  local completed=$2
  local failed=$3
  local success_rate=$4
  local streak=$5
  local best_streak=$6

  gum style \
    --border double \
    --margin "1 2" \
    --padding "1 2" \
    --border-foreground "#4A90E2" \
    "📊 STATISTIQUES DE PERFORMANCE" \
    "" \
    "🎯 Missions totales: $total" \
    "✅ Complétées: $completed" \
    "❌ Échouées: $failed" \
    "📈 Taux de réussite: ${success_rate}%" \
    "🔥 Série actuelle: $streak" \
    "🏆 Meilleure série: $best_streak"
}

ui_punishment_warning() {
  local punishment_type=$1
  local duration=$2

  gum style \
    --border thick \
    --margin "1 2" \
    --padding "1 2" \
    --border-foreground "#FF0000" \
    "💀 ÉCHEC DE MISSION DÉTECTÉ" \
    "" \
    "🚨 Pénalité: $punishment_type" \
    "⏱️  Durée: $duration minutes" \
    "" \
    "⚡ Application dans 5 secondes..."
}

ui_joker_available() {
  gum style \
    --border normal \
    --margin "1 0" \
    --padding "1 1" \
    --border-foreground "#FFA500" \
    "🃏 JOKER QUOTIDIEN DISPONIBLE" \
    "Changement de mission possible (1/jour)"
}

ui_countdown() {
  local seconds=$1
  local message=${2:-"Application de la pénalité dans"}

  for ((i = seconds; i >= 1; i--)); do
    echo -ne "\r${RED}$message $i secondes...${NC}"
    sleep 1
  done
  echo -e "\r${RED}$message maintenant!${NC}        "
}

ui_progress_bar() {
  local current=$1
  local total=$2
  local message=${3:-"Progression"}

  local percentage=$((current * 100 / total))
  local bar_length=40
  local filled_length=$((percentage * bar_length / 100))

  local bar=""
  for ((i = 0; i < filled_length; i++)); do
    bar+="█"
  done
  for ((i = filled_length; i < bar_length; i++)); do
    bar+="░"
  done

  echo -e "${CYAN}$message: [${bar}] ${percentage}%${NC}"
}

ui_confirm() {
  local message=$1
  local default=${2:-false}

  gum confirm --default="$default" "$message"
}

ui_input() {
  local placeholder=${1:-"Entrez votre réponse"}
  local value=${2:-""}

  if [[ -n "$value" ]]; then
    gum input --placeholder "$placeholder" --value "$value"
  else
    gum input --placeholder "$placeholder"
  fi
}

ui_wait() {
  local message=${1:-"Appuyez sur Entrée pour continuer"}
  gum input --placeholder "$message" >/dev/null
}
