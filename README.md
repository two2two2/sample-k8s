# Set up on Virtual Machine
## start vm 
```
$ vagrant up
$ vagrant ssh
$ sudo su -
```

## kubernetes(minikube) get started
```
# minikube start --vm-driver=none --extra-config=kubeadm.ignore-preflight-errors=SystemVerification

// gcpのレジストリの認証設定
# gcloud auth login
# gcloud auth configure-docker

# docker imageをビルドかpullで取ってくる

# kubectl apply -f k8s/minikube/config.yaml
# kubectl apply -f k8s/minikube/db-volume.yaml
# kubectl apply -f k8s/minikube/db.yaml

# kubectl exec -it [dbpod] -- mysql -uroot -ppassword -e"GRANT ALL PRIVILEGES ON *.* TO  'sample_user'@'%'; FLUSH PRIVILEGES;"

# minikube addons enable ingress
# minikube addons enable metrics-server

# kubectl apply -f k8s/minikube/
```

### deprecated
```
# minikube start --vm-driver=none

// エラーになったら
# sudo kubeadm reset -f && sudo /usr/bin/kubeadm init --config /var/lib/kubeadm.yaml --ignore-preflight-errors=DirAvailable--etc-kubernetes-manifests --ignore-preflight-errors=DirAvailable--data-minikube --ignore-preflight-errors=Port-10250 --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-kube-scheduler.yaml --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-kube-apiserver.yaml --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-kube-controller-manager.yaml --ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-etcd.yaml --ignore-preflight-errors=Swap --ignore-preflight-errors=CRI

// エラー後にもminikube 起動できない場合は
# minikube delete
```

## helm & cert-manager
```
# kubectl -n kube-system create serviceaccount tiller
# kubectl create --save-config clusterrolebinding tiller --clusterrole=cluster-admin --user="system:serviceaccount:kube-system:tiller"
# helm init --service-account tiller
# helm init --upgrade

# install cert-manger (optional)
# kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# kubectl create namespace cert-manager
# kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
# helm repo add jetstack https://charts.jetstack.io
# helm repo update
# helm install --name cert-manager --namespace cert-manager --version v0.8.0-beta.0 jetstack/cert-manager
```


# Set up on GKE (on cloud shell)
## GKE secrets Google KMS
最初の反映は考えないといけない。
```
# gcloud auth application-default login
# gcloud kms keyrings create secret-test --location global
# gcloud kms keys create secret-test-key --location global --keyring secret-test --purpose encrypt
# gcloud kms keys list --location global --keyring secret-test
# gcloud kms keys list --location global --keyring secret-test
projects/testing-190408-237002/locations/global/keyRings/secret-test/cryptoKeys/secret-test-key


// edit
# kubesec decrypt -i secret.yml
# gcloud kms keys update projects/testing-190408-237002/locations/global/keyRings/secret-test/cryptoKeys/secret-test-key --primary-version=1 --location global --keyring secret-test


// gcloud KMSのコンソールでローテーションを回す。 
# kubesec encrypt -i --key=gcp:projects/testing-190408-237002/locations/global/keyRings/secret-test/cryptoKeys/secret-test-key ./k8s/cloudsql/secret.yaml
# kubesec decrypt k8s/cloudsql/secret.yml | kubectl apply -f -
``` 

## GKE deploy
```
// クラスタの作成
$ gcloud beta container --project "testing-190408-237002" clusters create "rails-puma-gke-sample" --zone "asia-northeast1-a" --username "admin" --cluster-version "1.11.8-gke.6" --machine-type "custom-1-2048" --image-type "COS" --disk-type "pd-standard" --disk-size "10" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --enable-cloud-logging --enable-cloud-monitoring --no-enable-ip-alias --network "projects/testing-190408-237002/global/networks/default" --subnetwork "projects/testing-190408-237002/regions/asia-northeast1/subnetworks/default" --enable-autoscaling --min-nodes "1" --max-nodes "5" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair


// GCPのクラスタとkubectlを紐付ける
$ gcloud container clusters get-credentials [cluster name] --zone [zonename]
gcloud container clusters get-credentials rails-puma-gke-sample --zone asia-northeast1-a


// 最初の一回だけcircle ciに入れる。 ifであったら回避みたいなのしたい。
# kubectl create secret generic cloudsql-instance-credentials --from-file=credentials.json=${HOME}/account-auth.json


// ここで一度circle ciを回す。


// ingressを反映。(circle ciに入れてもOK) 基本は一回だけしか使わないはず。
# kubectl apply -f ingress.yaml
```


