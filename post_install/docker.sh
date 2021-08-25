#!/bin/bash

sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo systemctl enable docker