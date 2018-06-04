#!/usr/bin/sh
set -x

gcloud beta container node-pools create jobs-nodepool \
  --cluster k8s-cluster \
  --machine-type n1-standard-1 \
  --num-nodes 0 \
  --zone europe-west1-b \
  --enable-autoscaling --min-nodes=0 --max-nodes=3 \
  --node-taints dedicated=yorc:NoSchedule \
  --node-labels dedicated=yorc

