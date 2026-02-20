# Stage 1: Build the React app
FROM --platform=linux/amd64 node:18-alpine AS build

WORKDIR /app

ARG VITE_API_URL
ENV VITE_API_URL=${VITE_API_URL:-http://localhost}   

COPY package*.json ./

# Use fast mirror + retry to survive network drops
RUN npm config set registry https://registry.npmmirror.com --global && \
    npm config set disturl https://npmmirror.com/mirrors/node --global && \
    for i in {1..5}; do \
        npm ci --force && break || (echo "npm ci attempt $i failed - retrying..." && sleep 15); \
    done

COPY . .
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