# Kubernetes Engine

[Kubernetes Engine](https://cloud.google.com/kubernetes-engine) allows to deploy a Kubernetes cluster in one command.

Create a Kubernetes cluster with 3 worker nodes (default) :
```
gcloud container clusters create k8s-cluster --cluster-version 1.10.2-gke.3 --num-nodes 3
```

Reference: [gcloud container cluster create](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)

The worker nodes are created automatically by Kubernetes Engine using another Google Service, Compute Engine,
and follows Google Compute Engine pricing policy until the node is deleted.

These worker nodes can be seen using Compute Engine CLI:
```
gcloud compute instances list
```

This command won't show any node created for the Kubernetes master node. The master node is managed by Kubernetes Engine, not be the user, and the user won't pay for it.

Now that the cluster is created, to interact with it using kubectl, get cluster credentials running this command, that will create/update a $HOME/.kube/config file with required settings :
```
gcloud container clusters get-credentials k8s-cluster
```

You can now use kubectl to interact with your cluster:
```
kubectl get nodes
kubectl get pods --all-namespaces
```

## Node Pools

Nodes created above are added in a default node pool.
You can add other [node pools](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools) to the cluster. All nodes in a node pool have the same type, which can differ from the type of nodes in the default pool.

Autoscaling can be enabled on a node pool, so that it is automatically resized based on workloads.
You can define as well node taints (beta version) to mark nodes so that the scheduler will avoid or prevent using them, except for workloads declaring explicitly that they tolerate this taint.

In addition, you can require that a workload will be executed on nodes in a given pool, specifying node labels at the node pool level, and adding a node selector in your workload description to ask this workload to be scheduled on a node of this Pool.

For example, the following command will create a nodes pool dedicated to the orchestrator Kubernetes workloads.
This Pool will have initially no node, and will autoscale up to 3 nodes when the orchestrator execute Kubernetes workloads with specific requirements :

```
gcloud beta container node-pools create jobs-nodepool \
  --cluster k8s-cluster \
  --machine-type n1-standard-1 \
  --num-nodes 0 \                                          <- Initially, 0 node in the Pool
  --zone europe-west1-b \
  --enable-autoscaling --min-nodes=0 --max-nodes=3 \       <- min 0, max 3
  --node-taints dedicated=yorc:NoSchedule \                <- scheduler shoud not use nodes, expect for workloads tolerating this taint
  --node-labels dedicated=yorc                             <- label that should be referenced by workloads to be scheduled on this Pool
```

A  Kubernetes workload would be scheduled on a node of this pool if the Kubernetes specification of this workload contains the following tolerations (for node taints) and nodeSelector (for node labels) :
```
spec:
  template:
    spec:
      tolerations:
      - key: dedicated
        operator: Equal
        value: yorc
        effect: NoSchedule
      nodeSelector:
        dedicated: yorc
```

## Jobs

Creating a [Kubernetes job](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/) (here a perl container with a command computing PI to 9 decimals), with in its specification, tolerations and nodeSelector to be scheduled on the node pool jobs-nodepool described above.

Using file [scripts/jobPI.yml](../scripts/jobPI.yml), create the job:
```
kubectl create -f scripts/jobPI.yml
```

Regularly check its state. Here the following command describes related events showing the job is scheduled on the autoscaling node pool containing no node initially.
So a new node will be created on the fly (adding between 1 and 2 minutes of latency in job execution, the time to create this node) :
```
$ kubectl describe pods
Name:           pi-compute-job-xftvn
Namespace:      default
Node:           gke-k8s-cluster-jobs-nodepool-5018659c-8zlp/10.132.0.3
...
Conditions:
...
Node-Selectors:  dedicated=yorc
Tolerations:     dedicated=yorc:NoSchedule
node.kubernetes.io/not-ready:NoExecute for 300s
node.kubernetes.io/unreachable:NoExecute for 300s
...
Events:
 
  Type     Reason                 Age              From                                                  Message
  ----     ------                 ----             ----                                                  -------
  Normal   TriggeredScaleUp       3m               cluster-autoscaler                                    pod triggered scale-up: [{https://content.googleapis.com/compute/v1/projects/xxx/zones/europe-west1-b/instanceGroups/gke-k8s-cluster-jobs-nodepool-5018659c-grp 0->1 (max: 3)}]
  Warning  FailedScheduling       2m (x7 over 3m)  default-scheduler                                     0/1 nodes are available: 1 node(s) didn't match node selector.
  Normal   Scheduled              2m               default-scheduler                                     Successfully assigned pi-compute-job-xftvn to gke-k8s-cluster-jobs-nodepool-5018659c-8zlp
  Normal   SuccessfulMountVolume  2m               kubelet, gke-k8s-cluster-jobs-nodepool-5018659c-8zlp  MountVolume.SetUp succeeded for volume "default-token-9qwp7"
  Normal   Pulling                2m               kubelet, gke-k8s-cluster-jobs-nodepool-5018659c-8zlp  pulling image "perl"
  Normal   Pulled                 52s              kubelet, gke-k8s-cluster-jobs-nodepool-5018659c-8zlp  Successfully pulled image "perl"
  Normal   Created                52s              kubelet, gke-k8s-cluster-jobs-nodepool-5018659c-8zlp  Created container
  Normal   Started                52s              kubelet, gke-k8s-cluster-jobs-nodepool-5018659c-8zlp  Started container
```


Check pod status (```--show-all``` allows to show completed jobs) :
```
$ kubectl get pods --show-all
NAME                   READY     STATUS      RESTARTS   AGE
pi-compute-job-c26ts   0/1       Completed   0          3m
```


Get pod logs (here, it compute PI to the 9th decimal) :
```
kubectl logs pi-compute-job-c26ts
3.141592654
```

WARNING: with the autoscaling, after 10 minutes without any workload, the node that was created to execute our job will be automatically deleted, and the corresponding pod as well. So the pod logs displayed above are not accessible forever.

## CronJob

A [Kubernetes CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) is a time-base job executed at a specified time, or periodically on a given schedule written in [Cron](https://en.wikipedia.org/wiki/Cron) format.

Using file [scripts/cronJobDate.yml](../scripts/cronJobDate.yml), using a busybox container image with a command printing the date, defining as a CronJob executed every 2 minutes, create the cron job :
```
kubectl apply -f scripts/cronJobDate.yml
```

After several minutes, check the job was executed on schedule, except for the first job, because we are executing this job on a node pool with an initial size of 0, so the first schedule will trigger the creation of a node in the pool):
```
$ kubectl get pods --show-all
NAME                                  READY     STATUS      RESTARTS   AGE
print-date-cronjob-1527521280-fzjkk   0/1       Completed   0          6m
print-date-cronjob-1527521400-5xs46   0/1       Completed   0          4m
print-date-cronjob-1527521520-8lxk4   0/1       Completed   0          2m
print-date-cronjob-1527521640-rbpr9   0/1       Completed   0          38s
 
kubectl logs print-date-cronjob-1527521280-fzjkk
Mon May 28 15:30:07 UTC 2018
kubectl logs print-date-cronjob-1527521400-5xs46
Mon May 28 15:30:05 UTC 2018
kubectl logs print-date-cronjob-1527521520-8lxk4
Mon May 28 15:32:04 UTC 2018
kubectl logs print-date-cronjob-1527521640-rbpr9
Mon May 28 15:34:05 UTC 2018
```

Delete the job :
```
kubectl delete -f scripts/cronJobDate.yml
```

Delete the cluster

```
gcloud container clusters delete k8s-cluster
```

## Exposing applications to external traffic

Exposing a Kubernetes services of type [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) allows to have a given port number reserved on all nodes in the cluster for this service, and any traffic sent to this port is forwarded to the Service.
An external client using the external IP address of a node in the cluster and this port is then able to use he service.

In a cloud provider context, other ways of exposing services to external traffic should be supported :
  * Service of type [LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/service/#type-loadbalancer): Kubernetes Engine will automatically create a TCP load balancer and allocate an external IP address
  * Create a Kubernetes resource [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) describing rules and configuration for routing external traffic to internal service. This is the recommended way to expose HTTP(S) services. Kubernetes Engine will automatically create a HTTP load balancer, and configure health checks as well.

Following the example described at https://cloud.google.com/kubernetes-engine/docs/tutorials/http-balancer,

Deploy a web application:
```
kubectl run web --image=gcr.io/google-samples/hello-app:1.0 --port=8081
```

Expose your Deployment as a Service using the type ```NodePort```, that will reserve
a port number on all nodes in the cluster, any traffic sent to this port on any node will be forwarded to the service.

While,
 * ```port``` used above is the abstracted service port, which can be any port other pods use to access the Service
  * ```targetPort``` used below is the port the container accepts traffic on (can be a string)
 ```
kubectl expose deployment web --target-port=8080 --type=NodePort
```

Check a service was created and a NodePort was allocated :
```
$ kubectl get service web
NAME      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
web       NodePort   10.63.241.162   <none>        8081:32331/TCP   48s
```

Using file [scripts/webapp-ingress.yml](../scripts/webapp-ingress.yml), create an ingress resource running :
```
kubectl apply -f scripts/webapp-ingress.yml
```
Check the resource created :
```
$ kubectl get ingress webapp-ingress
NAME             HOSTS     ADDRESS         PORTS     AGE
webapp-ingress   *         35.190.32.237   80        1m
```

The external IP address of the service is provided here. It will take some time for Kubernetes Engine to provision the load balancer and set forwarding rules. While it is not ready, an attempt to access this IP address at port 80 will return an HTTP error 404 or 500.

In the meantime, here are some commands to check port and target port on a deployed application.
Get the pod:
```
$ kubectl get pods
NAME                   READY     STATUS    RESTARTS   AGE
web-5786867cfc-qcl5x   1/1       Running   0          2m
```

Get a shell to the running Container and run a command to see the target port:
```
$ kubectl exec -it web-5786867cfc-qcl5x -- /bin/sh

/ # netstat -an
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 :::8080                 :::*                    LISTEN
```

Exit form the shell and get pod details to find the port:
```
$ kubectl describe pod web-5786867cfc-qcl5x
Name:           web-5786867cfc-qcl5x
Namespace:      default
Node:           gke-k8s-cluster-default-pool-cdd9e7b5-0h88/10.132.0.2
Start Time:     Tue, 05 Jun 2018 10:32:15 +0200
Labels:         pod-template-hash=1342423797
                run=web
Annotations:    kubernetes.io/limit-ranger=LimitRanger plugin set: cpu request for container web
Status:         Running
IP:             10.60.0.13
Controlled By:  ReplicaSet/web-5786867cfc
Containers:
  web:
    Container ID:   docker://8d9071782393bf383ff3ab6e924f2b228b43d0204dbd860a8069dcb7b6db777f
    Image:          gcr.io/google-samples/hello-app:1.0
    Image ID:       docker-pullable://gcr.io/google-samples/hello-app@sha256:c62ead5b8c15c231f9e786250b07909daf6c266d0fcddd93fea882eb722c3be4
    Port:           8081/TCP
    State:          Running
      Started:      Tue, 05 Jun 2018 10:32:17 +0200
    Ready:          True
    Restart Count:  0
    Requests:
      cpu:        100m
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-ngzzc (ro)
```

## Cleanup

Delete the load balancing resources:
```
kubectl delete ingress webapp-ingress
```
Delete the cluster:
```
gcloud container clusters delete k8s-cluster
```

Next: [Cloud Machine Learning](cloud-ml-engine.md)

