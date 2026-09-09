FROM node:18-alpine
WORKDIR /usr/src/app

# Copy package files correctly
COPY app/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy app code
COPY app/ .

EXPOSE 3000
CMD ["node", "server.js"].