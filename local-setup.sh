#!/bin/bash

echo "Updating the Repos && install tools"
sudo apt update && sudo apt upgrade -y
sudo apt install -y zip unzip tree fish 
echo "###################################################################################################################################################################"




echo "Install docker, docker-compose && add user to docker group"
sudo apt install -y docker.io docker-compose  
sudo usermod -a -G docker dheeraj
echo "##################################################################################################################################################################"




echo "Install kubectx,kubens"
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

echo "###################################################################################################################################################################"





# echo "Installing systemd to enable systemctl"
# sudo cat <<EOF > /etc/wsl.conf
# [boot]
# systemd=true
# EOF
# curl -L -O "https://raw.githubusercontent.com/nullpo-head/wsl-distrod/main/install.sh"
# sudo chmod +x install.sh
# sudo ./install.sh install
# sudo /opt/distrod/bin/distrod enable
echo "###################################################################################################################################################################"




echo "Install Kind to create k8 cluster"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.18.0/kind-linux-amd64
sudo chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
echo "###################################################################################################################################################################"




echo "Install k3d to create k8 cluster "
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d
echo "###################################################################################################################################################################"




echo "Install kubectl to connect with k8 cluster"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "###################################################################################################################################################################"



echo "Install helm to manage k8 manifests"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
echo "###################################################################################################################################################################"



echo "Install k9s cli to manage kubernetes"
wget https://github.com/derailed/k9s/releases/download/v0.27.3/k9s_Linux_amd64.tar.gz
tar -xzvf k9s_Linux_amd64.tar.gz
mv k9s /usr/bin/k9s
echo "##################################################################################################################################################################"



echo "installing open-ssh & net-tools"
sudo sudo apt install -y openssh-server net-tools 
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



echo "Define Config file for kind cluster && k3d"
sudo cat <<EOF > /home/dheeraj/kind.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF


sudo cat <<EOF > /home/dheeraj/k3d-config.yaml
apiVersion: k3d.io/v1alpha4
kind: Simple
metadata:
  name: multinode
servers: 1
agents: 1
# kubeAPI:
#   hostIP: "172.29.208.142"
#   hostPort: "6445"
ports:
  - port: 8080:80
    nodeFilters:
      - loadbalancer
EOF
sudo cat /home/devops/kind.yaml
sudo cat /home/devops/k3d-config.yaml
echo "##################################################################################################################################################################"


