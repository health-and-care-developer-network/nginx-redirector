#!/bin/bash

# Usage:
# deploy-nginx.sh registryhostname targethostname

REGISTRY_HOST=$1
TARGET_HOST=$2

LISTEN_PORT=${LISTEN_PORT:-8083}
CONTAINER_NAME=${CONTAINER_NAME:-nginx-openods-redirector}
IMAGE_NAME=${IMAGE_NAME:-nhsd/nginx-openods-redirector}

if [ -z $TARGET_HOST ]
then
  TARGET_PREFIX=""
else
  TARGET_PREFIX="--tlsverify -H $TARGET_HOST:2376"
fi

if [ -z $REGISTRY_HOST ]
then
  # No private docker registry
  REGISTRY_PREFIX=""
  SOURCE_URL=$IMAGE_NAME
else
  # Registry specified, so use it
  REGISTRY_PREFIX="--tlsverify -H $REGISTRY_HOST:2376"
  SOURCE_URL=$REGISTRY_HOST:5000/$IMAGE_NAME
  docker $TARGET_PREFIX pull $SOURCE_URL
fi

MEMORYFLAG=500m
CPUFLAG=768

echo "Stopping any existing OpenODS containers"
docker $TARGET_PREFIX stop openods
docker $TARGET_PREFIX stop openods-postgres

echo "Run NGinX OpenODS redirector"
docker $TARGET_PREFIX stop $CONTAINER_NAME
docker $TARGET_PREFIX rm $CONTAINER_NAME
docker $TARGET_PREFIX run --name $CONTAINER_NAME \
	--restart=always \
        -m $MEMORYFLAG \
	-c $CPUFLAG \
	-p $LISTEN_PORT:80 \
	-d $SOURCE_URL

