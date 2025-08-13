#!/bin/bash

# ============================================================================
# Stats Module - Gestion des statistiques et du suivi des performances
# ============================================================================

# ============================================================================
# Enregistrement des statistiques
# ============================================================================

stats_record_completion() {
  local activity=$1
  local success=$2 # true/false

  local temp_file
  temp_file=$(mktemp)

  if [[ "$success" == "true" ]]; then
    # Mission réussie
    jq --arg activity "$activity" '
            .total_missions += 1 |
            .completed += 1 |
            .current_streak += 1 |
            .best_streak = ([.best_streak, .current_streak] | max) |
            .last_mission_date = (now | strftime("%Y-%m-%d")) |
            .activity_stats[$activity].completed += 1
        ' "$STATS_FILE" >"$temp_file"
  else
    # Mission échouée
    jq --arg activity "$activity" '
            .total_missions += 1 |
            .failed += 1 |
            .current_streak = 0 |
            .last_mission_date = (now | strftime("%Y-%m-%d")) |
            .activity_stats[$activity].failed += 1
        ' "$STATS_FILE" >"$temp_file"
  fi

  mv "$temp_file" "$STATS_FILE"
}

# ============================================================================
# Affichage des statistiques
# ============================================================================

stats_display() {
  ui_header "Statistiques de Performance"

  local total completed failed current_streak best_streak
  total=$(config_get '.total_missions' "$STATS_FILE")
  completed=$(config_get '.completed' "$STATS_FILE")
  failed=$(config_get '.failed' "$STATS_FILE")
  current_streak=$(config_get '.current_streak' "$STATS_FILE")
  best_streak=$(config_get '.best_streak' "$STATS_FILE")

  local success_rate=0
  if [[ $total -gt 0 ]]; then
    success_rate=$(echo "scale=1; $completed * 100 / $total" | bc -l 2>/dev/null || echo "0")
  fi

  # Affichage principal
  ui_stats_box "$total" "$completed" "$failed" "$success_rate" "$current_streak" "$best_streak"

  echo
  ui_divider
  echo

  # Statistiques par activité
  stats_display_by_activity

  echo
  ui_wait
}

stats_display_by_activity() {
  ui_info "Statistiques par activité :"
  echo

  local activities=("Challenge TryHackMe" "Documentation CVE" "Analyse de malware" "CTF Practice" "Veille sécurité")

  for activity in "${activities[@]}"; do
    local completed failed
    completed=$(jq -r --arg activity "$activity" '.activity_stats[$activity].completed // 0' "$STATS_FILE")
    failed=$(jq -r --arg activity "$activity" '.activity_stats[$activity].failed // 0' "$STATS_FILE")
    local total=$((completed + failed))

    if [[ $total -gt 0 ]]; then
      local rate
      rate=$(echo "scale=1; $completed * 100 / $total" | bc -l 2>/dev/null || echo "0")
      printf "  %-20s: %2d complétées, %2d échouées (%s%%)\n" \
        "$activity" "$completed" "$failed" "$rate"
    else
      printf "  %-20s: Aucune mission effectuée\n" "$activity"
    fi
  done
}

# ============================================================================
# Statistiques avancées
# ============================================================================

stats_get_success_rate() {
  local total completed
  total=$(config_get '.total_missions' "$STATS_FILE")
  completed=$(config_get '.completed' "$STATS_FILE")

  if [[ $total -gt 0 ]]; then
    echo "scale=2; $completed * 100 / $total" | bc -l
  else
    echo "0"
  fi
}

stats_get_activity_performance() {
  local activity=$1
  local completed failed
  completed=$(jq -r --arg activity "$activity" '.activity_stats[$activity].completed // 0' "$STATS_FILE")
  failed=$(jq -r --arg activity "$activity" '.activity_stats[$activity].failed // 0' "$STATS_FILE")
  local total=$((completed + failed))

  echo "completed:$completed"
  echo "failed:$failed"
  echo "total:$total"

  if [[ $total -gt 0 ]]; then
    local rate
    rate=$(echo "scale=2; $completed * 100 / $total" | bc -l)
    echo "rate:$rate"
  else
    echo "rate:0"
  fi
}

stats_get_current_streak() {
  config_get '.current_streak' "$STATS_FILE"
}

stats_get_best_streak() {
  config_get '.best_streak' "$STATS_FILE"
}

# ============================================================================
# Gestion des données
# ============================================================================

stats_reset() {
  local temp_file
  temp_file=$(mktemp)

  cat >"$temp_file" <<EOF
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

  mv "$temp_file" "$STATS_FILE"
}

stats_export() {
  local export_file="$HOME/learning_stats_$(date +%Y%m%d_%H%M%S).json"
  cp "$STATS_FILE" "$export_file"
  ui_success "Statistiques exportées vers: $export_file"
}

stats_get_weekly_summary() {
  local last_week
  last_week=$(date -d "7 days ago" +%s)

  # Pour l'instant, on affiche juste les stats générales
  # Plus tard on pourra ajouter un tracking par date
  ui_info "Résumé de la semaine :"
  local total completed failed
  total=$(config_get '.total_missions' "$STATS_FILE")
  completed=$(config_get '.completed' "$STATS_FILE")
  failed=$(config_get '.failed' "$STATS_FILE")

  echo "  Missions cette période: $total"
  echo "  Succès: $completed"
  echo "  Échecs: $failed"
}

# ============================================================================
# Badges et récompenses (pour motivation)
# ============================================================================

stats_check_achievements() {
  local completed current_streak best_streak
  completed=$(config_get '.completed' "$STATS_FILE")
  current_streak=$(config_get '.current_streak' "$STATS_FILE")
  best_streak=$(config_get '.best_streak' "$STATS_FILE")

  local achievements=()

  # Badges basés sur le nombre de missions
  if [[ $completed -ge 100 ]]; then
    achievements+=("🏆 Centurion (100 missions)")
  elif [[ $completed -ge 50 ]]; then
    achievements+=("🥈 Vétéran (50 missions)")
  elif [[ $completed -ge 10 ]]; then
    achievements+=("🥉 Apprenti (10 missions)")
  fi

  # Badges basés sur les streaks
  if [[ $best_streak -ge 30 ]]; then
    achievements+=("🔥 Légende (30 jours consécutifs)")
  elif [[ $best_streak -ge 14 ]]; then
    achievements+=("⚡ Déterminé (14 jours consécutifs)")
  elif [[ $best_streak -ge 7 ]]; then
    achievements+=("💪 Constant (7 jours consécutifs)")
  fi

  if [[ ${#achievements[@]} -gt 0 ]]; then
    ui_info "🏆 Récompenses débloquées :"
    for achievement in "${achievements[@]}"; do
      echo "  $achievement"
    done
    echo
  fi
}

stats_get_motivation_message() {
  local current_streak
  current_streak=$(config_get '.current_streak' "$STATS_FILE")
  local success_rate
  success_rate=$(stats_get_success_rate)

  if [[ $(echo "$success_rate >= 80" | bc -l) -eq 1 ]]; then
    echo "🌟 Performance excellente ! Continuez comme ça !"
  elif [[ $(echo "$success_rate >= 60" | bc -l) -eq 1 ]]; then
    echo "👍 Bonne progression ! Vous êtes sur la bonne voie."
  elif [[ $current_streak -ge 3 ]]; then
    echo "🔥 Belle série en cours ! Ne cassez pas la chaîne !"
  else
    echo "💪 Chaque expert était un débutant. Continuez à apprendre !"
  fi
}
