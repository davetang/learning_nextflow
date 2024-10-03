.PHONY: all
SHELL := /bin/bash

all: results/num_sorted_10.txt results/num_sorted_5.txt

results/num_sorted_10.txt: run_nf.sh
	bash $<

results/num_sorted_5.txt: results/num_sorted_10.txt
	head -5 $< > $@

clean:
	rm -rf .nextflow* work results *.log
