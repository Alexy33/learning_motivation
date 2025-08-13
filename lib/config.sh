#!/bin/bash

# ============================================================================
# Config Module - Gestion de la configuration et des données persistantes
# ============================================================================

# Fichiers de configuration
readonly CONFIG_FILE="$CONFIG_DIR/config.json"
readonly STATS_FILE="$CONFIG_DIR/stats.json"
readonly MISSION_FILE="$CONFIG_DIR/current_mission.json"
readonly TIMER_PID_FILE="$CONFIG_DIR/timer.pid"

# Configuration par défaut
readonly DEFAULT_EASY_DURATION=7200    # 2h en secondes
readonly DEFAULT_MEDIUM_DURATION=10800 # 3h en secondes
readonly DEFAULT_HARD_DURATION=14400   # 4h en secondes

# ============================================================================
# Initialisation de la configuration
# ============================================================================

config_init() {
  mkdir -p "$CONFIG_DIR"
  config_init_main
  config_init_stats
  config_cleanup_old_mission
}

config_init_main() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    cat >"$CONFIG_FILE" <<EOF
{
    "daily_joker_used": false,
    "last_joker_date": "",
    "durations": {
        "easy": $DEFAULT_EASY_DURATION,
        "medium": $DEFAULT_MEDIUM_DURATION,
        "hard": $DEFAULT_HARD_DURATION
    },
    "punishment_settings": {
        "enabled": true,
        "min_duration": 30,
        "max_duration": 60
    },
    "notifications": {
        "enabled": true,
        "sound": true
    }
}
EOF
  fi
}

config_init_stats() {
  if [[ ! -f "$STATS_FILE" ]]; then
    cat >"$STATS_FILE" <<EOF
{
    "total_missions": 0,
    "completed": 0,
    "failed": 0,
    "current_streak": 0,
    "best_streak": 0,
    "last_mission_date": "",
    "activity_stats": {
        "Challenge TryHackMe": {"completed": 0, "failed": 0},
        "Documentation CVE": {"completed": 0, "failed": 0},
        "Analyse de malware": {"completed": 0, "failed": 0},
        "CTF Practice": {"completed": 0, "failed": 0},
        "Veille sécurité": {"completed": 0, "failed": 0}
    }
}
EOF
  fi
}

config_cleanup_old_mission() {
  # Nettoyer les anciennes missions si plus d'un jour s'est écoulé
  if [[ -f "$MISSION_FILE" ]]; then
    local mission_date
    mission_date=$(jq -r '.start_time // empty' "$MISSION_FILE" 2>/dev/null || echo "")

    if [[ -n "$mission_date" ]]; then
      local current_time=$(date +%s)
      local time_diff=$((current_time - mission_date))

      # Si plus de 24h, nettoyer
      if [[ $time_diff -gt 86400 ]]; then
        rm -f "$MISSION_FILE"
        config_stop_timer
      fi
    fi
  fi
}

# ============================================================================
# Fonctions de lecture/écriture
# ============================================================================

config_get() {
  local key=$1
  local file=${2:-"$CONFIG_FILE"}

  jq -r "$key // empty" "$file" 2>/dev/null || echo ""
}

