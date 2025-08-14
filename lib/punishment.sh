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

  # Choisir un type de pénalité disponible selon l'environnement
  local available_punishments=()

  # Toujours disponibles
  available_punishments+=("wallpaper_shame")
  available_punishments+=("notification_spam")

  # Selon les privilèges et outils
  if sudo -n true 2>/dev/null; then
    available_punishments+=("network_restriction")
    available_punishments+=("website_block")
  fi

  # Verrouillage selon l'environnement
  if command -v loginctl &>/dev/null || command -v swaylock &>/dev/null || 
     command -v gnome-screensaver-command &>/dev/null; then
    available_punishments+=("lock_screen")
  fi

  # Souris selon l'environnement
  if punishment_can_modify_mouse; then
    available_punishments+=("mouse_sensitivity")
  fi

  # Choisir un type de pénalité aléatoire parmi les disponibles
  local punishment_type
  punishment_type=${available_punishments[$((RANDOM % ${#available_punishments[@]}))]}

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
# Détection de l'environnement
# ============================================================================

punishment_detect_environment() {
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
      echo "wayland_gnome"
    elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
      echo "wayland_kde"
    elif command -v hyprctl &>/dev/null; then
      echo "wayland_hyprland"
    elif command -v swaymsg &>/dev/null; then
      echo "wayland_sway"
    else
      echo "wayland_other"
    fi
  elif [[ -n "${DISPLAY:-}" ]]; then
    echo "x11"
  else
    echo "unknown"
  fi
}

punishment_can_modify_mouse() {
  # Hyprland
  if command -v hyprctl &>/dev/null; then
    return 0
  fi
  # Wayland avec GNOME
  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v gsettings &>/dev/null && [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    return 0
  fi
  # Wayland avec KDE
  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v kwriteconfig5 &>/dev/null && [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    return 0
  fi
  # Sway
  if command -v swaymsg &>/dev/null; then
    return 0
  fi
  # X11
  if [[ -n "${DISPLAY:-}" ]] && command -v xinput &>/dev/null; then
    return 0
  fi

  return 1
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
  elif command -v swaylock &>/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    swaylock
  elif command -v gnome-screensaver-command &>/dev/null; then
    gnome-screensaver-command -l
  else
    ui_warning "Impossible de verrouiller l'écran automatiquement"
    ui_info "Veuillez verrouiller manuellement votre écran pour $duration minutes"
  fi

  # Programmer le déverrouillage (notification)
  (
    sleep $((duration * 60))
    notify-send "🔓 Pénalité terminée" "La période de verrouillage est terminée. Vous pouvez déverrouiller votre écran."
  ) &
}

punishment_restrict_network() {
  local duration=$1

  ui_error "🌐 Réseau restreint pour $duration minutes"

  # Vérifier si on peut utiliser NetworkManager
  if systemctl is-active --quiet NetworkManager && sudo -n true 2>/dev/null; then
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
    # Simulation de restriction
    punishment_simulate_network_restriction "$duration"
  fi
}

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
    
    # Nettoyage symbolique
    (
      sleep $((duration * 60))
      rm -f "$block_file"
      notify-send "🌐 Sites débloqués" "Le blocage symbolique des sites est terminé."
    ) &
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

  local env
  env=$(punishment_detect_environment)

  case "$env" in
  "wayland_hyprland")
    punishment_reduce_mouse_hyprland "$duration"
    ;;
  "wayland_gnome")
    punishment_reduce_mouse_gnome_wayland "$duration"
    ;;
  "wayland_kde")
    punishment_reduce_mouse_kde_wayland "$duration"
    ;;
  "wayland_sway")
    punishment_reduce_mouse_sway "$duration"
    ;;
  "x11")
    punishment_reduce_mouse_x11 "$duration"
    ;;
  *)
    punishment_simulate_mouse_reduction "$duration"
    ;;
  esac
}

# ============================================================================
# Gestion souris par environnement
# ============================================================================

