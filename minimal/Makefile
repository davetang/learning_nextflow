.PHONY: all clean

SS := samplesheet.csv

FASTQS := $(shell cat $(SS) | cut -f4-5 -d',' | grep -v fastq1 | tr ',' '\n')

all: $(FASTQS) results/success

# targets...: pattern: prerequisites ...
# below the pattern is %, which just matches the entire target string
$(FASTQS): %: $(SS)
	@echo "Creating $@"
	@touch $@

results/success: main.nf $(FASTQS)
	nextflow run $<
	touch $@

clean:
	@rm -rfv $(FASTQS) .nextflow* work results
