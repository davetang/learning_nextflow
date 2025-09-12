#!/usr/bin/env nextflow

/*
 * Nextflow DSL2 workflow for sorting numbers and extracting top N values
 *
 * This workflow demonstrates:
 * - File processing with path inputs
 * - Process chaining and data flow
 * - Parameter usage and configuration
 * - Modern DSL2 syntax and best practices
 */

// Enable DSL2 syntax
nextflow.enable.dsl = 2

// Define pipeline parameters with default values
params.input_file = "$HOME/github/learning_nextflow/data/num.txt"
params.top_n = 10
params.outdir = "results"

/*
 * SORT: Process to sort numbers in ascending order
 *
 * This process takes a text file containing numbers and sorts them numerically.
 * The sorted output is saved to a new file with "_sorted" suffix.
 */
process SORT {
    // Add a descriptive tag for better process identification
    tag "Sorting ${input_file.name}"

    // Publish sorted files to results directory
    publishDir "${params.outdir}/sorted", mode: 'copy'

    input:
    path input_file  // Input file containing numbers to sort

    output:
    path "${input_file.baseName}_sorted.txt", emit: sorted_file  // Named output for clarity

    script:
    """
    # Sort numbers in ascending order (-n flag for numerical sort)
    sort -n ${input_file} > ${input_file.baseName}_sorted.txt

    # Log the sorting operation
    echo "Sorted ${input_file} -> ${input_file.baseName}_sorted.txt" >&2
    """
}

/*
 * TOPN: Process to extract the top N values from sorted data
 *
 * This process takes a sorted file and extracts the first N lines,
 * which represent the N smallest values after sorting.
 */
process TOPN {
    // Add descriptive tag showing which file and how many lines
    tag "Top ${n} from ${sorted_file.name}"

    // Publish results to output directory
    publishDir "${params.outdir}/top_values", mode: 'copy'

    input:
    path sorted_file  // Sorted input file
    val n            // Number of top values to extract

    output:
    path "top_${n}_values.txt", emit: top_values  // Save output to file instead of stdout
    stdout emit: display                          // Also emit to stdout for viewing

    script:
    """
    # Extract the first N lines (smallest N values)
    head -${n} ${sorted_file} > top_${n}_values.txt

    # Also output to stdout for immediate viewing
    echo "Top ${n} smallest values:"
    head -${n} ${sorted_file}

    # Log the operation
    echo "Extracted top ${n} values from ${sorted_file}" >&2
    """
}

/*
 * Main workflow definition
 *
 * This workflow orchestrates the data processing pipeline:
 * 1. Creates input channel from the specified file
 * 2. Sorts the numbers in the file
 * 3. Extracts the top N smallest values
 * 4. Displays the results
 */
workflow {
    // Create input channel from the parameter file
    // Using Channel.fromPath ensures proper file handling
    input_ch = Channel.fromPath(params.input_file, checkIfExists: true)

    // Execute the SORT process
    // The sorted file is automatically passed to the next process
    sorted_ch = SORT(input_ch)

    // Execute the TOPN process with sorted data and the top_n parameter
    // This demonstrates passing both file and value inputs
    top_values_ch = TOPN(sorted_ch.sorted_file, params.top_n)

    // Display the results using the view operator
    // This shows the stdout output from the TOPN process
    top_values_ch.display.view { result ->
        "=== PIPELINE RESULTS ===\n${result.trim()}\n========================"
    }
}

// Workflow event handlers - MUST be placed outside the workflow block
workflow.onComplete {
    log.info """
    Pipeline completed successfully!
    - Input file: ${params.input_file}
    - Top N values: ${params.top_n}
    - Results saved to: ${params.outdir}
    - Duration: ${workflow.duration}
    - Success: ${workflow.success}
    """
}

workflow.onError {
    log.error "Pipeline execution failed: ${workflow.errorMessage}"
}

/*
 * Workflow summary and usage information
 *
 * This workflow can be run with custom parameters:
 *
 * nextflow run main.nf --input_file /path/to/numbers.txt --top_n 5 --outdir my_results
 *
 * Parameters:
 * - input_file: Path to input file containing numbers (one per line)
 * - top_n: Number of smallest values to extract (default: 10)
 * - outdir: Output directory for results (default: "results")
 */
