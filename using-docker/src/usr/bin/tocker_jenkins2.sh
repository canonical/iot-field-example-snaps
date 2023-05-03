#!/bin/sh -e

docker run --name tocker-jenkins2 \
    -v jenkins-volume:/var/jenkins_home \
    -p 9090:8080 -p 60000:50000 \
    jenkins/jenkins
