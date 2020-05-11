cd 04-SCALING/
# 04-SCALING
# ├── knote-and-mongo-YAMLS-k8s
# │   ├── knoteApp-Deployment.yaml
# │   ├── knoteApp-Service.yaml
# │   ├── mongoApp-Deployment.yaml
# │   ├── mongoApp-Service.yaml
# │   └── mongoApp-Volume.yaml
# └── step-by-step.sh

# 1 Apply in the manifets
kubectl apply -f knote-and-mongo-YAMLS-k8s/
kubectl get pods
# NAME                     READY   STATUS    RESTARTS   AGE
# knote-7486947dbf-s7l84   1/1     Running   1          2d11h
# mongo-79696fcf9f-mqkmj   1/1     Running   1          2d11h

kubectl get deployments
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE
# knote   1/1     1            1           2d11h
# mongo   1/1     1            1           2d11h

kubectl scale --replicas=2 deployment/knote
# deployment.apps/knote scaled

# two replicas
kubectl get pods -l app=knote --watch
# NAME                     READY   STATUS    RESTARTS   AGE
# knote-7486947dbf-s7l84   1/1     Running   1          2d11h
# knote-7486947dbf-z2hc9   1/1     Running   0          60s



# Virtualizaion scheme :
host$ ifconfig
    # host(vboxnet0)    -->   192.168.99.1 
    # node minikube VM  -->   192.168.99.110

    |--------------| 
    |              | 
local net          | 
    |              |
    |              |- wlp2s0:192.168.0.107 
    --------------"host"
    |              |- vboxnet0: 192.168.99.1               
virtual net        |    
    |              |- 192.168.99.110
    |            "minikube cluster(VM)"
    |--------------|


# Reaccess your app:
    minikube service knote
    # |-----------|-------|-------------|-----------------------------|
    # | NAMESPACE | NAME  | TARGET PORT |             URL             |
    # |-----------|-------|-------------|-----------------------------|
    # | default   | knote |             | http://192.168.99.110:30424 |
    # |-----------|-------|-------------|-----------------------------|
    # 🎉  Opening service default/knote in default browser...
    
    # And create a note with a picture:
    |---------------"host"--------------------------
    |                 |- vboxnet0: 192.168.99.1               
virtual net           |    
    |                 |- 192.168.99.110
    ------------"minikube cluster(VM)"-----------------
    |                 |
k8s net           knote Service - 192.168.99.110:30424 
    |               /    \
    | knote pod1(c1)      knote pod2(c2)
    |(local filesystem)   (local filesystem)     # application is stateful!!!
    |     (image)            (no image)      
    |-----------------------------------------------
    
    # The picture that you added to your note is not displayed on every second reload,(F5).
    
    #To be scalable, applications must be stateless!!!

$ kubectl delete -f knote-and-mongo-YAMLS-k8s/
# deployment.apps "knote" deleted
# service "knote" deleted
# deployment.apps "mongo" deleted
# service "mongo" deleted
# persistentvolumeclaim "mongo-pvc" deleted


# 2 Refactor your app to make it stateless:
   # deploy an "object storage service" yourself: 
   # MinIO is an open-source object storage service that can be installed on your infrastructure.

#2.1 Install MinIO SDK for JavaScript
cd APPLICATION-REFACTORED/
npm install minio 

#2.2 Refactor the  app: APPLICATION-REFACTORED/index.js

#2.3Testing the app locally:                    
                    MongoDB(Docker container)
                    /
APP--> dependencies
                    \ 
                    MinIO (Docker container)

#you must run its dependencies too.

#Run minio/minio on Docker Hub:
sudo docker run \
  --name=minio \
  --rm \
  -p 9000:9000 \
  -e MINIO_ACCESS_KEY=123 \
  -e MINIO_SECRET_KEY=12345678 \
  minio/minio server /data
# -p: expose a container port to the local machine 

    # Endpoint:  http://172.17.0.2:9000  
    #            http://127.0.0.1:9000

    # Browser Access:
    #    http://172.17.0.2:9000  
    #    http://127.0.0.1:9000

