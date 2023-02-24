#!/bin/bash

echo "Updating the Repos"
sudo apt update
echo "###################################################################################################################################################################"




echo "Install docker && add user to docker group"
sudo apt install docker.io -y 
sudo usermod -a -G docker devops
echo "##################################################################################################################################################################"




echo "Install Docker Compose"
sudo curl -SL https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
echo "###################################################################################################################################################################"





echo "Installing systemd to enable systemctl"
curl -L -O "https://raw.githubusercontent.com/nullpo-head/wsl-distrod/main/install.sh"
sudo chmod +x install.sh
sudo ./install.sh install
sudo /opt/distrod/bin/distrod enable
echo "###################################################################################################################################################################"




echo "Install Kind to create k8 cluster"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
sudo chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
echo "###################################################################################################################################################################"




echo "Install k3d to create k8 cluster "
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d
echo "###################################################################################################################################################################"




echo "Install helm to manage k8 manifests"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
echo "###################################################################################################################################################################"



echo "Install kubectl to connect with k8 cluster"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "###################################################################################################################################################################"




echo "Define Config file for kind cluster && k3d"
sudo cat <<EOF > /home/devops/kind.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
EOF
sudo cat /home/devops/kind.yaml
echo "##################################################################################################################################################################"


echo "installing open-ssh & net-tools"
sudo apt install openssh-server -y && apt install net-tools -y
sudo ufw allow ssh
echo "##################################################################################################################################################################"

echo "creating jenkins_Slave directory giving permissions to devops "
sudo mkdir /opt/jenkins_slave
sudo chown devops.devops /opt/jenkins_slave
echo "##################################################################################################################################################################"


echo "Installing GitHub Cli"
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y
echo "##################################################################################################################################################################"

