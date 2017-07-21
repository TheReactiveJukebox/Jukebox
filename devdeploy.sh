#!/bin/sh

# Deployment script to quickly get a jukebox instance running on every machine.

# Dependencies: openssl, maven, docker, docker-compose
# All of those need to be available in the shell that is running this script.

COMPOSE_FILE=docker-compose.yml

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

# Removes containers, images, cache, volumes, compiled java app.
clean () {
    down
    docker container prune --force
    docker images "jukebox_*" --format='{{.Repository}}' | xargs --no-run-if-empty docker rmi
    docker volume prune --force

    rm -rf ./backend/target
}

# Runs docker-compose down
down () {
    docker-compose -f $COMPOSE_FILE down
}

# Deploys using docker compose. Will build images if necessary.
deploy() {
    docker-compose -f $COMPOSE_FILE up --build  
}

case $1 in
clean)
    # clean docker cache and backend target
    clean
;;
down)
    # shutdown docker containers
    down
    exit 0
;;
*)
    if [ -n "$1" ]
    then
        echo "usage: $0 [clean|down]" >&2
        exit 1
    fi
;;
esac
# Generate ssl certificate, if needed
if ! [ -f ./ssl/ssl.crt ] || ! [ -f ./ssl/ssl.key ]; then
    generate_ssl
fi

if ! [ -f ./backend/target/server.war ]; then
    build_backend
fi

deploy
