.PHONY: all
SHELL := /bin/bash

RVER := 4.4.0
all: verse_$(RVER).sif

verse_$(RVER).sif:
	singularity pull docker://rocker/verse:$(RVER)
