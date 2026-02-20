# Stage 1: Build the React app
FROM --platform=linux/amd64 node:18-alpine AS build

WORKDIR /app

# Runtime env fallback (can be overridden by docker-compose)
ENV VITE_API_URL=${VITE_API_URL:-http://localhost}

COPY package*.json ./

# Fast mirror + retry loop
RUN npm config set registry https://registry.npmmirror.com --global && \
    for i in {1..5}; do \
        npm ci --force && break || (echo "npm ci attempt $i failed - retrying..." && sleep 15); \
    done

COPY . .
RUN npm run build

# Stage 2: Serve with Nginx
FROM --platform=linux/amd64 nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]