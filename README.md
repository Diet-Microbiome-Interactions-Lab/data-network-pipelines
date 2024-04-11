# Data Network Pipelines (Bioinformatics)
## A DMIL-Supported Resource out of Purdue University

A repository housing a multitude of rules for job execution along with complete workflows. Each job is like a lego block that can be connected to other jobs (legos) based on compatible input and output. The goal is to be able to perform both simple jobs and comprehensive workflows with a few keystrokes and changes of configuration. This repo is meant to be open-source and we encourage community collaboration. If you think a rule of ours is stinky, open an issue/create a PR/comment and we are happy to take suggestions.

## Structure

This repository is broken down into a few main branches. The biggest is the SnakeRules folder, which houses a bunch of snakemake-specific rules and workflows. Snakemake is cool -> peep there docs, put it on your resume, and become a Snake-boi, Snake-gyrl, or Snake-p3rson. The second folder is Wrappers, which I'm not sure what is going on with that. Eventually, non-snakemake workflows will be added (such as NextFlow-based, bash-piped, or whatevers else). 

## 1. snakemake rules
This contains SnakeMake files along with the corresponding config and README. Each SnakeMake file should be able to be copied from this repo with its' corresponding config file (or by altering a different config file based on requirements in README) and be used in any context. What's missing? The actual environment. Environment management is annoying and not a priority right now, so the README file will have a suggested environment, as well as critical dependencies.
Later on, all of these will be incorporated into the offical SnakeMake Wrappers Github so anyone can use these rules with the *wrapper:* directive.