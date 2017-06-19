#!/bin/bash

# Deployment script to quickly get a jukebox instance running on every machine.

# Dependencies: openssl, maven, docker, docker-compose
# All of those need to be available in the shell that is running this script.

# Generates a new SSL certificate in ssl subfolder, which will be mounted by nginx
function generate_ssl {
    mkdir -p ssl
    openssl req \
        -x509 \
        -newkey rsa:4096 \
        -keyout ssl/ssl.key \
        -out ssl/ssl.crt \
        -days 365 \
        -nodes \
        -subj "/C=DE/ST=NRW/L=Dortmund/O=Reactive Jukebox/OU=PG 607/CN=*/"
}

# Builds the backend from source
function build_backend {
    cd backend
    mvn compiler:compile
    mvn war:war
    cd ..
}

# Deploys using docker compose. Will build images if necessary.
function deploy {
    docker-compose -f docker-compose.yml.dev up --build  
}

if ! [ -f ./ssl/ssl.crt ] || ! [ -f ./ssl/ssl.key ]; then
    generate_ssl
fi
if ! [ -f ./backend/target/server.war ]; then
    build_frontend
fi

deploy
