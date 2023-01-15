#!/bin/bash

echo "Updating the Repos"
sudo apt update
echo "####################################################################################"




echo "Install docker"
sudo apt install docker.io -y 
echo "####################################################################################"




echo "Installing systemd to enable systemctl"
curl -L -O "https://raw.githubusercontent.com/nullpo-head/wsl-distrod/main/install.sh"
sudo chmod +x install.sh
sudo ./install.sh install
# sudo /opt/distrod/bin/distrod enable --start-on-windows-boot
sudo /opt/distrod/bin/distrod enable
echo "####################################################################################"



echo "Install Kind to create k8 cluster"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
sudo chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
echo "####################################################################################"




echo "Install k3d to create k8 cluster "
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d
echo "####################################################################################"




echo "Install helm to manage k8 manifests"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
echo "####################################################################################"



echo "Install kubectl to connect with k8 cluster"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "####################################################################################"
