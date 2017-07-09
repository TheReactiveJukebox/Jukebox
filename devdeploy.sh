#!/bin/sh

# Deployment script to quickly get a jukebox instance running on every machine.

# Dependencies: openssl, maven, docker, docker-compose
# All of those need to be available in the shell that is running this script.

# Generates a new SSL certificate in ssl subfolder, which will be mounted by nginx
generate_ssl() {
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
build_backend() {
    cd backend
    mvn compiler:compile
    mvn war:war
    cd ..
}

clean () {
    down
    yes | docker container prune
    docker images "jukebox_*" --format='{{.Repository}}' | xargs --no-run-if-empty docker rmi
    yes | docker volume prune
    cd backend
    if [ -d target ]; then
        rm -rf target
    fi
    cd ..
}

down () {
    docker-compose -f docker-compose.yml.dev down
}

# Deploys using docker compose. Will build images if necessary.
deploy() {
    docker-compose -f docker-compose.yml.dev up --build  
}

# Generate ssl certificate, if needed
if ! [ -f ./ssl/ssl.crt ] || ! [ -f ./ssl/ssl.key ]; then
    generate_ssl
fi

# clean docker cache and backend target
if [ $# == 1 ] && [ $1 == clean ]; then
    clean
fi

# shoutdown docker containers
if [ $# == 1 ] && [ $1 == down ]; then
	down
	exit
fi

if ! [ -f ./backend/target/server.war ]; then
    build_backend
fi

deploy
