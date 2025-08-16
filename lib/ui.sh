#!/bin/bash

# ============================================================================
# UI Module - Interface utilisateur et affichage
# ============================================================================

# Couleurs essentielles (suppression des couleurs inutilisées)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ============================================================================
# Fonctions d'affichage de base
# ============================================================================

ui_clear() {
  clear
}

ui_header() {
  local title=${1:-"Learning Challenge Manager"}
  ui_clear
  echo -e "${CYAN}"
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

# ============================================================================
# Fonction ui_box optimisée
# ============================================================================

ui_box() {
  local title=$1
  local content=$2
  local border_color=${3:-"#4A90E2"}

  # Remplacer les | par des lignes séparées
  local formatted_content
  formatted_content=$(echo "$content" | sed 's/|/\n/g')

  # Passer chaque ligne comme argument séparé
  local lines=()
  while IFS= read -r line; do
    lines+=("$line")
  done <<<"$formatted_content"

  gum style \
    --border double \
    --margin "1 2" \
    --padding "1 2" \
    --border-foreground "$border_color" \
    "$title" \
    "" \
    "${lines[@]}"
}

# ============================================================================
# Boîtes spécialisées pour missions
# ============================================================================

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

ui_themed_mission_box() {
  local activity=$1
  local difficulty=$2
  local time=$3
  local theme=$4
  local border_color="#FF6B6B"

  gum style \
    --border double \
    --margin "1 2" \
    --padding "1 2" \
    --border-foreground "$border_color" \
    "🎯 MISSION THÉMATIQUE GÉNÉRÉE" \
    "" \
    "📋 Activité: $activity" \
    "⚡ Difficulté: $difficulty" \
    "⏰ Temps imparti: $time" \
    "🎨 Thème: $theme" \
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

ui_current_mission_with_theme() {
  local activity=$1
  local difficulty=$2
  local time_remaining=$3
  local theme=$4
  local border_color="#FFA500"

  gum style \
    --border normal \
    --margin "1 0" \
    --padding "1 1" \
    --border-foreground "$border_color" \
    "⚠️  MISSION THÉMATIQUE ACTIVE" \
    "📋 $activity ($difficulty)" \
    "🎨 Thème: $theme" \
    "⏰ Temps restant: $time_remaining"
  echo
}

# ============================================================================
# Boîtes spécialisées pour statistiques et pénalités
# ============================================================================

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

  # Descriptions des pénalités améliorées
  local punishment_description=""
  case "$punishment_type" in
    "network_restriction")
      punishment_description="🌐 Restriction réseau complète"
      ;;
    "website_block")
      punishment_description="🚫 Blocage sites distractifs"
      ;;
    "notification_spam")
      punishment_description="📢 Notifications de rappel fréquentes"
      ;;
    "mouse_sensitivity")
      punishment_description="🖱️ Sensibilité souris réduite"
      ;;
    "annoying_sound")
      punishment_description="🔊 Son strident avec volume progressif"
      ;;
    "command_swap")
      punishment_description="🔄 Commandes terminal inversées"
      ;;
    "screen_distortion")
      punishment_description="📺 Distorsion/rotation d'écran"
      ;;
    "keyboard_delay")
      punishment_description="⌨️ Délai de répétition clavier"
      ;;
    "fake_errors")
      punishment_description="💥 Injection de fausses erreurs"
      ;;
    *)
      punishment_description="💀 Pénalité système"
      ;;
  esac

  gum style \
    --border thick \
    --margin "1 2" \
    --padding "1 2" \
    --border-foreground "#FF0000" \
    "💀 ÉCHEC DE MISSION DÉTECTÉ" \
    "" \
    "🚨 Pénalité: $punishment_description" \
    "⏱️  Durée: $duration minutes" \
    "" \
    "⚡ Application dans 5 secondes..." \
    "" \
    "🃏 Prochain joker rechargé demain"
}

# ============================================================================
# Nouvelle fonction pour afficher les pénalités disponibles
# ============================================================================

show_punishment_info() {
  ui_header "💀 Informations sur les Pénalités"

  local min_duration max_duration
  min_duration=$(config_get '.punishment_settings.min_duration')
  max_duration=$(config_get '.punishment_settings.max_duration')

  ui_box "⚠️ PÉNALITÉS EN CAS D'ÉCHEC" \
    "En cas d'échec de mission, une pénalité aléatoire sera appliquée.|Durée: entre $min_duration et $max_duration minutes||Types de pénalités possibles:|🌐 Restriction du réseau complet|🚫 Blocage de sites distractifs|🖱️ Réduction sensibilité souris|🔊 Son strident avec volume progressif|🔄 Commandes terminal inversées (ls/sl, etc.)|📺 Distorsion/rotation d'écran|⌨️ Délai de répétition clavier|💥 Injection de fausses erreurs système|📢 Notifications de rappel fréquentes||Ces pénalités sont motivationnelles et temporaires.|Utilisez vos jokers pour les éviter !" \
    "#FF6B6B"

  echo
  ui_info "🎯 Pénalités actuellement actives :"
  punishment_list_active

  echo
  ui_wait
}

# ============================================================================
# Fonctions d'interaction utilisateur
# ============================================================================

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