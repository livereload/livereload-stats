#! /bin/bash

yearly=false
source=apache
if test "$1" = "-y"; then
  yearly=true
  echo "Will run yearly statistics."
  shift
fi
if test "$1" = "--s3"; then
  source=s3
  shift
fi

echo "Source: $source."

node bin/process.js ${source}-to-raw $source raw "$@"

node bin/process.js rawtodaily raw day-events "$@"
node bin/process.js reduce day-events month-events "$@"

node bin/process.js reducetemp month-events month-events-cum "$@"

node bin/process.js userinfo month-events-cum month-users "$@"

node bin/process.js usertemp month-users month-users-temp "$@"

node bin/process.js segmentation month-users-temp month-segments "$@"

node bin/report.js

if $yearly; then
  node bin/process.js reduce day-events year-events "$@"
  node bin/process.js reducetemp year-events year-events-cum "$@"
fi
