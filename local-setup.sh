#!/bin/bash

set -x #debug mode
set -e #exit the script when there is an error
set -o pipefail

# echo "Enable Systemd "
# sudo cat <<EOF > /etc/wsl.conf
# [boot]
# systemd=true
# EOF
# echo "###################################################################################################################################################################"


echo "Updating the Repos && install tools"
sudo apt update && sudo apt upgrade -y
sudo apt-add-repository ppa:fish-shell/release-3
sudo apt install -y fish zip unzip tree 


echo "###################################################################################################################################################################"




echo "Install docker, docker-compose && add user to docker group"
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin  
sudo usermod -a -G docker dheeraj
echo "##################################################################################################################################################################"




echo "Install kubectx,kubens"
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

echo "###################################################################################################################################################################"



echo "Install Kind to create k8 cluster"
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
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
wget https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz
tar -xzvf k9s_Linux_amd64.tar.gz
mv k9s /usr/bin/k9s
echo "##################################################################################################################################################################"



echo "installing open-ssh & net-tools"
sudo sudo apt install -y openssh-server net-tools 
sudo ufw allow ssh
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
rm -rf *
sudo cat <<EOF > /home/dheeraj/kind-setup.sh
#!/bin/bash

nt=$(docker network inspect -f '{{.IPAM.Config}}' kind | awk '{print $1}' | awk -F'.' '{print $2}')

IMAGE="kindest/node:v1.27.3@sha256:3966ac761ae0136263ffdb6cfd4db23ef8a83cba8a463690e98317add2c9ba72 "

apiServerAddress="172.29.246.13"
apiServerPort="6443"

read -p "Enter the value(ing/lb):" VAR

if [ "$VAR" == "ing" ]
then

echo "create kind cluster with ingress-nginx"

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
#networking:
  #apiServerAddress: "$apiServerAddress"
  #apiServerPort: $apiServerPort
nodes:
- role: control-plane
  image: $IMAGE
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
  - containerPort: 30080
    hostPort: 30080
  - containerPort: 30081
    hostPort: 30081
  - containerPort: 30000
    hostPort: 30000
EOF


sleep 5

echo "install nginx-ingress"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=30s

elif [ "$VAR" == "lb" ]
then 

echo "creating kind cluster with metal-lb"

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
#networking:
  #apiServerAddress: "$apiServerAddress"
  #apiServerPort: $apiServerPort
nodes:
- role: control-plane
  image: $IMAGE
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
EOF


echo "sleep 5 sec"

sleep 5

echo " instal metallb loadbalancer"

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml


echo "Wait for metallb to initialize"

kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=app=metallb \
                --timeout=90s

echo "sleep 5 sec"
sleep 5

echo "Setup address pool used by loadbalancers"

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: example
  namespace: metallb-system
spec:
  addresses:
  - 172.$nt.255.200-172.$nt.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
EOF


echo "success"

else
  echo "invalid arguemnt"
fi
EOF


sudo cat <<EOF > /home/dheeraj/k3d-config.yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
servers: 1
#agents: 1
#kubeAPI:
  #hostIP: "172.29.246.13"
  #hostPort: "6445"
ports:
  - port: 80:80
    nodeFilters:
      - loadbalancer
  - port: 30080:30080
    nodeFilters:
      - server:*
  - port: 30081:30081
    nodeFilters:
      - server:*
  - port: 30000:30000
    nodeFilters:
      - server:*
EOF
sudo chown dheeraj:dheeraj kind-setup.sh
sudo chown dheeraj:dheeraj k3d-config.yaml
sudo cp /home/dheeraj/kind-setup.sh /root
sudo cp /home/dheeraj/k3d-config.yaml /root
echo "##################################################################################################################################################################"


