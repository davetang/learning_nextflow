.PHONY: all clean

SS := samplesheet.csv

FILES := $(shell cat $(SS) | cut -f5 -d',' | grep -v input_file)

all: $(FILES) results/success

# targets...: pattern: prerequisites ...
# below the pattern is %, which just matches the entire target string
$(FILES): %: $(SS)
	@echo "Creating $@"
	@touch $@

results/success: main.nf $(FILES)
	nextflow run $<
	touch $@

clean:
	@rm -rfv $(FILES) .nextflow* work results