config_set() {
  local key=$1
  local value=$2
  local file=${3:-"$CONFIG_FILE"}

  local temp_file
  temp_file=$(mktemp)

  if [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" =~ ^(true|false)$ ]]; then
    # Valeur numérique ou booléenne
    jq "$key = $value" "$file" >"$temp_file"
  else
    # Valeur string
    jq --arg val "$value" "$key = \$val" "$file" >"$temp_file"
  fi

  mv "$temp_file" "$file"
}

config_get_duration() {
  local difficulty=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  config_get ".durations.$difficulty"
}

config_set_duration() {
  local difficulty=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  local duration=$2
  config_set ".durations.$difficulty" "$duration"
}

# ============================================================================
# Gestion du joker quotidien
# ============================================================================

config_is_joker_available() {
  local today
  today=$(date +%Y-%m-%d)
  local last_joker_date
  last_joker_date=$(config_get '.last_joker_date')
  local joker_used
  joker_used=$(config_get '.daily_joker_used')

  if [[ "$last_joker_date" != "$today" ]]; then
    # Nouveau jour, reset du joker
    config_set '.daily_joker_used' false
    config_set '.last_joker_date' "$today"
    echo "true"
  elif [[ "$joker_used" == "false" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

config_use_joker() {
  local today
  today=$(date +%Y-%m-%d)
  config_set '.daily_joker_used' true
  config_set '.last_joker_date' "$today"
}

# ============================================================================
# Gestion des missions
# ============================================================================

config_save_mission() {
  local activity=$1
  local difficulty=$2
  local duration=$3
  local start_time
  start_time=$(date +%s)

  local mission_data
  mission_data=$(jq -n \
    --arg activity "$activity" \
    --arg difficulty "$difficulty" \
    --arg start_time "$start_time" \
    --arg duration "$duration" \
    '{
            activity: $activity,
            difficulty: $difficulty,
            start_time: ($start_time | tonumber),
            duration: ($duration | tonumber),
            status: "active"
        }')

  echo "$mission_data" >"$MISSION_FILE"
}

config_get_current_mission() {
  if [[ -f "$MISSION_FILE" ]]; then
    cat "$MISSION_FILE"
  else
    echo "null"
  fi
}

config_complete_mission() {
  if [[ -f "$MISSION_FILE" ]]; then
    local temp_file
    temp_file=$(mktemp)
    jq '.status = "completed"' "$MISSION_FILE" >"$temp_file"
    mv "$temp_file" "$MISSION_FILE"
  fi
}

config_fail_mission() {
  if [[ -f "$MISSION_FILE" ]]; then
    local temp_file
    temp_file=$(mktemp)
    jq '.status = "failed"' "$MISSION_FILE" >"$temp_file"
    mv "$temp_file" "$MISSION_FILE"
  fi
}

config_clear_mission() {
  rm -f "$MISSION_FILE"
  config_stop_timer
}

# ============================================================================
# Gestion du timer
# ============================================================================

config_save_timer_pid() {
  local pid=$1
  echo "$pid" >"$TIMER_PID_FILE"
}

config_get_timer_pid() {
  if [[ -f "$TIMER_PID_FILE" ]]; then
    cat "$TIMER_PID_FILE"
  else
    echo ""
  fi
}

config_stop_timer() {
  local pid
  pid=$(config_get_timer_pid)

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi

  rm -f "$TIMER_PID_FILE"
}

config_is_timer_running() {
  local pid
  pid=$(config_get_timer_pid)

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "true"
  else
    echo "false"
  fi
}

# ============================================================================
# Configuration des durées personnalisées
# ============================================================================

config_modify_durations() {
  ui_header "Configuration des durées"

  local current_easy
  local current_medium
  local current_hard

  current_easy=$(config_get_duration "easy")
  current_medium=$(config_get_duration "medium")
  current_hard=$(config_get_duration "hard")

  ui_info "Durées actuelles :"
  echo "  Easy: $(format_time "$current_easy")"
  echo "  Medium: $(format_time "$current_medium")"
  echo "  Hard: $(format_time "$current_hard")"
  echo

  local choice
  choice=$(gum choose \
    "Modifier Easy" \
    "Modifier Medium" \
    "Modifier Hard" \
    "Rétablir par défaut" \
    "Retour")

  case "$choice" in
  "Modifier Easy")
    config_modify_single_duration "easy" "$current_easy"
    ;;
  "Modifier Medium")
    config_modify_single_duration "medium" "$current_medium"
    ;;
  "Modifier Hard")
    config_modify_single_duration "hard" "$current_hard"
    ;;
  "Rétablir par défaut")
    config_set_duration "easy" "$DEFAULT_EASY_DURATION"
    config_set_duration "medium" "$DEFAULT_MEDIUM_DURATION"
    config_set_duration "hard" "$DEFAULT_HARD_DURATION"
    ui_success "Durées rétablies par défaut"
    ;;
  esac
}

config_modify_single_duration() {
  local difficulty=$1
  local current_duration=$2
  local current_formatted
  current_formatted=$(format_time "$current_duration")

  ui_info "Durée actuelle pour $difficulty: $current_formatted"

  local hours
  local minutes

  hours=$(ui_input "Heures (0-23)" "$(echo "$current_duration / 3600" | bc)")
  minutes=$(ui_input "Minutes (0-59)" "$(echo "($current_duration % 3600) / 60" | bc)")

  if [[ "$hours" =~ ^[0-9]+$ ]] && [[ "$minutes" =~ ^[0-9]+$ ]]; then
    local new_duration=$((hours * 3600 + minutes * 60))
    config_set_duration "$difficulty" "$new_duration"
    ui_success "Durée mise à jour: $(format_time "$new_duration")"
  else
    ui_error "Valeurs invalides"
  fi
}

# ============================================================================
# Utilitaires
# ============================================================================

format_time() {
  local seconds=$1
  local hours=$((seconds / 3600))
  local minutes=$(((seconds % 3600) / 60))
  printf "%dh%02dm" $hours $minutes
}
