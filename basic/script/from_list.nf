#!/usr/bin/env nextflow

my_list = ['the', 'quick', 'brown', 'fox', 'jumps', 'over', 'the', 'lazy',
'dog']

Channel
   .fromList(my_list)
   .view()
