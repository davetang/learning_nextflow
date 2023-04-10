#!/usr/bin/env bash

set -euo pipefail

# As of 20230410, OpenJDK version 9 to 19 are available at
# https://jdk.java.net/archive/; the download links have a unique hash, so
# please visit the URL above to obtain the relevant download link

url=https://download.java.net/java/GA/jdk20/bdc68b4b9cbc4ebcb30745c85038d91d/36/GPL/openjdk-20_linux-x64_bin.tar.gz

root_dir=$(realpath $(dirname $0)/..)
bin_dir=${root_dir}/bin

if [[ ! -e ${bin_dir} ]]; then
   mkdir ${bin_dir}
fi

tarball=$(basename ${url})
# extracted=${tarball%%.*}
extracted=jdk-20

if [[ -e ${tarball} ]]; then
   >&2 echo ${tarball} already exists
   exit 1
else
   wget ${url} -O ${tarball}
   tar -xzf ${tarball}
   mv ${extracted} ${bin_dir}
   rm ${tarball}
fi

>&2 echo Done
exit 0
