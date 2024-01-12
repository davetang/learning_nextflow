#!/usr/bin/env bash

set -euo pipefail

version=4.3.2
image=davetang/learning_nextflow:${version}
container_name=learning_nextflow_${version}
port=6767

docker run \
   --name ${container_name} \
   -d \
   --rm \
   -p ${port}:8787 \
   -v $(pwd):/home/rstudio/work \
   -e PASSWORD=password \
   -e USERID=$(id -u) \
   -e GROUPID=$(id -g) \
   ${image}

>&2 echo ${container_name} listening on port ${port}

exit 0
