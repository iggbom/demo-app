# ── Stage 1: compile the Curity phantom token nginx module ─────────────────
FROM nginx:alpine AS module-builder

RUN apk add --no-cache gcc make libc-dev openssl-dev pcre2-dev zlib-dev git wget

# Download nginx source at exactly the version shipped in the base image so
# the compiled .so is ABI-compatible with the runtime nginx binary.
RUN NGINX_VERSION=$(nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') \
 && wget -q "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
 && tar xzf "nginx-${NGINX_VERSION}.tar.gz" \
 && mv "nginx-${NGINX_VERSION}" /nginx-src

RUN git clone --depth 1 https://github.com/curityio/nginx_phantom_token_module.git /phantom-src

RUN cd /nginx-src \
 && ./configure --with-compat --add-dynamic-module=/phantom-src \
 && make modules

# ── Stage 2: build the React/Vite app ──────────────────────────────────────
FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# No VITE_* build-time args needed — config is injected at runtime via window.env
RUN npm run build

# ── Stage 3: nginx runtime ──────────────────────────────────────────────────
FROM nginx:alpine

# Install the phantom token dynamic module.
RUN mkdir -p /usr/lib/nginx/modules
COPY --from=module-builder /nginx-src/objs/ngx_curity_http_phantom_token_module.so /usr/lib/nginx/modules/

# Replace the main nginx.conf with one that loads the module.
COPY nginx-main.conf /etc/nginx/nginx.conf

# Config templates processed at container startup by docker-entrypoint.sh
COPY config.js.template    /etc/nginx/config.js.template
COPY nginx.conf.template   /etc/nginx/nginx.conf.template

COPY --from=build /app/dist /usr/share/nginx/html

# Entrypoint: generate runtime configs from env vars, then start nginx
COPY 40-generate-configs.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
