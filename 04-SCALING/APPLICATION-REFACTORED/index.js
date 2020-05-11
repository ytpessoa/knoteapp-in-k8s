//////////////////////////////////////
//  Executando a Aplicação          //
/////////////////////////////////////

//Dependências:
// $ npm install mongodb
// $ npm install express
// $ npm install marked
// $ npm install multer
// views/index.pug
// public/tachyons.min.css

// 1- Inicie um servidor MongoDB:
// $ mongod
// ou
// $ sudo systemctl start mongodb

// 2- Execute seu aplicativo com:
// $ node index.js

// 3-Acessar Aplicativo
// http://localhost: 3000


//////////////////////////////////////
//  Descrição da Aplicação          //
/////////////////////////////////////
// Aplicativo é um aplicativo para anotações:
// -- Código padrão para um aplicativo Express em NodeJs
// -- Express e Pug são duas opções populares quando se trata de servidores
//    da Web e mecanismos de modelagem no Node.js:
//    $ npm install express





//////////////////////////////////////
//          HTML                    //
/////////////////////////////////////
// Marked é um excelente mecanismo para renderizar o Markdown em HTML.
// $ npm install marked
const marked = require('marked') // importando "marked"


const path = require('path')
const express = require('express')

const app = express()
const port = process.env.PORT || 3000

// Multer: middleware para dados de formulário com várias partes, para manipular os dados enviados
//$ npm install multer
const multer = require('multer')


////////////////////////////////////////////////
//  Minio:open-source object storage service  //
///////////////////////////////////////////////
const minio = require('minio')
const minioHost = process.env.MINIO_HOST || 'localhost'
const minioBucket = 'image-storage' //the "folder" where your pictures are saved.

async function initMinIO() {
  // tasks:
  // -connect to the MinIO server;
  // -keep trying to connect to MinIO until it succeeds;
  // -You should gracefully handle the case when the MinIO Pod is started with a delay.

  console.log('Initialising MinIO...')
  const client = new minio.Client({
    endPoint: minioHost,
    port: 9000,
    useSSL: false,
    accessKey: process.env.MINIO_ACCESS_KEY, //environment variables
    secretKey: process.env.MINIO_SECRET_KEY, //environment variables
  })
  let success = false
  while (!success) {
    try {
      if (!(await client.bucketExists(minioBucket))) {
        await client.makeBucket(minioBucket)
      }
      success = true
    } catch {
      await new Promise(resolve => setTimeout(resolve, 1000))
    }
  }
  console.log('MinIO initialised')
  return client
}



//////////////////////////////////////
//  Conectando um banco de dados    //
/////////////////////////////////////
// $ npm install mongodb (client do MongoDB)
const MongoClient = require('mongodb').MongoClient

//URL de busca do seridor MongoDB
const mongoURL = process.env.MONGO_URL || 'mongodb://localhost:27017/dev'

// Busca contínua do servidor MongoDB até a sua disponibilidade
async function initMongo() { 
    console.log('Initialising MongoDB...')
    let success = false
    while (!success) {
      try {
        client = await MongoClient.connect(mongoURL, {
          useNewUrlParser: true,
          useUnifiedTopology: true,
        })
        success = true
      } catch {
        console.log('Error connecting to MongoDB, retrying in 1 second')
        await new Promise(resolve => setTimeout(resolve, 1000))
      }
    }
    
    // Conexão de estabelecida com o servidor MongoDB    
    console.log('MongoDB initialised')
    // cria uma coleção(tabelas em bancos de dados relacionais - listas de itens) "notes":
    return client.db(client.s.options.dbName).collection('notes')
  }


async function start() {
  const db = await initMongo()    //esperando conexão com o servidor MongoDB  
  
  const minio = await initMinIO() // esperando conexão com o servidor Minio  
  
  app.set('view engine', 'pug')
  app.set('views', path.join(__dirname, 'views'))
  app.use(express.static(path.join(__dirname, 'public')))

  app.get('/', async (req, res) => {
    res.render('index', { notes: await retrieveNotes(db) })
  })

    // O formulário é enviado para a rota "/note" , 
    // então você precisa adicionar essa rota ao seu aplicativo:
    app.post(
        '/note',
       
        //salva as imagens carregadas em "public/uploads"(local file system)
        //multer({ dest: path.join(__dirname, 'public/uploads/') }).single('image'),        
        
        //to save the pictures to MinIO  
        multer({ storage: multer.memoryStorage()}).single('image'),
        
        async (req, res) => {
            if (!req.body.upload && req.body.description) 
            {
            await saveNote(db, { description: req.body.description })
            res.redirect('/') //redirecionado para a página principal
            } 
            else if (req.body.upload && req.file) 
            {
                await minio.putObject(
                  minioBucket,
                  req.file.originalname,
                  req.file.buffer
                )
                const link = `/img/${encodeURIComponent(req.file.originalname)}`
                
                // insere um link para o arquivo na caixa de texto
                //const link = `/uploads/${encodeURIComponent(req.file.filename)}`             
                
                res.render('index', {
                  content: `${req.body.description} ![](${link})`,
                  notes: await retrieveNotes(db),
                })
            }
        }
    )//end app.post

    // The pictures are served to the clients via the /img route of your app:
    //-create an additional route:
    app.get('/img/:name', async (req, res) => {
      //The /img route retrieves a picture by its name from MinIO and serves it to the client:
      const stream = await minio.getObject(
        minioBucket,
        decodeURIComponent(req.params.name),
      )
      stream.pipe(res)
    })

    app.listen(port, () => {
      console.log(`App listening on http://localhost:${port}`)
    })

   
} // end async function start() 

//salve uma única nota no banco de dados:
async function saveNote(db, note) {
    await db.insertOne(note)
  }

//recuperar todas as notas do banco de dados:
async function retrieveNotes(db) {
    const notes = (await db.find().toArray()).reverse()
    
    //converte todas as notas em HTML bem formatadas antes de devolvê-las:
    return notes.map(it => {
        return { ...it, description: marked(it.description) }
    })
  }

start()