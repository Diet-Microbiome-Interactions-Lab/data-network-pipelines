# Rules for each Snakemake Wokflow and Rule

1. Each rule should include the logging parameter
   1. The log should be composed of a config parameter log_folder and log_id, that way the user has full control over where the file is and how it is labeled. *Note*: Having a way to randomly+uniquely assign a log_id would be helpful for later parsing.

# Stuff that would be nice

1. Made out the limits of threads and RAM for each job
   1. Is there a way to show this with the -np command?
2. Pass

# Notes

- The most important thing to consider when grabbing new input through a workflow is how to uniquely identify it. For example, with a UUID or something within the filename makes it relatively easy

- How to work with Anvio? I want to make sure I can keep stuff up to date, such as (especially) SnakeMake. 

## Anvio Environment
- Could not install numpy<=1.24.1 due to python 3.12. I removed this dependency and instead installed
