#!/bin/bash

# ============================================================================
# Punishment Module - Système de pénalités motivationnelles
# ============================================================================

readonly PUNISHMENT_TYPES=(
  "lock_screen"
  "network_restriction"
  "website_block"
  "wallpaper_shame"
  "notification_spam"
  "mouse_sensitivity"
)

# ============================================================================
# Application des pénalités
# ============================================================================

punishment_apply_random() {
  # Récupérer les paramètres de pénalité
  local min_duration max_duration
  min_duration=$(config_get '.punishment_settings.min_duration')
  max_duration=$(config_get '.punishment_settings.max_duration')

  # Générer une durée aléatoire
  local duration=$((RANDOM % (max_duration - min_duration + 1) + min_duration))

  # Choisir un type de pénalité aléatoire
  local punishment_type
  punishment_type=${PUNISHMENT_TYPES[$((RANDOM % ${#PUNISHMENT_TYPES[@]}))]}

  punishment_apply "$punishment_type" "$duration"
}

punishment_apply() {
  local punishment_type=$1
  local duration=$2

  ui_punishment_warning "$punishment_type" "$duration"

  # Countdown avant application
  ui_countdown 5 "Application de la pénalité dans"

  case "$punishment_type" in
  "lock_screen")
    punishment_lock_screen "$duration"
    ;;
  "network_restriction")
    punishment_restrict_network "$duration"
    ;;
  "website_block")
    punishment_block_websites "$duration"
    ;;
  "wallpaper_shame")
    punishment_change_wallpaper "$duration"
    ;;
  "notification_spam")
    punishment_notification_spam "$duration"
    ;;
  "mouse_sensitivity")
    punishment_reduce_mouse_sensitivity "$duration"
    ;;
  *)
    ui_error "Type de pénalité inconnu: $punishment_type"
    ;;
  esac
}

# ============================================================================
# Types de pénalités spécifiques
# ============================================================================

punishment_lock_screen() {
  local duration=$1

  ui_error "🔒 Écran verrouillé pour $duration minutes"

  # Essayer différentes méthodes de verrouillage selon l'environnement
  if command -v loginctl &>/dev/null; then
    loginctl lock-session
  elif command -v xscreensaver-command &>/dev/null; then
    xscreensaver-command -lock
  elif command -v gnome-screensaver-command &>/dev/null; then
    gnome-screensaver-command -l
  elif command -v swaylock &>/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    swaylock
  else
    ui_warning "Impossible de verrouiller l'écran automatiquement"
    ui_info "Veuillez verrouiller manuellement votre écran pour $duration minutes"
  fi

  # Programmer le déverrouillage (notification)
  (
    sleep $((duration * 60))
    punishment_send_unlock_notification
  ) &
}

punishment_restrict_network() {
  local duration=$1

  ui_error "🌐 Réseau restreint pour $duration minutes"

  # Vérifier si on peut utiliser NetworkManager
  if systemctl is-active --quiet NetworkManager; then
    # Créer un script de restauration
    cat >"$CONFIG_DIR/restore_network.sh" <<'EOF'
#!/bin/bash
sudo systemctl start NetworkManager
notify-send "🌐 Réseau restauré" "La restriction réseau a été levée."
EOF
    chmod +x "$CONFIG_DIR/restore_network.sh"

    # Couper le réseau
    sudo systemctl stop NetworkManager

    # Programmer la restauration
    (
      sleep $((duration * 60))
      bash "$CONFIG_DIR/restore_network.sh"
      rm -f "$CONFIG_DIR/restore_network.sh"
    ) &

    ui_info "Le réseau sera restauré automatiquement dans $duration minutes"
  else
    ui_warning "NetworkManager non disponible, simulation de la restriction"
    punishment_simulate_network_restriction "$duration"
  fi
}

punishment_block_websites() {
  local duration=$1

  ui_error "🚫 Sites distractifs bloqués pour $duration minutes"

  # Sites à bloquer
  local blocked_sites=(
    "youtube.com"
    "www.youtube.com"
    "reddit.com"
    "www.reddit.com"
    "facebook.com"
    "www.facebook.com"
    "twitter.com"
    "www.twitter.com"
    "x.com"
    "www.x.com"
    "instagram.com"
    "www.instagram.com"
    "tiktok.com"
    "www.tiktok.com"
    "twitch.tv"
    "www.twitch.tv"
  )

  # Créer le fichier de blocage temporaire
  local block_file="$CONFIG_DIR/blocked_hosts"
  {
    echo "# Learning Challenge - Punishment Block"
    echo "# Applied on $(date)"
    for site in "${blocked_sites[@]}"; do
      echo "127.0.0.1 $site"
    done
  } >"$block_file"

  # Ajouter au hosts système (nécessite sudo)
  if sudo -n true 2>/dev/null; then
    sudo bash -c "cat '$block_file' >> /etc/hosts"

    # Programmer la restauration
    (
      sleep $((duration * 60))
      punishment_restore_websites "$block_file"
    ) &

    ui_info "Les sites seront débloqués automatiquement dans $duration minutes"
  else
    ui_warning "Privilèges sudo requis pour bloquer les sites"
    ui_info "Blocage symbolique appliqué (fichier: $block_file)"
  fi
}

