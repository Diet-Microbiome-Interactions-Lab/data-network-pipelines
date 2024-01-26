__author__ = "Dane Deemer"
__copyright__ = "Copyright 2023, Dane Deemer"
__email__ = "ddeemer@purdue.edu"
__license__ = "MIT"

# import os
from snakemake.shell import shell

# prefix = os.path.splitext(snakemake.output[0])[0]

shell(
    "metaquast.py {snakemake.params} -t {snakemake.threads} -o {snakemake.output[0]} "
    "{snakemake.input[0]}"
)

# shell(
#     "samtools sort {snakemake.params} -@ {snakemake.threads} -o {snakemake.output[0]} "
#     "-T {prefix} {snakemake.input[0]}")