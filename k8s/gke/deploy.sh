#!/bin/bash

set -ex

# 前のJobが残っていたらまずは消す
kubectl delete job setup 2&> /dev/null || true
# マイグレート用のJobを作成し、実行します
kubectl create -f ./k8s/gke/patched_job.yaml
# Jobが正常に実行されるまで待ちます
while [ true ]; do
  phase=`kubectl get pods --selector="name=deploy-task" -o 'jsonpath={.items[0].status.phase}' || 'false'`
  if [[ "$phase" != 'Pending' ]]; then
    break
  fi
done

# Jobの終了状態を取得します
while [ true ]; do
  succeeded=`kubectl get jobs setup -o 'jsonpath={.status.succeeded}'`
  failed=`kubectl get jobs setup -o 'jsonpath={.status.failed}'`
  if [[ "$succeeded" == "1" ]]; then
    break
  elif [[ "$failed" -gt "0" ]]; then
    kubectl describe job setup
    kubectl logs $(kubectl get pods --selector="name=deploy-task" --output=jsonpath={.items[0].metadata.name}) setup
    kubectl delete job setup
    echo 'マイグレートに失敗！'
    exit 1
  fi
done
kubectl delete job setup || true