punishment_change_wallpaper() {
  local duration=$1

  ui_error "🖼️ Wallpaper de la honte appliqué pour $duration minutes"

  # Créer un wallpaper de motivation/honte
  local shame_wallpaper="$CONFIG_DIR/shame_wallpaper.png"

  # Sauvegarder le wallpaper actuel si possible
  punishment_backup_wallpaper

  # Créer ou télécharger un wallpaper motivationnel
  punishment_create_shame_wallpaper "$shame_wallpaper"

  # Appliquer le nouveau wallpaper
  punishment_set_wallpaper "$shame_wallpaper"

  # Programmer la restauration
  (
    sleep $((duration * 60))
    punishment_restore_wallpaper
  ) &

  ui_info "Le wallpaper sera restauré dans $duration minutes"
}

punishment_notification_spam() {
  local duration=$1

  ui_error "📢 Notifications de rappel activées pour $duration minutes"

  local end_time=$(($(date +%s) + duration * 60))

  # Messages motivationnels
  local messages=(
    "💀 Vous avez échoué à votre mission..."
    "📚 Il est temps de retourner étudier !"
    "⏰ La discipline mène au succès"
    "🎯 Prochain challenge : ne pas échouer !"
    "💪 L'échec est le début de la réussite"
    "🔥 Transformez cette défaite en victoire !"
  )

  # Lancer le spam de notifications
  (
    while [[ $(date +%s) -lt $end_time ]]; do
      local message=${messages[$((RANDOM % ${#messages[@]}))]}
      notify-send "🎯 Learning Challenge" "$message" --urgency=normal
      sleep 180 # Une notification toutes les 3 minutes
    done
    notify-send "✅ Pénalité terminée" "Les notifications de rappel sont désactivées."
  ) &
}

punishment_reduce_mouse_sensitivity() {
  local duration=$1

  ui_error "🖱️ Sensibilité de souris réduite pour $duration minutes"

  # Sauvegarder les paramètres actuels
  punishment_backup_mouse_settings

  # Réduire la sensibilité (si xinput est disponible)
  if command -v xinput &>/dev/null; then
    local mouse_ids
    mouse_ids=$(xinput list | grep -i mouse | grep -o 'id=[0-9]*' | cut -d= -f2)

    for id in $mouse_ids; do
      # Sauvegarder les paramètres actuels
      xinput list-props "$id" >"$CONFIG_DIR/mouse_$id.backup" 2>/dev/null || true

      # Réduire la sensibilité à 30%
      xinput set-prop "$id" "libinput Accel Speed" -0.7 2>/dev/null || true
    done

    # Programmer la restauration
    (
      sleep $((duration * 60))
      punishment_restore_mouse_settings
    ) &

    ui_info "La sensibilité de la souris sera restaurée dans $duration minutes"
  else
    ui_warning "xinput non disponible, impossible de modifier la sensibilité"
  fi
}

# ============================================================================
# Fonctions utilitaires pour les pénalités
# ============================================================================

punishment_simulate_network_restriction() {
  local duration=$1

  # Créer un fichier de rappel visuel
  cat >"$CONFIG_DIR/network_restricted.txt" <<EOF
RÉSEAU SYMBOLIQUEMENT RESTREINT

Durée: $duration minutes
Début: $(date)
Fin prévue: $(date -d "+${duration} minutes")

Cette restriction est symbolique car les privilèges
administrateur ne sont pas disponibles.

Respectez cette restriction pour maintenir l'intégrité
du système de motivation !
EOF

  ui_info "Fichier de restriction créé: $CONFIG_DIR/network_restricted.txt"

  # Supprimer le fichier après la durée
  (
    sleep $((duration * 60))
    rm -f "$CONFIG_DIR/network_restricted.txt"
    notify-send "🌐 Restriction levée" "La restriction réseau symbolique est terminée."
  ) &
}

punishment_create_shame_wallpaper() {
  local output_file=$1

  # Si ImageMagick est disponible, créer un wallpaper personnalisé
  if command -v convert &>/dev/null; then
    convert -size 1920x1080 xc:black \
      -gravity center \
      -fill red \
      -pointsize 72 \
      -annotate +0-200 "MISSION ÉCHOUÉE" \
      -fill white \
      -pointsize 48 \
      -annotate +0-100 "IL EST TEMPS DE SE REMETTRE AU TRAVAIL" \
      -fill yellow \
      -pointsize 36 \
      -annotate +0+50 "$(date '+%H:%M - %d/%m/%Y')" \
      "$output_file" 2>/dev/null || true
  else
    # Créer un fichier texte simple si convert n'est pas disponible
    cat >"${output_file}.txt" <<EOF
═══════════════════════════════════════
            MISSION ÉCHOUÉE
═══════════════════════════════════════

Il est temps de se remettre au travail !

Date: $(date '+%H:%M - %d/%m/%Y')
═══════════════════════════════════════
EOF
  fi
}

punishment_backup_wallpaper() {
  # Essayer de sauvegarder le wallpaper actuel selon l'environnement
  local backup_info="$CONFIG_DIR/wallpaper_backup.info"

  if command -v gsettings &>/dev/null; then
    # GNOME
    gsettings get org.gnome.desktop.background picture-uri >"$backup_info" 2>/dev/null || true
  elif command -v xfconf-query &>/dev/null; then
    # XFCE
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image >"$backup_info" 2>/dev/null || true
  fi
}

punishment_set_wallpaper() {
  local wallpaper_file=$1

  # Appliquer selon l'environnement de bureau
  if command -v gsettings &>/dev/null; then
    # GNOME
    gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper_file" 2>/dev/null || true
  elif command -v xfconf-query &>/dev/null; then
    # XFCE
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$wallpaper_file" 2>/dev/null || true
  elif command -v feh &>/dev/null; then
    # Feh (environnements légers)
    feh --bg-scale "$wallpaper_file" 2>/dev/null || true
  fi
}

punishment_restore_wallpaper() {
  local backup_info="$CONFIG_DIR/wallpaper_backup.info"

  if [[ -f "$backup_info" ]]; then
    local original_wallpaper
    original_wallpaper=$(cat "$backup_info")

    if command -v gsettings &>/dev/null; then
      gsettings set org.gnome.desktop.background picture-uri "$original_wallpaper" 2>/dev/null || true
    elif command -v xfconf-query &>/dev/null; then
      xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$original_wallpaper" 2>/dev/null || true
    fi

    rm -f "$backup_info"
  fi

  notify-send "🖼️ Wallpaper restauré" "Le fond d'écran original a été rétabli."
}

punishment_backup_mouse_settings() {
  if command -v xinput &>/dev/null; then
    xinput list >"$CONFIG_DIR/mouse_devices.backup"
  fi
}

punishment_restore_mouse_settings() {
  if command -v xinput &>/dev/null && [[ -f "$CONFIG_DIR/mouse_devices.backup" ]]; then
    # Restaurer les paramètres par défaut
    local mouse_ids
    mouse_ids=$(xinput list | grep -i mouse | grep -o 'id=[0-9]*' | cut -d= -f2)

    for id in $mouse_ids; do
      # Remettre la sensibilité par défaut
      xinput set-prop "$id" "libinput Accel Speed" 0 2>/dev/null || true
    done

    rm -f "$CONFIG_DIR"/mouse_*.backup
  fi

  notify-send "🖱️ Souris restaurée" "La sensibilité de la souris a été rétablie."
}

punishment_restore_websites() {
  local block_file=$1

  if [[ -f "$block_file" ]] && sudo -n true 2>/dev/null; then
    # Supprimer les lignes ajoutées du fichier hosts
    sudo sed -i '/# Learning Challenge - Punishment Block/,/^$/d' /etc/hosts
    rm -f "$block_file"

    notify-send "🌐 Sites débloqués" "L'accès aux sites web a été restauré."
  fi
}

punishment_send_unlock_notification() {
  notify-send "🔓 Pénalité terminée" "La période de verrouillage est terminée. Vous pouvez déverrouiller votre écran."
}

# ============================================================================
# Gestion des pénalités actives
# ============================================================================

punishment_list_active() {
  ui_info "Pénalités actives :"

  local found_any=false

  # Vérifier les différents types de pénalités
  if [[ -f "$CONFIG_DIR/network_restricted.txt" ]]; then
    echo "  🌐 Restriction réseau active"
    found_any=true
  fi

  if [[ -f "$CONFIG_DIR/wallpaper_backup.info" ]]; then
    echo "  🖼️ Wallpaper de la honte actif"
    found_any=true
  fi

  if pgrep -f "punishment.*notification_spam" &>/dev/null; then
    echo "  📢 Spam de notifications actif"
    found_any=true
  fi

  if [[ ! $found_any ]]; then
    echo "  Aucune pénalité active"
  fi
}

punishment_emergency_stop() {
  ui_warning "🚨 ARRÊT D'URGENCE DES PÉNALITÉS"

  if ui_confirm "Voulez-vous vraiment arrêter toutes les pénalités actives ?"; then
    # Arrêter toutes les pénalités en cours
    pkill -f "punishment" 2>/dev/null || true

    # Restaurer les paramètres
    punishment_restore_wallpaper 2>/dev/null || true
    punishment_restore_mouse_settings 2>/dev/null || true

    # Nettoyer les fichiers temporaires
    rm -f "$CONFIG_DIR/network_restricted.txt"
    rm -f "$CONFIG_DIR/blocked_hosts"
    rm -f "$CONFIG_DIR/restore_network.sh"

    ui_success "Toutes les pénalités ont été annulées."
  fi
}
