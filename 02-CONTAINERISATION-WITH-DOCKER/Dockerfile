#baseImage:a version of Ubuntu with Node.js installed:
FROM node:12.0-slim

#COPY source dest ( source:app -> dest:container)
COPY . .

#RUN command  (executes inside the container)
RUN npm install

# Command that should be executed when the container starts:
CMD [ "node", "index.js" ]

