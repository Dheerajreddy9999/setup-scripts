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
  - containerPort: 31000
    hostPort: 31000
  - containerPort: 32000
  - hostPort: 32000
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