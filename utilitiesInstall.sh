#!/bin/bash

sudo apt update -y > /dev/null

sudo apt install -y nodejs npm

sudo npm i -g azure-functions-core-tools@4 --unsafe-perm true

sudo apt install -y python3.10-venv
