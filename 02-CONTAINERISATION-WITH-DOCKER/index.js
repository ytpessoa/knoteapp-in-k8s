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
  const db = await initMongo() //esperando conexão com o servidor MongoDB  
  app.set('view engine', 'pug')
  app.set('views', path.join(__dirname, 'views'))
  app.use(express.static(path.join(__dirname, 'public')))

    // O formulário é enviado para a rota "/note" , 
    // então você precisa adicionar essa rota ao seu aplicativo:
    app.post(
        '/note',
        //salva as imagens carregadas em "public/uploads":
        multer({ dest: path.join(__dirname, 'public/uploads/') }).single('image'),
        
        async (req, res) => {
            if (!req.body.upload && req.body.description) {
            await saveNote(db, { description: req.body.description })
            res.redirect('/') //redirecionado para a página principal
            } else if (req.body.upload && req.file) {
                // insere um link para o arquivo na caixa de texto
                const link = `/uploads/${encodeURIComponent(req.file.filename)}`
                res.render('index', {
                  content: `${req.body.description} ![](${link})`,
                  notes: await retrieveNotes(db),
                })
            }
        }
    )


  app.listen(port, () => {
    console.log(`App listening on http://localhost:${port}`)
  })

  app.get('/', async (req, res) => {
    res.render('index', { notes: await retrieveNotes(db) })
  })

}

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