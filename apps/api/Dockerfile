# Use the official Node.js image as base
FROM node:22-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy package configurations
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy the rest of the source code
COPY . .

# Build the API
RUN npm run build

# Start a new stage for a smaller production image
FROM node:22-alpine AS runner

# Set NODE_ENV to production
ENV NODE_ENV production

# Set the working directory
WORKDIR /app

# Copy the package.json and install only production dependencies
COPY package.json package-lock.json ./

RUN npm install --omit=dev

# Copy the built application from the builder stage
COPY --from=builder /app/dist ./dist

# Expose the API port (change if your API runs on a different port)
EXPOSE 3000

# Set the command to start the API
CMD ["node", "dist/main"]
