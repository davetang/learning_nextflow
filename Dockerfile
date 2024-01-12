FROM davetang/rstudio:4.3.2

MAINTAINER Dave Tang <me@davetang.org>

RUN apt-get clean all && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
      default-jre \
      curl && \
    apt-get clean all && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /src && \
    cd /src && \
    curl -fsSL get.nextflow.io | bash && \
    mv nextflow /usr/local/bin && \
    cd && rm -rf /src

WORKDIR /work
