#!/bin/bash

sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

sudo yum install wget unzip google-cloud-sdk -y

# docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# minikube
sudo curl -L https://storage.googleapis.com/minikube/releases/v1.0.0/minikube-linux-amd64 -o /usr/local/bin/minikube
sudo chmod +x /usr/local/bin/minikube

# kubectl
sudo curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

# kubesec
sudo curl -sSL https://github.com/shyiko/kubesec/releases/download/0.9.2/kubesec-0.9.2-linux-amd64 -o kubesec && sudo chmod a+x kubesec && sudo mv kubesec /usr/local/bin/  

# stern
sudo curl -L https://github.com/wercker/stern/releases/download/1.10.0/stern_linux_amd64 -o /usr/local/bin/stern
sudo chmod +x /usr/local/bin/stern

# kube-prompt
sudo wget https://github.com/c-bata/kube-prompt/releases/download/v1.0.6/kube-prompt_v1.0.6_linux_amd64.zip
sudo nzip kube-prompt_v1.0.6_linux_amd64.zip
sudo chmod +x kube-prompt
sudo mv ./kube-prompt /usr/local/bin/kube-prompt
sudo rm -f kube-prompt_v1.0.6_linux_amd64.zip


# install helm (optional)
# sudo yum install -y socat
# sudo curl -sL https://storage.googleapis.com/kubernetes-helm/helm-v2.14.0-linux-amd64.tar.gz -o /tmp/helm/helm.tar.gz
# sudo tar -xvf /tmp/helm/helm.tar.gz -C /tmp/helm
# sudo mv /tmp/helm/linux-amd64/helm /usr/local/bin/
# sudo chmod 755 /usr/local/bin/helm 
# sudo kubectl -n kube-system create serviceaccount tiller
# sudo kubectl create --save-config clusterrolebinding tiller --clusterrole=cluster-admin --user="system:serviceaccount:kube-system:tiller"
# sudo kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin  --user=$(gcloud config get-value core/account)
# sudo helm init --service-account tiller
# sudo helm init --upgrade

# install cert-manger (optional)
# sudo kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# sudo kubectl create namespace cert-manager
# sudo kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
# sudo helm repo add jetstack https://charts.jetstack.io
# sudo helm repo update
# sudo helm install --name cert-manager --namespace cert-manager --version v0.8.0-beta.0 jetstack/cert-manager


sudo mkdir -p /root/.kube
sudo touch /root/.kube/config

sudo mkdir /root/.docker
sudo touch /root/.docker/config.json
sudo echo {} > /root/.docker/config.json

sudo cat >> /root/.bashrc << EOF
alias p=kube-prompt
alias k=kubectl
alias kd="kubectl describe"
alias kgpy="kubectl get pods -o yaml"
alias ka="kubectl apply -f"
alias klo="kubectl logs -f"
alias kex="kubectl exec -it"
alias dils="docker image ls"
alias dcls="docker container ls -a --format \"table {{.ID}}\t{{.Names}}\t{{.Status}}\""
alias dcrm="docker container rm $(docker container ps -a -f status=exited -q)"
complete -o default -F __start_kubectl k
source <(kubectl completion bash)
source <(kubesec completion bash)
source <(helm completion bash)
EOF

sudo cat > /root/.bash_profile << EOF
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


# docker container run --rm -d -it --name nginx -v /home/docker/html:/usr/share/nginx/html -p 8080:80 nginx:latest
# docker run -d -p 5000:5000 -v ~/.dockerregistry:/var/lib/docker/registry --restart always --name registry registry:2
