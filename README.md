# Learning Challenge Manager

Un système de gestion de défis d'apprentissage gamifié pour la cybersécurité, avec motivation par pénalités temporaires.

## 🎯 Concept

Le Learning Challenge Manager génère des missions d'apprentissage avec des difficultés et temps variables. En cas d'échec à terminer dans les temps, des pénalités temporaires motivationnelles sont appliquées.

## ✨ Fonctionnalités

### 🎮 **Interface Unifiée**

- **Menu principal** avec navigation contextuelle
- **Gestion complète** depuis une seule commande
- **Interface moderne** avec [gum](https://github.com/charmbracelet/gum)

### 🎯 **Système de Missions**

- **Challenge TryHackMe** : Difficulté aléatoire (Easy/Medium/Hard)
- **Documentation CVE** : Thèmes selon difficulté choisie
- **Analyse de malware** : Du basique au reverse engineering
- **CTF Practice** : Web, crypto, forensics, pwn
- **Veille sécurité** : Actualités à analyses géopolitiques
- **Mission unique** : Une seule mission à la fois
- **Joker quotidien** : Changer de mission 1 fois par jour

### ⏰ **Gestion du Temps**

- **Easy** : 2h | **Medium** : 3h | **Hard** : 4h
- **Timer en arrière-plan** avec notifications
- **Rappels** à 75%, 90% et 95% du temps

### 💀 **Pénalités Motivationnelles**

- **Verrouillage d'écran** temporaire (30-60 min)
- **Restriction réseau** avec restauration auto
- **Blocage sites** distractifs (YouTube, Reddit...)
- **Wallpaper motivationnel** temporaire
- **Notifications de rappel** périodiques
- **Réduction sensibilité souris**

### 📊 **Statistiques Complètes**

- **Suivi global** : missions, taux de réussite, streaks
- **Par activité** : performance détaillée par type
- **Par difficulté** : analyse Easy/Medium/Hard
- **Badges** : Apprenti, Vétéran, Centurion, Maître Hard...

## 📋 Prérequis

### Arch Linux

```bash
sudo pacman -S gum jq bc
```

### Autres distributions

```bash
# Ubuntu/Debian
sudo apt install jq bc
# Installer gum depuis https://github.com/charmbracelet/gum/releases

# Fedora  
sudo dnf install jq bc
```

## 🚀 Installation

### Installation automatique

```bash
git clone <repo-url> learning-challenge
cd learning-challenge
chmod +x install.sh
./install.sh
```

### Installation manuelle

```bash
git clone <repo-url> learning-challenge
cd learning-challenge
chmod +x learning.sh
./learning.sh
```

## 🎮 Utilisation

### Lancement

```bash
learning  # Si installé avec install.sh
# OU
./learning.sh  # Depuis le dossier du projet
```

### Navigation

Le menu principal s'adapte selon votre état :

**Sans mission active :**

- 🎯 **Challenges** → Choisir un nouveau défi
- 📊 **Statistiques** → Voir vos performances  
- ⚙️ **Paramètres** → Configuration
- 🚪 **Quitter**

**Avec mission active :**

- 📋 **Mission en cours** → Détails et progression
- ✅ **Terminer la mission** → Validation
- 🚨 **Urgence** → Arrêt d'urgence
- 💀 **Peine encourue** → Info pénalités
- 🎯 **Challenges** → (Bloqué pendant mission)
- 📊 **Statistiques**
- ⚙️ **Paramètres**
- 🚪 **Quitter**

### Workflow typique

1. **Lancer** `learning`
2. **Choisir** "🎯 Challenges"
3. **Sélectionner** un type d'activité
4. **Accepter** la mission/thème généré
5. **Travailler** sur votre défi
6. **Valider** avec "✅ Terminer la mission"

## 🎯 Types de Challenges

### 🔥 Challenge TryHackMe

- **Système aléatoire** : Easy/Medium/Hard généré automatiquement
- **Durées** : 2h/3h/4h selon difficulté

### 📚 Documentation CVE  

- **Easy** : 1 CVE récente, vulnérabilité web basique
- **Medium** : 2-3 CVE critiques, rapport avec POC
- **Hard** : 3-5 CVE chaînées, guide mitigation complet

### 🦠 Analyse de malware

- **Easy** : Analyse statique, IoC basiques
- **Medium** : Reverse engineering, analyse dynamique  
- **Hard** : APT sophistiqué, unpacking avancé

### 🏴‍☠️ CTF Practice

- **Easy** : Web faciles, crypto basique, forensics simples
- **Medium** : Reverse engineering, pwn avec protections
- **Hard** : 0-day, malware obfusqué, cryptanalyse

### 🔍 Veille sécurité

- **Easy** : Actualités hebdo, 3 techniques d'attaque
- **Medium** : Rapport APT, tendances mensuelles
- **Hard** : Analyse géopolitique, prospective

## ⚙️ Configuration

### Durées personnalisées

Menu → Paramètres → Modifier les durées par difficulté

### Pénalités

Menu → Paramètres → Configuration des pénalités

- Activer/désactiver
- Modifier durées min/max

### Notifications  

Menu → Paramètres → Paramètres de notifications

- Activer/désactiver notifications
- Contrôler sons d'alerte

## 📊 Statistiques

### Métriques principales

- **Missions totales** et taux de réussite
- **Série actuelle** et meilleure série
- **Performance par activité** (TryHackMe, CVE...)
- **Performance par difficulté** (Easy, Medium, Hard)

### Badges disponibles

- 🥉 **Apprenti** (10 missions)
- 🥈 **Vétéran** (50 missions)  
- 🏆 **Centurion** (100 missions)
- 💪 **Constant** (7 jours consécutifs)
- ⚡ **Déterminé** (14 jours consécutifs)
- 🔥 **Légende** (30 jours consécutifs)
- 💀 **Maître Hard** (10 missions Hard)

## 🚨 Mode Urgence

En cas de problème, le menu Urgence permet :

- **Arrêter mission** actuelle sans pénalité
- **Stopper pénalités** en cours
- **Réinitialisation complète** du système
- **Diagnostic** état du système

## 🗂️ Structure des fichiers

```
learning-challenge/
├── learning.sh              # Interface principale unifiée
├── install.sh               # Installation automatique  
├── lib/                     # Modules fonctionnels
│   ├── config.sh           # Configuration
│   ├── ui.sh               # Interface utilisateur
│   ├── mission.sh          # Logique missions
│   ├── stats.sh            # Statistiques
│   ├── timer.sh            # Gestion temps
│   └── punishment.sh       # Pénalités
└── README.md
```

### Données utilisateur

- `~/.learning_challenge/config.json` - Configuration
- `~/.learning_challenge/stats.json` - Statistiques
- `~/.learning_challenge/current_mission.json` - Mission active

## 🔧 Dépannage

### Installation des dépendances

```bash
# Arch Linux
sudo pacman -S gum jq bc

# Vérifier installation
which gum jq bc
```

### Problèmes de permissions

```bash
# Pénalités nécessitent sudo pour :
sudo systemctl stop NetworkManager  # Restriction réseau
sudo tee -a /etc/hosts              # Blocage sites
```

### Réinitialisation

```bash
learning  # → Menu → Urgence → Réinitialisation complète
# OU suppression manuelle
rm -rf ~/.learning_challenge
```

## 🤝 Contribution

Idées d'améliorations :

- Nouveaux types de missions
- Pénalités créatives supplémentaires  
- Support d'autres environnements de bureau
- Intégrations avec outils spécialisés
- Mode collaboratif/équipe

## 📝 License

MIT License

## 🎯 Philosophie

*"La discipline est le pont entre les objectifs et l'accomplissement."*

Le Learning Challenge Manager transforme l'apprentissage en cybersécurité en expérience gamifiée motivante, où chaque défi completed vous rapproche de l'expertise.
