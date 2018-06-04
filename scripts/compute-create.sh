#!/usr/bin/sh
set -x
gcloud compute instances create myinstance \
    --image-family centos-7 \
    --image-project centos-cloud \
    --machine-type n1-standard-1 \
    --zone europe-west1-b \
    --preemptible