punishment_reduce_mouse_hyprland() {
  local duration=$1

  ui_info "🌊 Configuration Hyprland détectée"

  # Sauvegarder la configuration actuelle
  local current_sensitivity
  current_sensitivity=$(hyprctl getoption input:sensitivity | grep -oP 'float: \K[0-9.-]+' || echo "0")

  echo "sensitivity=$current_sensitivity" >"$CONFIG_DIR/mouse_hyprland_backup.conf"

  # Réduire la sensibilité (valeurs négatives = moins sensible)
  hyprctl keyword input:sensitivity -0.7

  ui_success "✓ Sensibilité réduite via Hyprland"

  # Programmer la restauration
  (
    sleep $((duration * 60))
    punishment_restore_mouse_hyprland
  ) &
}

punishment_restore_mouse_hyprland() {
  if [[ -f "$CONFIG_DIR/mouse_hyprland_backup.conf" ]]; then
    source "$CONFIG_DIR/mouse_hyprland_backup.conf"
    hyprctl keyword input:sensitivity "$sensitivity"
    rm -f "$CONFIG_DIR/mouse_hyprland_backup.conf"
  else
    hyprctl keyword input:sensitivity 0
  fi

  notify-send "🖱️ Souris restaurée" "Sensibilité normale rétablie (Hyprland)"
}

punishment_reduce_mouse_gnome_wayland() {
  local duration=$1

  # Sauvegarder les paramètres actuels
  local current_speed
  current_speed=$(gsettings get org.gnome.desktop.peripherals.mouse speed 2>/dev/null || echo "0.0")

  cat >"$CONFIG_DIR/mouse_gnome_backup.conf" <<EOF
speed=$current_speed
EOF

  # Réduire la sensibilité
  gsettings set org.gnome.desktop.peripherals.mouse speed -0.7

  ui_success "✓ Sensibilité réduite via GNOME Settings"

  # Programmer la restauration
  (
    sleep $((duration * 60))
    punishment_restore_mouse_gnome_wayland
  ) &
}

punishment_restore_mouse_gnome_wayland() {
  if [[ -f "$CONFIG_DIR/mouse_gnome_backup.conf" ]]; then
    source "$CONFIG_DIR/mouse_gnome_backup.conf"
    gsettings set org.gnome.desktop.peripherals.mouse speed "${speed//\'/}" 2>/dev/null || true
    rm -f "$CONFIG_DIR/mouse_gnome_backup.conf"
  fi

  notify-send "🖱️ Souris restaurée" "La sensibilité normale a été rétablie (GNOME/Wayland)."
}

punishment_reduce_mouse_kde_wayland() {
  local duration=$1

  # Sauvegarder les paramètres KDE
  local current_accel
  current_accel=$(kreadconfig5 --file kcminputrc --group Mouse --key Acceleration 2>/dev/null || echo "2.0")

  cat >"$CONFIG_DIR/mouse_kde_backup.conf" <<EOF
acceleration=$current_accel
EOF

  # Réduire la sensibilité
  kwriteconfig5 --file kcminputrc --group Mouse --key Acceleration 0.5
  qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

  ui_success "✓ Sensibilité réduite via KDE Settings"

  # Programmer la restauration
  (
    sleep $((duration * 60))
    punishment_restore_mouse_kde_wayland
  ) &
}

punishment_restore_mouse_kde_wayland() {
  if [[ -f "$CONFIG_DIR/mouse_kde_backup.conf" ]]; then
    source "$CONFIG_DIR/mouse_kde_backup.conf"
    kwriteconfig5 --file kcminputrc --group Mouse --key Acceleration "$acceleration"
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    rm -f "$CONFIG_DIR/mouse_kde_backup.conf"
  fi

  notify-send "🖱️ Souris restaurée" "La sensibilité normale a été rétablie (KDE/Wayland)."
}

punishment_reduce_mouse_sway() {
  local duration=$1

  # Appliquer une sensibilité réduite temporaire
  swaymsg input type:pointer accel_profile flat 2>/dev/null || true
  swaymsg input type:pointer pointer_accel -0.7 2>/dev/null || true

  ui_success "✓ Sensibilité réduite via Sway"

  # Programmer la restauration
  (
    sleep $((duration * 60))
    punishment_restore_mouse_sway
  ) &
}