#Run MongoDB:
sudo docker run \
  --name=mongo \
  --rm \
  -p 27017:27017 \
  mongo

#Ports in use:
sudo lsof -i -P -n | grep LISTEN

# start the app :
MINIO_ACCESS_KEY=123 MINIO_SECRET_KEY=12345678 node index.js
# MINIO_ACCESS_KEY and MINIO_SECRET_KEY: application environment variables

sudo lsof -i -P -n | grep LISTEN
# docker-pr  5078            root    4u  IPv6 3513625      0t0  TCP *:9000 (LISTEN)
# docker-pr  8198            root    4u  IPv6 3597779      0t0  TCP *:27017 (LISTEN)
# node       8584          ytallo   38u  IPv6 3598256      0t0  TCP *:3000 (LISTEN)

# App MinIO:   127.0.0.1:9000
# App MongoDB: 127.0.0.1:27017
# Main App :   127.0.0.1:3000

# Create some notes with pictures
# uploaded pictures are saved in the: "MinIO object storage" (rather than on the "local file system)!!!

#terminate your application
ctrl+c
sudo docker stop mongo minio
sudo docker rm mongo minio

# 3 Containerising the app :
ls APPLICATION-REFACTORED/
# Dockerfile  index.js  node_modules  package.json  package-lock.json  public  views
cd APPLICATION-REFACTORED/
sudo docker build -t ytpessoa/knote-js:2.0.0 .
sudo docker push ytpessoa/knote-js:2.0.0

#Verify: https://hub.docker.com/repository/docker/ytpessoa/knote-js


# 4 Run application with all three components as Docker containers:
           
           host
            |
          docker ----------- (runtinme)
            |
        knote-net----------- (container network )
      /     |     \  
 mongo    knote    minio ----(containers)
        (port:3000)    


$ sudo docker network create knote-net
$ sudo docker network list


sudo docker run \
  --name=mongo \
  --rm \
  --network=knote-net \
  mongo


sudo docker run \
  --name=minio \
  --rm \
  --network=knote-net \
  -e MINIO_ACCESS_KEY=123 \
  -e MINIO_SECRET_KEY=12345678 \
  minio/minio server /data

 sudo docker run \
  --name=knote \
  --rm \
  --network=knote-net \
  -p 3000:3000 \
  -e MONGO_URL=mongodb://mongo:27017/dev \
  -e MINIO_ACCESS_KEY=123 \
  -e MINIO_SECRET_KEY=12345678 \
  -e MINIO_HOST=minio \
  ytpessoa/knote-js:2.0.0


sudo docker stop mongo minio knote
sudo docker rm knote minio mongo


# 5 Updating the k8s manifests(YAML resources):
04-SCALING$ tree knote-and-mongo-YAMLS-k8s/
knote-and-mongo-YAMLS-k8s/
├── knoteApp-Deployment.yaml
├── knoteApp-Service.yaml
├── minioApp-Deployment.yaml
├── minioApp-Service.yaml
├── minioApp-Volume.yaml
├── mongoApp-Deployment.yaml
├── mongoApp-Service.yaml
└── mongoApp-Volume.yaml

kubectl get pods
#No resources found in default namespace.

kubectl apply -f knote-and-mongo-YAMLS-k8s/
# deployment.apps/knote created
# service/knote created
# deployment.apps/minio created
# service/minio created
# persistentvolumeclaim/minio-pvc created
# deployment.apps/mongo created
# service/mongo created
# persistentvolumeclaim/mongo-pvc created

kubectl get pods --watch
# NAME                     READY   STATUS              RESTARTS   AGE
# knote-755996748d-x9jmm   0/1     ContainerCreating   0          11s
# minio-6d89c68b9-84dwn    0/1     ContainerCreating   0          11s
# mongo-79696fcf9f-q6pbm   0/1     ContainerCreating   0          11s



