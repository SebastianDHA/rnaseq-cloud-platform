## Versioned R from rocker
FROM rocker/rstudio:4.4.0

## System dependencies
RUN apt-get update && apt-get install -y \
	libcurl4-openssl-dev \
   	libssl-dev \
   	libxml2-dev \
   	libgit2-dev \
   	libxt6 \
   	curl \
   	git \
	&& rm -rf /var/lib/apt/lists/*

## Install Bioconductor and CRAN packages
COPY r-packages.R /tmp/r-packages.R
RUN Rscript /tmp/r-packages.R && rm /tmp/r-packages.R

## Set working R directory
WORKDIR /home/rstudio