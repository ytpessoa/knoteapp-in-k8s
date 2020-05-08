
#defines the base layer for the container, in this case, a version of Ubuntu with Node.js installed:
FROM node:12.0-slim

#copies the files of your app into the container: source -> destination:
COPY . .  

# executes inside the container:
RUN npm install

# defines the command that should be executed when the container starts
CMD ["node", "index.js"]