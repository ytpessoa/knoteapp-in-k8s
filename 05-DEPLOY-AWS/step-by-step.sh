EKS:
# -AWS runs the Kubernetes control plane for you. That means, AWS runs the master nodes, 
#  and you run the worker nodes.
# -AWS runs three master nodes in three availability zones in your selected region.    
                    region=eu-west-2 
                  /        |         \
            --------------------------------------
                Application Load Balancer (ALB)
            --------------------------------------
            |                |                   |
          ZONA 1          ZONA 2             ZONA 3
     MASTER NODE 1       MASTER NODE 2       MASTER NODE 3
     etcd instance------etcd instance------etcd instance

# we have full control over the worker nodes= ordinary Amazon EC2 instances 


# 1 Create account in the AWS
console.aws.amazon.com 
-> MySecurity Credentials 
-> Access keys (access key ID and secret access key)
-> Create New Access Key
-> Download Key File
# Access Key ID: xxxxxxxxxxxxxxxxx
# Secret Access Key: xxxxxxxxxxxxxxxxxxxxxx

create: ~/.aws/credentials
===================credentials=======================
[default]
aws_access_key_id=xxxxxxxxxxxx
aws_secret_access_key=xxxxxxxxxxxxxxxxxx
======================================================


# 2 Install "eksctl" and awscli

sudo apt  install awscli   # version 1.16.218-1

# 3 Creating a Kubernetes cluster on AWS:

eksctl create cluster --region=eu-west-2 --name=knote
# - 2 worker nodes (this is the default)
# -The worker nodes are m5.large Amazon EC2 instances (this is the default)
# -The cluster is created in the eu-west-2 region (London)
# -The name of the cluster is "knote"

#To create or update the kubeconfig file for your cluster:
aws eks --region eu-west-2 update-kubeconfig --name knote

kubectl get nodes
# NAME                                          STATUS   ROLES    AGE   VERSION
# ip-192-168-22-58.eu-west-2.compute.internal   Ready    <none>   13m   v1.15.11-eks-af3caf
# ip-192-168-87-0.eu-west-2.compute.internal    Ready    <none>   13m   v1.15.11-eks-af3caf

kubectl apply -f knote-and-mongo-YAMLS-k8s/
# deployment.apps/knote created
# service/knote created
# deployment.apps/minio created
# service/minio created
# persistentvolumeclaim/minio-pvc created
# deployment.apps/mongo created
# service/mongo created
# persistentvolumeclaim/mongo-pvc created

#To access the app: "public address" of the "knote Service"
kubectl get services
# NAME         TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)        AGE
# knote        LoadBalancer   10.100.239.164   a912078677f4f496e8932163643e3bca-1506885056.eu-west-2.elb.amazonaws.com   80:30731/TCP   2m16s
# kubernetes   ClusterIP      10.100.0.1       <none>                                                                    443/TCP        31m
# minio        ClusterIP      10.100.222.209   <none>                                                                    9000/TCP       2m12s
# mongo        ClusterIP      10.100.70.133    <none>                                                                    27017/TCP      2m8s

#fully-qualified domain name: a912078677f4f496e8932163643e3bca-1506885056.eu-west-2.elb.amazonaws.com 
web browser: a912078677f4f496e8932163643e3bca-1506885056.eu-west-2.elb.amazonaws.com 

kubectl scale --replicas=10 deployment knote
# deployment.extensions/knote scaled
kubectl get pods
# NAME                     READY   STATUS    RESTARTS   AGE
# knote-65d675d698-5lrkg   1/1     Running   0          22s
# knote-65d675d698-7bw2p   1/1     Running   0          22s
# knote-65d675d698-b8r6t   1/1     Running   0          22s
# knote-65d675d698-cflmb   1/1     Running   0          22s
# knote-65d675d698-f8x6w   1/1     Running   0          8m26s
# knote-65d675d698-hxjpv   1/1     Running   0          22s
# knote-65d675d698-kgrsd   1/1     Running   0          22s
# knote-65d675d698-kznpd   1/1     Running   0          22s
# knote-65d675d698-ntgfv   1/1     Running   0          22s
# knote-65d675d698-p6rrm   1/1     Running   0          22s
# minio-5646646d47-2hmv8   1/1     Running   0          8m23s
# mongo-66796479f-zd5qg    1/1     Running   0          8m19s


# Maximum number of Pods:

kubectl get pods --all-namespaces
# NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
# default       knote-65d675d698-5lrkg     1/1     Running   0          4m
# default       knote-65d675d698-7bw2p     1/1     Running   0          4m
# default       knote-65d675d698-b8r6t     1/1     Running   0          4m
# default       knote-65d675d698-cflmb     1/1     Running   0          4m
# default       knote-65d675d698-f8x6w     1/1     Running   0          12m
# default       knote-65d675d698-hxjpv     1/1     Running   0          4m
# default       knote-65d675d698-kgrsd     1/1     Running   0          4m
# default       knote-65d675d698-kznpd     1/1     Running   0          4m
# default       knote-65d675d698-ntgfv     1/1     Running   0          4m
# default       knote-65d675d698-p6rrm     1/1     Running   0          4m
# default       minio-5646646d47-2hmv8     1/1     Running   0          12m
# default       mongo-66796479f-zd5qg      1/1     Running   0          11m
# kube-system   aws-node-btf9l             1/1     Running   0          33m
# kube-system   aws-node-v7wth             1/1     Running   0          33m
# kube-system   coredns-576d9b7d78-9lrd5   1/1     Running   0          40m
# kube-system   coredns-576d9b7d78-j7lqj   1/1     Running   0          40m
# kube-system   kube-proxy-8klvd           1/1     Running   0          33m
# kube-system   kube-proxy-vbhp7           1/1     Running   0          33m

#Kubernetes runs some system Pods on your worker nodes in the kube-system namespace. 
#These Pods count against the limit too.

# The m5.large instance type that you are using for your worker nodes can host up to 29 Pods.

#Let's exceed this limit on purpose to observe what happens:
kubectl scale --replicas=60 deployment/knote
#deployment.extensions/knote scaled

kubectl get pods \
  -l app=knote \
  --field-selector='status.phase=Running' \
  --no-headers | wc -l
# 50

kubectl get pods \
  -l app=knote \
  --field-selector='status.phase=Pending' \
  --no-headers | wc -l
# 10

#total:
kubectl get pods \
  --all-namespaces \
  --field-selector='status.phase=Running' \
  --no-headers | wc -l
# 58

# To fix:
kubectl scale --replicas=50 deployment/knote

kubectl get pods \
  -l app=knote \
  --field-selector='status.phase=Pending' \
  --no-headers | wc -l
# 0


Price:
# m5.24xlarge EC2 instances for your worker nodes and have 737 Pods on each of them.
# Running the cluster alone (without the worker nodes) costs USD 0.20 per hour.
# And running the two m5.large worker node costs USD 0.096 per hour for each one.
# The total amount is around USD 0.40 per hour for running your cluster.
#The price stays the same, no matter how many Pods you run on the cluster.

# Cleaning up:
eksctl delete cluster --region=eu-west-2 --name=knote