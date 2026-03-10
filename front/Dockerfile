FROM node:20-alpine

WORKDIR /app

# Copy package.json to install dependencies
COPY package.json ./
# Try to copy lockfile if it exists, otherwise just package.json
COPY package*.json ./

# Install dependencies
RUN npm install

# The rest of the application will be mounted as a volume in docker-compose for hot-reloading
EXPOSE 3000

# Set these environment variables so Next.js listens on all interfaces
ENV HOST=0.0.0.0
ENV PORT=3000
# Enable polling for file watching in Docker to ensure hot-reload works
ENV WATCHPACK_POLLING=true

CMD ["npm", "run", "dev"]
