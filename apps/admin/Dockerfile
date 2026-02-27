# Stage 1: Build the Angular application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built assets from builder stage
# Angular outputs to dist/admin/browser/ with the application builder
COPY --from=builder /app/dist/admin/browser /usr/share/nginx/html

# Copy custom Nginx config template for SPA support
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Expose port 80
EXPOSE 80

# Use envsubst to substitute environment variables at runtime
# API_URL defaults to http://localhost:3000 if not set
ENV API_URL=http://localhost:3000
CMD ["/bin/sh", "-c", "envsubst '${API_URL}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
