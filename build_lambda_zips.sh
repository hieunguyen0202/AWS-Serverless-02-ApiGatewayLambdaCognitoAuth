#!/bin/bash

# Go to lambda_func module directory
cd terraform/modules/lambda_func

# Create generate_short_url.zip
mkdir -p tmp_generate && cp generate_short_url.py tmp_generate/app.py
cd tmp_generate && zip ../generate_short_url.zip app.py && cd ..
rm -rf tmp_generate

# Create get_url.zip
mkdir -p tmp_get && cp get_url.py tmp_get/app.py
cd tmp_get && zip ../get_url.zip app.py && cd ..
rm -rf tmp_get

echo "Lambda packages created successfully."