FROM node:14
RUN npm install -g npm
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the container
COPY package*.json ./

# Install application dependencies
RUN npm install

# Copy the rest of the application code to the container
COPY . .
EXPOSE 5000

CMD ["node", "server.js"]
