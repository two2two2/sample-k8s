#!/bin/bash

sudo tee /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

sudo yum install wget unzip google-cloud-sdk git apr-util epel-release jq tmux -y

if [ ! -e /root/.kube ]; then  
  echo creating .kube/config.json ...
  sudo mkdir -p /root/.kube /root/.minikube
  sudo touch /root/.kube/config
fi


if [ ! -e /root/.docker ]; then  
  echo creating .docker/config.json ...
  sudo mkdir /root/.docker
  sudo touch /root/.docker/config.json
  sudo echo {} > /root/.docker/config.json
fi


sudo tee -a /root/.bashrc << EOF
alias ls='ls -F --color=auto'
alias la='ls -laF --color=auto'
alias ll='ls -lF --color=auto'
alias ..='cd ..'
alias p=kube-prompt
alias k=kubectl
alias kd="kubectl describe"
alias kgpy="kubectl get pods -o yaml"
alias ka="kubectl apply -f"
alias klo="kubectl logs -f"
alias kex="kubectl exec -it"
alias dils="docker image ls"
alias dcls="docker container ls -a --format \"table {{.ID}}\t{{.Names}}\t{{.Status}}\""
alias dcrm="docker container prune"
alias mkstr="minikube start --vm-driver=none --extra-config=kubeadm.ignore-preflight-errors=SystemVerification"
complete -o default -F __start_kubectl k
source <(kubectl completion bash)
source <(kubesec completion bash)
source <(helm completion bash)
EOF

sudo tee -a /root/.tmux.conf << EOF
set -g prefix C-s
set-window-option -g mode-mouse on
unbind C-b
bind | split-window -h
bind - split-window -v
bind r source-file ~/.tmux.conf \; display "Reloaded!"
set -g alternate-screen on
set -g default-terminal "screen-256color"
set-option -g mouse-select-pane on
set-option -g mouse-resize-pane on
EOF

sudo tee -a /root/.bash_profile << EOF
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs
export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
export KUBECONFIG=$HOME/.kube/config

PATH=$PATH:$HOME/bin:/usr/local/bin

export PATH
EOF


echo downloding docker-compose....
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo downloding minikube.....
sudo curl -L https://storage.googleapis.com/minikube/releases/v1.0.0/minikube-linux-amd64 -o /usr/local/bin/minikube
sudo chmod +x /usr/local/bin/minikube

echo downloding kubectl.....
sudo curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

echo downloding kubesec....
sudo curl -sSL https://github.com/shyiko/kubesec/releases/download/0.9.2/kubesec-0.9.2-linux-amd64 -o kubesec && sudo chmod a+x kubesec && sudo mv kubesec /usr/local/bin/  

echo downloding stern....
sudo curl -L https://github.com/wercker/stern/releases/download/1.10.0/stern_linux_amd64 -o /usr/local/bin/stern
sudo chmod +x /usr/local/bin/stern

echo downloding kube-prompt....
sudo wget https://github.com/c-bata/kube-prompt/releases/download/v1.0.6/kube-prompt_v1.0.6_linux_amd64.zip
sudo unzip kube-prompt_v1.0.6_linux_amd64.zip
sudo chmod +x kube-prompt
sudo mv ./kube-prompt /usr/local/bin/kube-prompt
sudo rm -f kube-prompt_v1.0.6_linux_amd64.zip

echo downloding install helm.....
sudo yum install -y socat
sudo wget https://storage.googleapis.com/kubernetes-helm/helm-v2.14.0-linux-amd64.tar.gz
sudo tar -xzvf helm-v2.14.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm 
sudo rm -f helm-v2.14.0-linux-amd64.tar.gz
sudo rm -rf linux-amd64

echo terraform
sudo wget https://releases.hashicorp.com/terraform/0.12.2/terraform_0.12.2_linux_amd64.zip
sudo unzip terraform_0.12.2_linux_amd64.zip && mv terraform /usr/local/bin/
sudo rm -f terraform_0.12.2_linux_amd64.zip 