# Access your app with:
kubectl get services
#  NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# "knote"      LoadBalancer   10.106.12.50    <pending>     80:32670/TCP   5m1s
# kubernetes   ClusterIP      10.96.0.1       <none>        443/TCP        8m34s
# minio        ClusterIP      10.108.115.90   <none>        9000/TCP       5m1s
# mongo        ClusterIP      10.98.169.119   <none>        27017/TCP      5m1s

minikube service knote

    |---------------"host"--------------------------
    |                 |- vboxnet0: 192.168.99.1               
virtual net           |    
    |                 |- 192.168.99.111($ minikube ip)
    ------------"minikube cluster(VM)"-----------------
    |                 |
k8s net           knote Service(LoadBalancer): 192.168.99.111:32670
    |                 |    
    |             knote Pod 
    |             /         \         
    |      mongo Pod       minio Pod
    |        (text)        (images)
    |-----------------------------------------------

minikube service knote
# |-----------|-------|-------------|-----------------------------|
# | NAMESPACE | NAME  | TARGET PORT |             URL             |
# |-----------|-------|-------------|-----------------------------|
# | default   | knote |             | http://192.168.99.111:32670 |
# |-----------|-------|-------------|-----------------------------|
# 🎉  Opening service default/knote in default browser...


# 6 Scaling the app:
    |---------------"host"--------------------------
    |                 |- vboxnet0: 192.168.99.1               
virtual net           |    
    |                 |- 192.168.99.111($ minikube ip)
    ------------"minikube cluster(VM)"-----------------
    |                 |
k8s net           knote Service(LoadBalancer): 192.168.99.111:32670
    |                 |    
    |             knote Pod (stateless)# -> because it saves the uploaded pictures on a MinIO server instead of the Podss file system.)    
    |             /         \         
    |      mongo Pod       minio Pod
    |        (text)        (images)
    |-----------------------------------------------


kubectl get deployments
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE
# knote   1/1     1            1           47m
# minio   1/1     1            1           47m
# mongo   1/1     1            1           47m

kubectl get pods -l app=knote --watch
# NAME                     READY   STATUS    RESTARTS   AGE
# knote-755996748d-5h84q   1/1     Running   0          2m31s
# knote-755996748d-9ghhc   1/1     Running   0          2m31s
# knote-755996748d-dp8r7   1/1     Running   0          2m31s
# knote-755996748d-htjkw   1/1     Running   0          2m31s
# knote-755996748d-mc6qh   1/1     Running   0          2m31s
# knote-755996748d-q4xk7   1/1     Running   0          2m31s
# knote-755996748d-r9z8k   1/1     Running   0          2m31s
# knote-755996748d-sbppv   1/1     Running   0          2m31s
# knote-755996748d-tf5c9   1/1     Running   0          2m31s
# knote-755996748d-x9jmm   1/1     Running   0          51m

minikube service knote
# |-----------|-------|-------------|-----------------------------|
# | NAMESPACE | NAME  | TARGET PORT |             URL             |
# |-----------|-------|-------------|-----------------------------|
# | default   | knote |             | http://192.168.99.111:32670 |
# |-----------|-------|-------------|-----------------------------|
# 🎉  Opening service default/knote in default browser...


# reload the page a couple of times --> requests to knote Service

    |---------------"host"--------------------------
    |                 |- vboxnet0: 192.168.99.1               
virtual net           |    
    |                 |- 192.168.99.111($ minikube ip)
    ------------"minikube cluster(VM)"-----------------
    |                 |
k8s net           knote Service(LoadBalancer): 192.168.99.111:32670
    |        _________|___________________    
    |       /         |                  |
    | knote Pod1    knote Pod2 ... knote Pod10   #scalable app!!!
    |      |_____________________________|
    |              ____|_____     
    |             /          \         
    |      mongo Pod        minio Pod
    |        (text)         (images)
    |-----------------------------------------------


# Clean Up:
kubectl delete -f knote-and-mongo-YAMLS-k8s/
minikube stop