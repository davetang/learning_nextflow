#!/usr/bin/env bash
ver=4.3.2
docker build -t davetang/learning_nextflow:${ver} .

# docker login
# docker push davetang/rstudio:${ver}
