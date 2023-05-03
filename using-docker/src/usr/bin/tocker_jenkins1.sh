#!/bin/sh -e

docker run --name tocker-jenkins1 \
    -v jenkins-volume:/var/jenkins_home \
    -p 8080:8080 -p 50000:50000 \
    jenkins/jenkins
