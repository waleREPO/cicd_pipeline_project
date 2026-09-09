# Copy package files
COPY app/package*.json ./

# Install dependencies
RUN npm install --production

# Copy app code
COPY app/ .

# Expose port
EXPOSE 3000

# Start the app
CMD ["node", "server.js"]