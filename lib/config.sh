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
readonly JOKERS_PER_DAY=3              # Constante simplifié

# ============================================================================
# Initialisation de la configuration
# ============================================================================

config_init() {
  mkdir -p "$CONFIG_DIR"
  config_init_main
  config_init_stats
  config_migrate_stats
  config_cleanup_old_mission
}

config_init_main() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    cat >"$CONFIG_FILE" <<EOF
{
    "jokers_used_today": 0,
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
        "Développement Tools": {"completed": 0, "failed": 0},
        "Reverse Engineering": {"completed": 0, "failed": 0},
        "Investigation Digitale": {"completed": 0, "failed": 0}
    },
    "difficulty_stats": {
        "Easy": {"completed": 0, "failed": 0},
        "Medium": {"completed": 0, "failed": 0},
        "Hard": {"completed": 0, "failed": 0}
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
# Fonctions de lecture/écriture simplifiées
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
    jq "$key = $value" "$file" >"$temp_file"
  else
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
# Gestion du système de jokers simplifié
# ============================================================================

config_get_jokers_used() {
  local today
  today=$(date +%Y-%m-%d)
  local last_joker_date
  last_joker_date=$(config_get '.last_joker_date')

  if [[ "$last_joker_date" != "$today" ]]; then
    # Nouveau jour, reset des jokers
    config_set '.jokers_used_today' 0
    config_set '.last_joker_date' "$today"
    echo "0"
  else
    local jokers_used
    jokers_used=$(config_get '.jokers_used_today')
    echo "${jokers_used:-0}"
  fi
}

config_get_jokers_available() {
  local used
  used=$(config_get_jokers_used)
  echo $((JOKERS_PER_DAY - used))
}

config_is_joker_available() {
  local available
  available=$(config_get_jokers_available)
  [[ $available -gt 0 ]]
}

config_use_joker() {
  local today used
  today=$(date +%Y-%m-%d)
  used=$(config_get_jokers_used)

  config_set '.jokers_used_today' $((used + 1))
  config_set '.last_joker_date' "$today"
}

# ============================================================================
# Gestion des missions
# ============================================================================

config_save_mission() {
  local activity=$1
  local difficulty=$2
  local duration=$3
  local theme=${4:-""}
  local start_time
  start_time=$(date +%s)

  local mission_data
  if [[ -n "$theme" ]]; then
    mission_data=$(jq -n \
      --arg activity "$activity" \
      --arg difficulty "$difficulty" \
      --arg start_time "$start_time" \
      --arg duration "$duration" \
      --arg theme "$theme" \
      '{
        activity: $activity,
        difficulty: $difficulty,
        start_time: ($start_time | tonumber),
        duration: ($duration | tonumber),
        theme: $theme,
        status: "active"
      }')
  else
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
  fi

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
# Configuration des durées simplifiée
# ============================================================================

config_modify_durations() {
  ui_header "Configuration des durées"

  local current_easy current_medium current_hard
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
    config_modify_duration "easy" "$current_easy"
    ;;
  "Modifier Medium")
    config_modify_duration "medium" "$current_medium"
    ;;
  "Modifier Hard")
    config_modify_duration "hard" "$current_hard"
    ;;
  "Rétablir par défaut")
    config_set_duration "easy" "$DEFAULT_EASY_DURATION"
    config_set_duration "medium" "$DEFAULT_MEDIUM_DURATION"
    config_set_duration "hard" "$DEFAULT_HARD_DURATION"
    ui_success "Durées rétablies par défaut"
    ;;
  esac
}

