#!/bin/bash
echo "RSYNC data/html"
rsync -vz data/html/ andreyvit_livereload@ssh.phx.nearlyfreespeech.net:/home/public/stats/
echo "http://livereload.com/stats/"
