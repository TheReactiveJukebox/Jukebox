#!/bin/bash
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

function build {
    cd frontend
	#is npm installed?
	if ! [ -d "./node_modules" ]; then
		npm install
	fi
    npm run build:prod
    cd ../backend
    mvn deploy
    cd ..
}

function deploy {
    docker-compose -f docker-compose.yml.dev up --build  
}

if ! [ -f ./ssl/ssl.crt ] || ! [ -f ./ssl/ssl.key ]; then
    generate_ssl
fi

build
deploy
