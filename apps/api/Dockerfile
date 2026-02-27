# Use the official Node.js image as base
FROM node:22-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy root configurations (if using workspaces, root package.json/lock is needed)
COPY package.json package-lock.json ./

# Copy API app
COPY apps/api/package.json ./apps/api/

# Install dependencies (from root to handle workspaces if applicable, or just in app if isolated)
# If ParkLocator uses npm workspaces, we run npm install at root.
RUN npm install

# Copy the rest of the source code
COPY . .

# Build the API
WORKDIR /app/apps/api
RUN npm run build

# Start a new stage for a smaller production image
FROM node:22-alpine AS runner

# Set NODE_ENV to production
ENV NODE_ENV production

# Set the working directory
WORKDIR /app

# Copy the package.json and install only production dependencies
COPY package.json package-lock.json ./
COPY apps/api/package.json ./apps/api/

RUN npm install --omit=dev

# Copy the built application from the builder stage
COPY --from=builder /app/apps/api/dist ./apps/api/dist

# Expose the API port (change if your API runs on a different port)
EXPOSE 3000

# Set the command to start the API
WORKDIR /app/apps/api
CMD ["npm", "run", "start:prod"]
