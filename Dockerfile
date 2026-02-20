# Stage 1: Build the React app
FROM --platform=linux/amd64 node:18-alpine AS build

# Set working directory
WORKDIR /app

# Accept build arg for backend API URL (passed from Jenkins or docker build)
ARG VITE_API_URL
ENV VITE_API_URL=${VITE_API_URL}

# Copy package files first (better layer caching)
COPY package*.json ./

# Install dependencies (use ci for CI reproducibility, --force if you have conflicts)
RUN npm ci --force

# Copy source code
COPY . .

# Build for production
RUN npm run build

# Stage 2: Serve with Nginx (lightweight)
FROM --platform=linux/amd64 nginx:alpine

# Copy built files from previous stage
COPY --from=build /app/dist /usr/share/nginx/html

# Custom Nginx config (if you have one)
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Run Nginx
CMD ["nginx", "-g", "daemon off;"]