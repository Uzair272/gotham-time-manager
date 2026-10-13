FROM node:18 AS build

WORKDIR /app

# Install dependencies and build
COPY package*.json ./
RUN npm ci --silent
COPY . .
RUN npm run build

FROM nginx:stable-alpine

# Copy built static files to nginx
COPY --from=build /app/dist /usr/share/nginx/html

# Send every unknown path to index.html so vue-router (history mode) works on refresh
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose HTTP port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
