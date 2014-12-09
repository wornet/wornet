sudo apt-get install gcc make build-essential sudo git memcached redis mongodb nodejs npm nodejs-legacylibcap2-bin
sudo setcap cap_net_bind_service=+ep /usr/bin/nodejs
sudo setcap cap_net_bind_service=+ep /usr/local/bin/node
