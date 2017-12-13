#!/bin/bash

# Deployment script to quickly get a jukebox instance running on every machine.

# Dependencies: openssl, maven, docker, docker-compose
# All of those need to be available in the shell that is running this script.

trap "exit 1" ERR

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
function build_frontend {
    cd frontend

    # install dependencies if necessary
    if ! [ -d "./node_modules" ]; then
        npm install
    fi

    # run build script
    npm run build:aot:prod
    cd ..
}

# Builds the backend from source
function build_backend {
    cd backend
    mvn compiler:compile war:war
    mkdir -p logs
    touch logs/studie.log
    cd ..
}

clean () {
    down
    docker container prune --force
    docker images "jukebox_*" --format='{{.Repository}}' | xargs --no-run-if-empty docker rmi
    docker volume prune --force

    rm -rf ./backend/target ./backend/logs
}

# Deploys using docker compose. Will build images if necessary.
function deploy {
    docker-compose -f docker-compose.yml.prod up --build  
}


case $1 in
clean)
    # clean docker cache and backend target
    clean
;;
down)
    # shoutdown docker containers
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

if ! [ -f ./ssl/ssl.crt ] || ! [ -f ./ssl/ssl.key ]; then
    generate_ssl
fi
    build_frontend
    build_backend


deploy
