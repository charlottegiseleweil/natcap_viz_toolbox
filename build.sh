#!/usr/bin/env bash

# Default options
open=false
interactive_spellcheck=false
batch_spellcheck=true
outputs=()
formats=()

latex_includes=(
  '--include-in-header=templates/subcaption.tex'
  '--include-in-header=templates/chapter-style.tex'
  '--include-in-header=templates/caption-size.tex'
  '--include-in-header=templates/square-bullets.tex'
  '--include-in-header=templates/margins.tex'
  '--include-in-header=templates/landscape.tex'
  '--include-before-body=templates/titlepage.tex'
);

html_includes=(
  '--include-in-header=templates/css-imports.html'
  '--include-in-header=templates/style.html'
  '--include-before-body=templates/body-open.html'
  '--include-after-body=templates/body-close.html'
  '--include-after-body=templates/js-imports.html'
  '--include-after-body=build/script.html'
  '--latexmathml'
);

# Process command line arguments
while test $# -gt 0
do
    case "$1" in
        --spellcheck) interactive_spellcheck=true
            ;;
        --nospellcheck) batch_spellcheck=false
            ;;
        --open) open=true
            ;;
        --pdf) outputs+=(pdf); formats+=(latex) 
            ;;
        --tex) outputs+=(tex); formats+=(latex)
            ;;
        --docx) outputs+=(docx); formats+=('')
            ;;
        --html) outputs+=(html); formats+=(html)
            ;;
        *) echo "unrecognized option $1"
            ;;
    esac
    shift
done

# If no target is specified, pick pdf only
if [ ${#outputs[@]} -eq 0 ]; then
  outputs+=(pdf)
  formats+=(latex)
fi

# Create build directory if not present
if [ ! -d build ]; then 
  mkdir build
fi

# Spell check the files
if [ $interactive_spellcheck = true ]; then
  # Run interactive mode to fix spelling mistakes
  mdspell --ignore-acronyms --en-us src/*.md || exit 1
elif [ $batch_spellcheck = true ]; then
  mdspell --report --ignore-acronyms --en-us src/*.md
fi


# Generate documents for all output formats 
for idx in "${!outputs[@]}"; do
  
  # Concatenate all files with space in between
  for f in src/*.md; do 
    cat "${f}"; echo; echo;
  done > build/toolbox_raw.md;
  
  outfile="build/toolbox.${outputs[$idx]}"
  format="${formats[$idx]}"
  if [ ! -z $format ]; then
    case $format in
      html) includes="${html_includes[@]}"
        ;;
      latex) includes="${latex_includes[@]}";
        ;;
      *) includes="";
        ;;
    esac

    format="-t $format"
  fi

  # Update all the links to be pdf instead of png
  if [ "$format" = "-t latex" ]; then
    cat build/toolbox_raw.md |\
      sed -e "s|/g/png|/g/pdf|g" |\
      sed -e "s|../images|images|g" \
      > build/toolbox.md;
    mv build/toolbox.md build/toolbox_raw.md;
  elif [ "$format" = "-t html" ]; then 
    GIT_COMMIT_DATE=$(bash -c "git log -1 --format=%cD | cut -f1-4 -d ' '")
    sed "s|LASTCOMMITDATE|$GIT_COMMIT_DATE|g" ./templates/script.html > build/script.html
    cat build/toolbox_raw.md |\
      sed -e 's|\\ref{\([^}]*\)}|<span class="ref">\1</span>|g' \
      > build/toolbox.md;
    mv build/toolbox.md build/toolbox_raw.md;
  fi

  # Render the comments correctly
  cat build/toolbox_raw.md |\
    sed \
        -e s/'~~}'/'}'/g \
        -e s/'{~~'/'\\st{'/g \
        -e s/'~>'/'}\\underline{'/g \
        -e s/'{--'/'\\st{'/g \
        -e s/'--}'/'}'/g \
        -e s/'{++'/'\\underline{'/g \
        -e s/'++}'/'}'/g \
        -e s/'{=='/'\\hl{'/g \
        -e s/'==}'/'}'/g \
        -e s/'{>>'/'\\marginpar{'/g \
        -e s/'<<}'/'}'/g \
    > build/toolbox.md

  echo -n "Compiling toolbox to $outfile ($format) ..."
  cat build/toolbox.md |\
  pandoc -f markdown $format \
    $includes \
    --smart \
    --reference-links \
    --standalone \
    --number-sections \
    --default-image-extension=pdf \
    --toc \
    --normalize \
    --highlight-style=tango \
    --filter pandoc-fignos \
    --filter pandoc-citeproc \
    --bibliography=src/biblio.bib \
    --csl templates/civil.csl \
    -V documentclass:memoir \
    -V classoption=oneside \
    -V fontsize=11pt \
    --variable=geometry:a4paper \
    -o $outfile
  echo " Done !"
done

if [ $open = true ]; then
  open build/toolbox.pdf
fi

