#1) Criar arquivo DockerFile na raiz da Aplicação

#2) Criando o conteiner:

$ sudo docker build -t knote .

    # "-t"   : tag 
    # "knote": name
    # "."    : current    
    # output : Docker image

$ sudo docker images
    # knote          

# 3) Criar rede de container para knote e mongo

$ docker network create knote

# Executation Server mongoDB:
$ sudo docker run --name=mongo --rm --network=knote  mongo


# Executation your application:
$ sudo docker images
   # knote          

$ sudo docker run \
  --name=knote \
  --rm \
  --network=knote \
  -p 3000:3000 \
  -e MONGO_URL=mongodb://mongo:27017/dev \
  knote


$ sudo docker ps
    # knote        "node index.js"          
    # mongo        "docker-entrypoint.s…"   

# Finalizando:
$ sudo docker stop mongo knote
$ sudo docker rm mongo knote 

$ sudo docker login
$ sudo docker images
    # knote           

# Renomear sua imagem:
$ sudo docker tag knote dockerID/image:tag
$ sudo docker tag knote ytpessoa/knote-js:1.0.0  

# Subir pra hub.docker:
$ sudo docker push ytpessoa/knote-js:1.0.0  

#https://hub.docker.com/
    # conteiner: ytpessoa/knote-js:1.0.0


#############################
#   Resumo de Execução      #
#############################

# 1) Criar a rede de container "knote-net":

$ sudo docker network create knote-net
$ sudo docker network list
    # knote-net  

# 2) Conteiner Server MongoDB

sudo docker run \
  --name=mongo \
  --rm \
  --network=knote-net \
  mongo

# 3) Conteiner da sua aplicação no "hub.docker.com" :

sudo docker run \
  --name=knote \
  --rm \
  --network=knote-net \
  -p 3000:3000 \
  -e MONGO_URL=mongodb://mongo:27017/dev \
   ytpessoa/knote-js:1.0.0

$ sudo docker ps
# IMAGE                     COMMAND                  PORTS                    NAMES
# ytpessoa/knote-js:1.0.0   "node index.js"          0.0.0.0:3000->3000/tcp   knote
# mongo                     "docker-entrypoint.s…"   27017/tcp                mongo

# Finalizando:
$ sudo docker stop mongo knote
$ sudo docker network rm knote-net

