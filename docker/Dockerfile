FROM debian:stretch

RUN apt-get update && apt-get install -y \
        git \
        pandoc \
        pandoc-citeproc \
        texlive-fonts-recommended \
        texlive-latex-extra \
        texlive-fonts-extra \
        python-pip \
        && pip install pandoc-fignos --system
