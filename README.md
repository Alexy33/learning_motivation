# Learning Challenge Manager

Un système de gestion de tâches gamifié pour l'apprentissage en cybersécurité, inspiré des mécaniques de motivation par pénalités.

## 🎯 Concept

Le Learning Challenge Manager génère des missions d'apprentissage aléatoires avec des difficultés et temps variables. En cas d'échec à terminer dans les temps, des pénalités temporaires sont appliquées pour maintenir la motivation.

## ✨ Fonctionnalités

- **Missions aléatoires** : Challenge TryHackMe, Documentation CVE, Analyse de malware, CTF, Veille sécurité
- **Système de difficulté** : Easy (2h), Medium (3h), Hard (4h)
- **Joker quotidien** : Possibilité de changer de mission 1 fois par jour
- **Pénalités motivationnelles** :
  - Verrouillage d'écran temporaire
  - Restriction réseau
  - Blocage de sites distractifs
  - Wallpaper de motivation
  - Notifications de rappel
  - Réduction de sensibilité souris
- **Statistiques complètes** : Suivi des performances, séries de succès
- **Interface moderne** avec [gum](https://github.com/charmbracelet/gum)

## 📋 Prérequis

### Arch Linux
```bash
sudo pacman -S gum jq bc
```

### Autres distributions
```bash
# Ubuntu/Debian
sudo apt install jq bc
# Installer gum depuis les releases GitHub

# Fedora
sudo dnf install jq bc
```

## 🚀 Installation

1. **Cloner le projet**
```bash
git clone <repo-url> learning-challenge
cd learning-challenge
```

2. **Rendre les scripts exécutables**
```bash
chmod +x learning.sh
chmod +x bin/*
```

3. **Ajouter au PATH (optionnel mais recommandé)**
```bash
# Ajouter à ~/.bashrc ou ~/.zshrc
export PATH="$PATH:$(pwd)/bin"

# Ou créer des liens symboliques
sudo ln -s "$(pwd)/bin/learning-check" /usr/local/bin/
sudo ln -s "$(pwd)/bin/learning-status" /usr/local/bin/
sudo ln -s "$(pwd)/bin/learning-emergency" /usr/local/bin/
```

4. **Premier lancement**
```bash
./learning.sh
```

## 🎮 Utilisation

### Commandes principales

- `./learning.sh` - Lancer le gestionnaire principal
- `learning-check` - Valider une mission en cours
- `learning-status` - Voir le statut actuel
- `learning-emergency` - Arrêt d'urgence

### Workflow typique

1. **Démarrer une session**
   ```bash
   ./learning.sh
   ```

2. **Choisir une activité** depuis le menu interactif

3. **Accepter la mission générée** (difficulté et temps aléatoires)

4. **Travailler sur la mission**

5. **Valider en fin de session**
   ```bash
   learning-check
   ```

### Exemples de missions

- **Challenge TryHackMe Easy (2h)** : Résoudre une room facile
- **Documentation CVE Medium (3h)** : Analyser et documenter 3 CVE récentes
- **Analyse malware Hard (4h)** : Reverse engineering d'un échantillon

## ⚙️ Configuration

### Fichiers de configuration

- `~/.learning_challenge/config.json` - Configuration générale
- `~/.learning_challenge/stats.json` - Statistiques de performance
- `~/.learning_challenge/current_mission.json` - Mission active

### Personnalisation des durées

```bash
./learning.sh
# Menu Configuration > Modifier les durées par difficulté
```

### Désactiver les pénalités

Éditez `~/.learning_challenge/config.json` :
```json
{
  "punishment_settings": {
    "enabled": false
  }
}
```

## 🔧 Fonctionnalités avancées

### Statut en temps réel

```bash
# Statut détaillé
learning-status

# Statut simple pour scripts
learning-status simple
# Output: ACTIVE:TryHackMe:1h30m

# Statistiques rapides
learning-status quick
```

### Mode urgence

```bash
# Menu interactif
learning-emergency

# Arrêt rapide
learning-emergency quick

# Arrêter juste la mission
learning-emergency quick mission
```

### Intégration dans la barre de statut

Pour i3bar, waybar, etc. :
```bash
# Dans votre config
"custom/learning": {
    "exec": "learning-status simple 2>/dev/null || echo 'IDLE'",
    "interval": 30
}
```

## 📊 Système de statistiques

- **Missions totales** et taux de réussite
- **Séries de succès** (streaks)
- **Performance par activité**
- **Badges de motivation** basés sur les performances

## 🛡️ Sécurité et permissions

Certaines pénalités nécessitent des privilèges élevés :
- **Restriction réseau** : `sudo` pour NetworkManager
- **Blocage de sites** : `sudo` pour modifier `/etc/hosts`

Les pénalités s'adaptent automatiquement si les permissions ne sont pas disponibles.

## 🐛 Dépannage

### La mission ne se lance pas
```bash
# Vérifier les dépendances
which gum jq bc

# Vérifier la configuration
learning-emergency status
```

### Les pénalités ne s'appliquent pas
```bash
# Vérifier les permissions sudo
sudo -n true

# Mode urgence pour nettoyer
learning-emergency reset
```

### Timer bloqué
```bash
# Forcer l'arrêt
learning-emergency quick

# Ou nettoyer manuellement
pkill -f "learning.*timer"
rm -f ~/.learning_challenge/timer.pid
```

## 🏗️ Architecture

```
learning-challenge/
├── learning.sh              # Script principal
├── bin/                      # Commandes utilitaires
│   ├── learning-check        # Validation missions
│   ├── learning-status       # Statut actuel
│   └── learning-emergency    # Mode urgence
├── lib/                      # Modules
│   ├── config.sh            # Configuration
│   ├── ui.sh                # Interface utilisateur
│   ├── mission.sh           # Logique missions
│   ├── stats.sh             # Statistiques
│   ├── timer.sh             # Gestion temps
│   └── punishment.sh        # Pénalités
└── README.md
```

## 🤝 Contribution

Les contributions sont bienvenues ! Quelques idées :

- Nouveaux types de missions
- Pénalités créatives supplémentaires
- Support d'autres environnements de bureau
- Intégrations avec des outils spécialisés
- Interface web/GUI

## 📝 License

MIT License - Voir le fichier LICENSE pour plus de détails.

## 🙏 Remerciements

- [Charm Bracelet](https://charm.sh/) pour les outils CLI magnifiques
- La communauté cybersécurité pour l'inspiration
- Les mécaniques de gamification qui rendent l'apprentissage addictif

---

*"La discipline est le pont entre les objectifs et l'accomplissement."*