config_modify_duration() {
  local difficulty=$1
  local current_duration=$2
  local current_formatted
  current_formatted=$(format_time "$current_duration")

  ui_info "Durée actuelle pour $difficulty: $current_formatted"

  local hours minutes
  hours=$(ui_input "Heures (0-23)" "$(echo "$current_duration / 3600" | bc)")
  minutes=$(ui_input "Minutes (0-59)" "$(echo "($current_duration % 3600) / 60" | bc)")

  if [[ "$hours" =~ ^[0-9]+$ ]] && [[ "$minutes" =~ ^[0-9]+$ ]] && [[ $hours -le 23 ]] && [[ $minutes -le 59 ]]; then
    local new_duration=$((hours * 3600 + minutes * 60))
    if [[ $new_duration -gt 0 ]]; then
      config_set_duration "$difficulty" "$new_duration"
      ui_success "Durée mise à jour: $(format_time "$new_duration")"
    else
      ui_error "La durée doit être supérieure à 0"
    fi
  else
    ui_error "Valeurs invalides (heures: 0-23, minutes: 0-59)"
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

config_migrate_stats() {
  if [[ ! -f "$STATS_FILE" ]]; then
    return 0 # Pas de fichier à migrer
  fi

  # Vérifier si migration nécessaire (présence anciennes activités)
  local needs_migration=false
  
  if jq -e '.activity_stats["Analyse de malware"]' "$STATS_FILE" >/dev/null 2>&1; then
    needs_migration=true
  fi
  
  if jq -e '.activity_stats["CTF Practice"]' "$STATS_FILE" >/dev/null 2>&1; then
    needs_migration=true
  fi
  
  if jq -e '.activity_stats["Veille sécurité"]' "$STATS_FILE" >/dev/null 2>&1; then
    needs_migration=true
  fi

  if [[ "$needs_migration" == "true" ]]; then
    ui_info "🔄 Migration des statistiques vers le nouveau système..."
    
    # Sauvegarder l'ancien fichier
    cp "$STATS_FILE" "$STATS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Récupérer les stats globales
    local total completed failed current_streak best_streak last_date
    total=$(jq -r '.total_missions // 0' "$STATS_FILE")
    completed=$(jq -r '.completed // 0' "$STATS_FILE")
    failed=$(jq -r '.failed // 0' "$STATS_FILE")
    current_streak=$(jq -r '.current_streak // 0' "$STATS_FILE")
    best_streak=$(jq -r '.best_streak // 0' "$STATS_FILE")
    last_date=$(jq -r '.last_mission_date // ""' "$STATS_FILE")
    
    # Récupérer les stats par difficulté (à préserver)
    local easy_completed easy_failed medium_completed medium_failed hard_completed hard_failed
    easy_completed=$(jq -r '.difficulty_stats.Easy.completed // 0' "$STATS_FILE")
    easy_failed=$(jq -r '.difficulty_stats.Easy.failed // 0' "$STATS_FILE")
    medium_completed=$(jq -r '.difficulty_stats.Medium.completed // 0' "$STATS_FILE")
    medium_failed=$(jq -r '.difficulty_stats.Medium.failed // 0' "$STATS_FILE")
    hard_completed=$(jq -r '.difficulty_stats.Hard.completed // 0' "$STATS_FILE")
    hard_failed=$(jq -r '.difficulty_stats.Hard.failed // 0' "$STATS_FILE")
    
    # Récupérer les stats des activités conservées
    local tryhackme_completed tryhackme_failed cve_completed cve_failed
    tryhackme_completed=$(jq -r '.activity_stats["Challenge TryHackMe"].completed // 0' "$STATS_FILE")
    tryhackme_failed=$(jq -r '.activity_stats["Challenge TryHackMe"].failed // 0' "$STATS_FILE")
    cve_completed=$(jq -r '.activity_stats["Documentation CVE"].completed // 0' "$STATS_FILE")
    cve_failed=$(jq -r '.activity_stats["Documentation CVE"].failed // 0' "$STATS_FILE")
    
    # Migrer les anciennes activités vers les nouvelles
    local malware_completed malware_failed ctf_completed ctf_failed veille_completed veille_failed
    malware_completed=$(jq -r '.activity_stats["Analyse de malware"].completed // 0' "$STATS_FILE")
    malware_failed=$(jq -r '.activity_stats["Analyse de malware"].failed // 0' "$STATS_FILE")
    ctf_completed=$(jq -r '.activity_stats["CTF Practice"].completed // 0' "$STATS_FILE")
    ctf_failed=$(jq -r '.activity_stats["CTF Practice"].failed // 0' "$STATS_FILE")
    veille_completed=$(jq -r '.activity_stats["Veille sécurité"].completed // 0' "$STATS_FILE")
    veille_failed=$(jq -r '.activity_stats["Veille sécurité"].failed // 0' "$STATS_FILE")
    
    # Créer le nouveau fichier stats avec migration intelligente
    local temp_file
    temp_file=$(mktemp)
    
    cat >"$temp_file" <<EOF
{
    "total_missions": $total,
    "completed": $completed,
    "failed": $failed,
    "current_streak": $current_streak,
    "best_streak": $best_streak,
    "last_mission_date": "$last_date",
    "activity_stats": {
        "Challenge TryHackMe": {
            "completed": $((tryhackme_completed + ctf_completed)),
            "failed": $((tryhackme_failed + ctf_failed))
        },
        "Documentation CVE": {
            "completed": $((cve_completed + veille_completed)),
            "failed": $((cve_failed + veille_failed))
        },
        "Développement Tools": {"completed": 0, "failed": 0},
        "Reverse Engineering": {
            "completed": $malware_completed,
            "failed": $malware_failed
        },
        "Investigation Digitale": {"completed": 0, "failed": 0}
    },
    "difficulty_stats": {
        "Easy": {"completed": $easy_completed, "failed": $easy_failed},
        "Medium": {"completed": $medium_completed, "failed": $medium_failed},
        "Hard": {"completed": $hard_completed, "failed": $hard_failed}
    }
}
EOF

    mv "$temp_file" "$STATS_FILE"
    
    ui_success "✅ Migration terminée - anciennes stats préservées et réorganisées"
    ui_info "📁 Sauvegarde créée: $(basename "$STATS_FILE.backup."*)"
  fi
}
