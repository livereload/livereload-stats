#!/bin/bash
mkdir -p data/s3
echo "S3CMD data/s3"
s3cmd -v sync s3://livereload-logs/ping/logs/ data/s3/
