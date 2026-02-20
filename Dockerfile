# Stage 1: Build the React app
FROM --platform=linux/amd64 node:18-alpine AS build

WORKDIR /app

# ✅ ARG must come before ENV to accept --build-arg from docker build
ARG VITE_API_URL=http://192.168.100.116
ENV VITE_API_URL=${VITE_API_URL}

COPY package*.json ./

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