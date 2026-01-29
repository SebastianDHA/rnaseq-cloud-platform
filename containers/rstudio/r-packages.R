
install.packages(c(
  "tidyverse",
  "rstatix",
  "ggrepel",
  "patchwork",
  "viridis",
  "ggbeeswarm",
  "readxl",
  "xlsx",
  "janitor",
  "nplyr",
  "gt",
  "cowplot",
  "arrow",
  "ggh4x",
  "tidytext",
  "ggtext",
  "gghighlight",
  "ggpubr",
  "scales",
  "ggpmisc",
  "assertthat",
  "rlang",
  "textclean",
  "ggprism",
  "ggpp",
  "lemon",
  "ggwordcloud"
))

if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install(c(
  "variancePartition",
  "edgeR",
  "limma",
  "vsn",
  "sva",
  "tximeta",
  "SummarizedExperiment",
  "BiocParallel",
  "clusterProfiler", 
  "DOSE"
))
