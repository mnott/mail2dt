#!/bin/bash

export PATH=$PATH:/usr/local/bin

docker-compose run -p 993:993 mail

echo Done.
