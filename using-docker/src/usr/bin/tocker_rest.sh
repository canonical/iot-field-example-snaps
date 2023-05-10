#!/bin/sh -e

image() {
    curl --unix-socket /run/docker.sock -X POST \
        http://localhost/v1.41/images/create?fromImage=nginx:latest
}

list() {
    curl --unix-socket /run/docker.sock -X GET http://localhost/v1.41/containers/json
}

server() {
    curl --unix-socket /run/docker.sock -X POST    \
        -H "Content-Type: application/json"        \
        -d "@$SNAP/usr/share/composers/nginx.json" \
        http://localhost/v1.41/containers/create?name=nginx-server
}

start() {
    curl --unix-socket /run/docker.sock -X POST \
        http://localhost/v1.41/containers/nginx-server/start
}
