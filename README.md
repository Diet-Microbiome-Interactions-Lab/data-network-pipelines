# Metagenomic Pipelines
## Dane Deemer

The name of this repo is a little bit misleading, as it's not just a repository for *metagenomics* pipelines, but also for various other types of bioinformatics data.

## Structure

This repository is broken down into a few main branches

## 1. snakemake
This contains SnakeMake files along with the corresponding config and README. Each SnakeMake file should be able to be copied from this repo with its' corresponding config file (or by altering a different config file based on requirements in README) and be used in any context. What's missing? The actual environment. Environment management is annoying and not a priority right now, so the README file will have a suggested environment, as well as critical dependencies.
Later on, all of these will be incorporated into the offical SnakeMake Wrappers Github so anyone can use these rules with the *wrapper:* directive.