punishment_restore_mouse_sway() {
  swaymsg input type:pointer accel_profile adaptive 2>/dev/null || true
  swaymsg input type:pointer pointer_accel 0 2>/dev/null || true
  notify-send "🖱️ Souris restaurée" "La sensibilité normale a été rétablie (Sway)."
}

punishment_reduce_mouse_x11() {
  local duration=$1

  ui_info "🖥️ Environnement X11 détecté"

  if command -v xinput &>/dev/null; then
    local mouse_ids
    mouse_ids=$(xinput list | grep -i mouse | grep -o 'id=[0-9]*' | cut -d= -f2)

    for id in $mouse_ids; do
      xinput set-prop "$id" "libinput Accel Speed" -0.7 2>/dev/null || true
    done

    ui_success "✓ Sensibilité réduite via xinput"

    # Programmer la restauration
    (
      sleep $((duration * 60))
      punishment_restore_mouse_x11
    ) &
  else
    punishment_simulate_mouse_reduction "$duration"
  fi
}

punishment_restore_mouse_x11() {
  if command -v xinput &>/dev/null; then
    local mouse_ids
    mouse_ids=$(xinput list | grep -i mouse | grep -o 'id=[0-9]*' | cut -d= -f2)

    for id in $mouse_ids; do
      xinput set-prop "$id" "libinput Accel Speed" 0 2>/dev/null || true
    done
  fi

  notify-send "🖱️ Souris restaurée" "La sensibilité normale a été rétablie (X11)."
}

punishment_simulate_mouse_reduction() {
  local duration=$1

  ui_warning "⚠️ Impossible de modifier la sensibilité automatiquement"
  ui_info "📝 SIMULATION: Réduisez manuellement votre sensibilité de souris"

  # Créer un fichier de rappel visuel
  cat >"$CONFIG_DIR/mouse_reduction_reminder.txt" <<EOF
🖱️ PÉNALITÉ: SENSIBILITÉ SOURIS RÉDUITE

Durée: $duration minutes
Début: $(date)
Fin prévue: $(date -d "+${duration} minutes")

CONSIGNE:
Réduisez manuellement la sensibilité de votre souris 
dans les paramètres système pendant cette durée.

Cette pénalité est basée sur l'honneur du système !
Respectez-la pour maintenir l'efficacité motivationnelle.

Instructions par environnement:
- GNOME: Paramètres > Souris > Vitesse du pointeur
- KDE: Paramètres système > Périphériques d'entrée > Souris
- XFCE: Paramètres > Souris et pavé tactile > Vitesse
EOF

  ui_info "📄 Fichier de rappel créé: $CONFIG_DIR/mouse_reduction_reminder.txt"

  if command -v notify-send &>/dev/null; then
    notify-send "🖱️ Pénalité Souris" "Réduisez manuellement votre sensibilité pendant $duration minutes" --urgency=critical
  fi

  # Programmer le nettoyage et la notification de fin
  (
    sleep $((duration * 60))
    rm -f "$CONFIG_DIR/mouse_reduction_reminder.txt"
    if command -v notify-send &>/dev/null; then
      notify-send "✅ Pénalité terminée" "Vous pouvez restaurer la sensibilité normale de votre souris"
    fi
  ) &
}

# ============================================================================
# Fonctions utilitaires wallpaper
# ============================================================================

punishment_backup_wallpaper() {
  local backup_info="$CONFIG_DIR/wallpaper_backup.info"

  if command -v gsettings &>/dev/null; then
    gsettings get org.gnome.desktop.background picture-uri >"$backup_info" 2>/dev/null || true
  elif command -v xfconf-query &>/dev/null; then
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image >"$backup_info" 2>/dev/null || true
  fi
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
╔══════════════════════════════════════════════════════════════╗
            MISSION ÉCHOUÉE
╚══════════════════════════════════════════════════════════════╝

Il est temps de se remettre au travail !

Date: $(date '+%H:%M - %d/%m/%Y')
╚══════════════════════════════════════════════════════════════╝
EOF
  fi
}

