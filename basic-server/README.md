# Basic Sever

_Canonical Devices and IoT, Field Engineering_

Snap base: core20 (Ubuntu 20.04)
## Introduction

A simple server snap that demonstrates a basic TCP server using 'ncat'. When a client conneccts , the server responds with a "Hello, World!"
and disconnects.

## Quick start

1. Install the snap:
```bash
sudo snap install --dangerous basic-server_*.snap
```

2. View current port
```bash
sudo snap get basic-server daemon.port
```

3. Test the server:
```bash
nc localhost 9999
```

4. Change port
```bash
sudo snap get basic-server daemon.port=8080
```

##Source

- https://github.com/canonical/iot-field-example-snaps/tree/main/basic-server

