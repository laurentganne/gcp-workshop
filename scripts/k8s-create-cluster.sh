#!/usr/bin/sh
set -x

gcloud container clusters create k8s-cluster --cluster-version 1.10.2-gke.3 --num-nodes 3
