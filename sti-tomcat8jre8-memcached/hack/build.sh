#!/bin/bash -e
# Ce script est utilisé pour construire et squasher l'image du reverse proxy
# positionnée en frontal de la rados GW.
# This script is used to build, test and squash the OpenShift Docker images.
#
# Name of resulting image will be: 'd1g1tal/s3-reverse-proxy'.
#
# DOCKER_VERSION - Version de l'image Docker à créer, e.g. v1.0
# BASE_IMAGE_NAME - s3-reverse-proxy par défaut, normalement ok
# TAG_ON_SUCCESS - If set, tested image will be re-tagged as a non-candidate
#       image, if the tests pass.
set -x

if [ ! -d AccessMaster/usr ]; then
  echo "AccessMaster non present dans AccessMaster/usr/, merci de lire AccessMaster/README.md"
  exit 256
fi

DOCKERFILE_PATH="Dockerfile"

OC_CLIENT_URL=https://github.com/openshift/origin/releases/download/v1.4.1/openshift-origin-client-tools-v1.4.1-3f9807a-linux-64bit.tar.gz
OC_CLIENT_SHA256=c2ac117e85a968c4d16d5657a31dce0715dcbfa4ab4a7bc49e5c6fd7caffb7da

test -z "$BASE_IMAGE_NAME" && {
  BASE_IMAGE_NAME="tomcat8jre8"
}

NAMESPACE="${DOCKER_NAMESPACE}/"
test -z "$DOCKER_NAMESPACE" && {
    NAMESPACE="d1g1tal/"
}

test -z "$DOCKER_VERSION" && {
    DOCKER_VERSION="latest"
}

# Cleanup the temporary Dockerfile created by docker build with version
trap "rm -f ${DOCKERFILE_PATH}.version" SIGINT SIGQUIT EXIT

# Perform docker build but append the LABEL with GIT commit id at the end
function docker_build_with_version {
  local dockerfile="$1"
  # Use perl here to make this compatible with OSX
  DOCKERFILE_PATH=$(perl -MCwd -e 'print Cwd::abs_path shift' $dockerfile)
  echo "-> Use ${DOCKERFILE_PATH}"
  pwd
  cp ${DOCKERFILE_PATH} "${DOCKERFILE_PATH}.version"
  git_version=$(git rev-parse HEAD)
  echo "LABEL io.openshift.builder-version=\"${git_version}\"" >> "${dockerfile}.version"
  if [[ "${UPDATE_BASE}" == "1" ]]; then
    BUILD_OPTIONS+=" --pull=true"
  fi
  docker build ${BUILD_OPTIONS} -t ${IMAGE_NAME} -f "${dockerfile}.version" .
  if [[ "${SKIP_SQUASH}" != "1" ]]; then
    squash "${dockerfile}.version"
  fi
  rm -f "${DOCKERFILE_PATH}.version"
}

# Install the docker squashing tool[1] and squash the result image
# [1] https://github.com/goldmann/docker-squash
function squash {
  # FIXME: We have to use the exact versions here to avoid Docker client
  #        compatibility issues
  easy_install -q --user docker_py==1.7.2 docker-squash==1.0.1
  base=$(awk '/^FROM/{print $2}' $1)
  kernel=$(uname)
  if [[ "$kernel" == "Darwin" ]]; then
    ${HOME}/Library/Python/2.7/bin/docker-scripts squash --tag ${IMAGE_NAME} -f $base ${IMAGE_NAME}
  else
    if [[ -f /etc/debian_version ]]; then
      ${HOME}/.local/bin/docker-squash --tag ${IMAGE_NAME} -f $base ${IMAGE_NAME}
    elif [[ -x "/usr/bin/docker-squash" ]]; then
      /usr/bin/docker-squash --tag ${IMAGE_NAME} -v -f $base ${IMAGE_NAME}
    else
      ${HOME}/.local/bin/docker-scripts squash --tag ${IMAGE_NAME} -f $base ${IMAGE_NAME}
    fi
  fi
}

function download_oc_client {
  curl --location -o ./oc.tgz ${OC_CLIENT_URL}
  # Check SHA256
  sha256sum=$(sha256sum ./oc.tgz | awk '{print $1}')
  if [ ! "$sha256sum" == "${OC_CLIENT_SHA256}" ]
  then
    echo "Checksum of oc client failed"
    exit 1
  else
    # Extract oc tool from oc.tgz
    tar -z -x --wildcards --no-xattrs --no-selinux -O -f ./oc.tgz "*/oc" > ./oc
    chmod +x ./oc
  fi
}

function check_oc_client  {
  if [[ -f "./oc.tgz" ]]
  then
      echo "File './oc.tgz' is already present"
      # Check SHA256
      sha256sum=$(sha256sum ./oc.tgz | awk '{print $1}')
      if [ ! "$sha256sum" == "${OC_CLIENT_SHA256}" ]
      then
        rm -f ./oc
        rm -f ./oc.tgz
        download_oc_client
      else
        # Extract oc tool from oc.tgz
        tar -z -x --wildcards --no-xattrs --no-selinux -O -f ./oc.tgz "*/oc" > ./oc
        chmod +x ./oc
      fi
  else
    download_oc_client
  fi
}


IMAGE_NAME="${NAMESPACE}${BASE_IMAGE_NAME}:${DOCKER_VERSION}"

if test -v TEST_MODE; then
  IMAGE_NAME+="-candidate"
fi

check_oc_client

echo "-> Building ${IMAGE_NAME} ..."
docker_build_with_version Dockerfile