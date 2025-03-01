#!/bin/bash

set -e

pushd ${BASH_SOURCE%/*} > /dev/null
. ./constants.sh
. ./console.sh
. ./platform.sh

./require.sh docker
./check-docker.sh
popd > /dev/null

export DOCKER_BUILDKIT=1

PROJECT_DIR="$( pwd )"
PROJECT_NAME=${PROJECT_NAME:-''}
PROJECT_YAML=${PROJECT_YAML:-''}
SOURCE_DIR=${SOURCE_DIR:-''}
DEPLOYMENT_DIR=${DEPLOYMENT_DIR:-''}

# ------------------
function validateParameters()
{
    [ -z ${PROJECT_NAME} ] && error "PROJECT_NAME is not set."
    [ -z ${PROJECT_YAML} ] && error "PROJECT_YAML is not set."
    [ -z ${SOURCE_DIR} ] && error "SOURCE_DIR is not set."
    [ -z ${DEPLOYMENT_DIR} ] && error "DEPLOYMENT_DIR is not set."

    [ ! -f ${PROJECT_YAML} ] && error "File \"${PROJECT_YAML}\" is not accessible."
    [ ! -d ${SOURCE_DIR} ] && error "Directory \"${SOURCE_DIR}\" is not accessible."
    [ ! -d ${DEPLOYMENT_DIR} ] && error "Directory \"${DEPLOYMENT_DIR}\" is not accessible."

    return ${__TRUE}
}

# ------------------
function bootDeployment()
{
    verbose "${INFO}Building generator${NC}"
    docker build -t spryker_docker_sdk \
        -f "${SOURCE_DIR}/generator/Dockerfile" \
        "${SOURCE_DIR}/generator"

    cp -rf ${SOURCE_DIR}/bin ${DEPLOYMENT_DIR}/bin
    cp -rf ${SOURCE_DIR}/context ${DEPLOYMENT_DIR}/context
    cp -rf ${SOURCE_DIR}/images ${DEPLOYMENT_DIR}/images
    cp ${PROJECT_YAML} ${DEPLOYMENT_DIR}/project.yml

    USER_UID=1000
    USER_GID=1000
    [ "$(getPlatform)" == "linux" ] && USER_UID=$(id -u) && USER_GID=$(id -g)

    verbose "${INFO}Running generator${NC}"
    docker run -i --rm \
        -e SPRYKER_DOCKER_SDK_PROJECT_NAME=${PROJECT_NAME} \
        -e SPRYKER_DOCKER_SDK_PROJECT_YAML="/data/deployment/project.yml" \
        -e SPRYKER_DOCKER_SDK_DEPLOYMENT_DIR="/data/deployment" \
        -e SPRYKER_DOCKER_SDK_PLATFORM="$(getPlatform)" \
        -v ${DEPLOYMENT_DIR}:/data/deployment:rw \
        -u ${USER_UID}:${USER_GID} \
        spryker_docker_sdk

    chmod +x ${DEPLOYMENT_DIR}/deploy
}

validateParameters
bootDeployment
