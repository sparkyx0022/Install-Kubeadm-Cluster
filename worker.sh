#!/bin/sh

sudo apt update
sudo apt install git

### INSTALLATING NETFILTER CONFIG #### 
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
lsmod | grep br_netfilter

### INSTALLATING NETWORK BRIDGE #### 
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

### Apply sysctl params without reboot ####
sudo sysctl --system

### SWAPOFF #### 
sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

### INSTALLATING PACKAGES DOCKER #### 
sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

### ADDING KEYRING ####     
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

### ADDING KEYRING INTO SOURCES LIST #### 
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

### INSTALLATING DOCKER, DOCKER-CLI ####  
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

### CREATING A NEW FILE OF CGROUPDRIVER DOCKER #### 
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

### RESTARTING SERVICES DOCKER/CONTAINERD #### 
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker  

#sudo systemctl status docker
#sudo systemctl status containerd

### UPDATING AND ADDING KEYRING OF K8s #### 
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
mkdir /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list### INSTALLATING K8s #### 

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

exit 1
-----------------------------------------------------------------------------------------------
### MANUALLY STEPS TODO ###

sudo nano /etc/containerd/config.toml
#disabled_plugins = ["cri"]
systemctl restart containerd.service
