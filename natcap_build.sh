#! /bin/bash

# Generate the html file at build/toolbox.html
./build.sh --html --nospellcheck

# fix up relative paths so we can distribute to bucket
sed 's|../images|images|g' build/toolbox.html > build/index.html

# Synchronize the toolbox with the storage bucket.
# Assumes we're properly authenticated with google cloud/gsutil.
gsutil cp build/index.html gs://viz.naturalcapitalproject.org/index.html
gsutil -m rsync -d images gs://viz.naturalcapitalproject.org/images
