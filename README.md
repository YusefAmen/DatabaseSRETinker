# DatabaseSRETinker

# Data Tinkering Environment

This repository contains the configuration and setup for a local data tinkering environment using Docker, Kubernetes (Kind), Helm, and Python.

## Prerequisites
- macOS Sequoia 15.2
- Minimum Free Storage: 100GB
- External drive for Time Machine backup (e.g., WD Passport)

## Setup Instructions

### 1. Backup
- Use Time Machine to back up your system to an external drive.

### 2. Install Core Tools
- Install Homebrew packages:
  ```bash
  brew bundle --file=Brewfile

- Set up Helm:
  ```bash
  while read -r name url; do helm repo add "$name" "$url"; done < helm-repos.txt
  helm repo update
  ```

**Note**: The Grafana service uses a NodePort on port 30000, which is mapped to host port 3000 via the Kind cluster configuration. Kubernetes NodePort values must be in the range 30000–32767.