## helm GKE Let's Encrypt[WIP]
```
// helm install (on cloud shell)
# cd /tmp
# wget https://storage.googleapis.com/kubernetes-helm/helm-v2.14.0-linux-amd64.tar.gz
# tar xvzf helm-v2.13.1-linux-amd64.tar.gz
# sudo mv linux-amd64/helm /usr/local/bin/helm
# sudo chmod +x /usr/local/bin/helm
# rm -r ./helm-v2.13.1-linux-amd64.tar.gz linux-amd64/
# source <(helm completion bash)


// serviceaccountの作成
# kubectl create serviceaccount -n kube-system tiller


// tillerを動作させるアカウントに権限付与
#  kubectl create --save-config clusterrolebinding tiller --clusterrole=cluster-admin --user="system:serviceaccount:kube-system:tiller"


// helmクライアントの初期化とtillerのデプロイ（セキュリティ的に甘いらしい）
# sudo helm init --service-account tiller  → エラーでたら以下
# kubectl delete svc tiller-deploy -n kube-system
# kubectl -n kube-system delete deploy tiller-deploy
# kubectl create serviceaccount --namespace kube-system tiller
# kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
# helm init --service-account tiller


// エラーでなかったら以下。
# sudo helm init --service-account default

$HELM_HOME has been configured at /home/hogehoge/.helm.
Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.
Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation


# helm repo update


// cert-managerのインストール
# kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
# kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.7/deploy/manifests/00-crds.yaml
# kubectl create namespace cert-manager
# kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
# helm install --name cert-manager --namespace cert-manager --version v0.7.2 jetstack/cert-manager


# kubectl apply -f cert-manager.yaml -n kube-system

// 少し時間かかる
# kubectl get cert
# kubectl describe cert

// ingressのspec.tlsの設定を解除して
# kubectl apply -f ingress.yaml

# openssl s_client -connect [domain]:443
# kubectl get certificate -o jsonpath="{.items..status.notAfter}\n"
```

# for Development
## docker-compose
```
# docker-compose build

# docker-compose up -d

# docker-compose exec db  mysql -uroot -ppassword -e"GRANT ALL PRIVILEGES ON *.* TO 'sample_user'@'%'; FLUSH PRIVILEGES;"

# docker-compose exec app rails db:create
# docker-compose exec app rails db:migrate
```


# commands

## docker
```
# docker container ls -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```

## gcloud
If you want to use `gcloud`, put `gcloud init` on your console.
```
# gcloud auth configure-docker
# gcloud auth login
# gcloud config set project testing-190408-237002
# docker tag [IMAGE] asia.gcr.io/[PROJECT_ID]/[IMAGE]
# docker tag docker_app:latest asia.gcr.io/testing-190408-237002/rails_puma_gke_sample_web:v0.1
# docker push asia.gcr.io/[PROJECT_ID]/[IMAGE]
# docker push asia.gcr.io/testing-190408-237002/rails_puma_gke_sample_web
```

## useful command
exitedになったコンテナを削除
`# docker container rm $(docker container ps -a -f status=exited -q)`

railsで特定のファイルの変更
`# docker image build -t [IMAGE_NAME]:[new_tag] .`


### kubernetes
```
# kubectl apply -f k8s/ --prune --all
# kubectl get deployment,svc,pods,pvc
# kubectl get all
# kubectl get pods [pod name] -o jsonpath="{.metadata.name}"

# minikube service list

// minikubeのtype:LoadBalancerを使ったときのIPの確認
# minikube service sample-lb --url
http://10.0.2.15:30080

// podのログ
# stern "web-\w"

// 複数コンテナあるときのexex
# kubectl exec -it web_pod -c rails /bin/bash

// 引数のあるexec
# kubectl exec -it db -- mysql -uroot -ppassword

// 強制削除
# kubectl delete pods [podname] --grace-period=0 --force

// Delete Evectid Pods
# kubectl get po --all-namespaces --field-selector 'status.phase!=Running' -o json | kubectl delete -f -


// ingress debuging
# kubectl get pods -n kube-system | grep nginx-ingress-controller
# kubectl describe pods -n kube-system nginx-ingress-controller-...
# kubectl describe pods -n kube-system $(kubectl get pods -n kube-system -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep nginx-ingress-controller)
```

## helm
```
# kubectl get pods --namespace cert-manager

```



