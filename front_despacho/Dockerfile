FROM node:24-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY . .

RUN npm run build

FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY nginx.conf.template /etc/nginx/templates/default.conf.template

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
