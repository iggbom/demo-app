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

# The .env file must exist at build time so Vite can inline VITE_* variables
ARG VITE_AUTHORITY
ARG VITE_CLIENT_ID
ARG VITE_CLIENT_SECRET
RUN VITE_AUTHORITY=${VITE_AUTHORITY} VITE_CLIENT_ID=${VITE_CLIENT_ID} VITE_CLIENT_SECRET=${VITE_CLIENT_SECRET} npm run build

# ── Stage 3: nginx runtime ──────────────────────────────────────────────────
FROM nginx:alpine

# Install the phantom token dynamic module.
RUN mkdir -p /usr/lib/nginx/modules
COPY --from=module-builder /nginx-src/objs/ngx_curity_http_phantom_token_module.so /usr/lib/nginx/modules/

# Replace the main nginx.conf with one that loads the module.
# Must be done via COPY (not a shell heredoc) to reliably overwrite the file.
COPY nginx-main.conf /etc/nginx/nginx.conf

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