punishment_set_wallpaper() {
  local wallpaper_file=$1

  # Détecter l'environnement
  if command -v hyprctl &>/dev/null; then
    punishment_set_wallpaper_hyprland "$wallpaper_file"
  elif command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper_file" 2>/dev/null || true
  elif command -v xfconf-query &>/dev/null; then
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$wallpaper_file" 2>/dev/null || true
  elif command -v kwriteconfig5 &>/dev/null; then
    kwriteconfig5 --file kdesktoprc --group Desktop0 --key Wallpaper "$wallpaper_file" 2>/dev/null || true
  elif command -v feh &>/dev/null; then
    feh --bg-scale "$wallpaper_file" 2>/dev/null || true
  fi
}

punishment_set_wallpaper_hyprland() {
  local wallpaper_file=$1
  
  if command -v swww &>/dev/null; then
    swww img "$wallpaper_file" 2>/dev/null || true
  elif command -v hyprpaper &>/dev/null; then
    echo "preload = $wallpaper_file" > /tmp/hyprpaper_temp.conf
    echo "wallpaper = ,$wallpaper_file" >> /tmp/hyprpaper_temp.conf
    hyprpaper -c /tmp/hyprpaper_temp.conf &
  else
    if command -v swaybg &>/dev/null; then
      pkill swaybg 2>/dev/null || true
      swaybg -i "$wallpaper_file" &
    fi
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

  # Arrêter swaybg si en cours
  pkill swaybg 2>/dev/null || true

  # Supprimer wallpaper de honte
  rm -f "$CONFIG_DIR/shame_wallpaper.png" "$CONFIG_DIR/shame_wallpaper.png.txt"

  notify-send "🖼️ Wallpaper restauré" "Le fond d'écran original a été rétabli."
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

# ============================================================================
# Gestion des pénalités actives
# ============================================================================

punishment_has_active_punishments() {
  # Vérifier s'il y a des pénalités en cours
  if [[ -f "$CONFIG_DIR/network_restricted.txt" ]] ||
    [[ -f "$CONFIG_DIR/wallpaper_backup.info" ]] ||
    [[ -f "$CONFIG_DIR/blocked_hosts" ]] ||
    [[ -f "$CONFIG_DIR/mouse_reduction_reminder.txt" ]] ||
    [[ -f "$CONFIG_DIR"/mouse_*_backup.conf ]] ||
    pgrep -f "punishment.*notification_spam" &>/dev/null; then
    return 0 # Il y a des pénalités
  else
    return 1 # Pas de pénalités
  fi
}

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

  if [[ -f "$CONFIG_DIR/blocked_hosts" ]]; then
    echo "  🚫 Sites web bloqués"
    found_any=true
  fi

  if [[ -f "$CONFIG_DIR"/mouse_*_backup.conf ]] || [[ -f "$CONFIG_DIR/mouse_reduction_reminder.txt" ]]; then
    echo "  🖱️ Sensibilité souris réduite"
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

  # Arrêter tous les processus de pénalités
  pkill -f "punishment" 2>/dev/null || true

  # Restaurer les paramètres
  punishment_restore_wallpaper 2>/dev/null || true
  
  # Restaurer souris selon environnement
  [[ -f "$CONFIG_DIR/mouse_hyprland_backup.conf" ]] && punishment_restore_mouse_hyprland
  [[ -f "$CONFIG_DIR/mouse_gnome_backup.conf" ]] && punishment_restore_mouse_gnome_wayland
  [[ -f "$CONFIG_DIR/mouse_kde_backup.conf" ]] && punishment_restore_mouse_kde_wayland
  command -v xinput &>/dev/null && punishment_restore_mouse_x11

  # Nettoyer les fichiers temporaires
  rm -f "$CONFIG_DIR/network_restricted.txt"
  rm -f "$CONFIG_DIR/blocked_hosts"
  rm -f "$CONFIG_DIR/restore_network.sh"
  rm -f "$CONFIG_DIR/mouse_reduction_reminder.txt"

  # Restaurer réseau si nécessaire
  if sudo -n true 2>/dev/null; then
    sudo systemctl start NetworkManager 2>/dev/null || true
    sudo sed -i '/# Learning Challenge - Punishment Block/,/^$/d' /etc/hosts 2>/dev/null || true
  fi

  ui_success "Toutes les pénalités ont été annulées."
}