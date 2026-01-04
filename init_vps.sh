#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose git
sudo systemctl enable --now docker
# Add current user to docker group
sudo usermod -aG docker $USER
echo "VPS Initialized. Please log out and back in for docker groups to take effect."