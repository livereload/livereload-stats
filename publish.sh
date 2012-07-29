#!/bin/bash
echo "RSYNC data/html"
sh rsync -avz data/html/ andreyvit_livereload@ssh.phx.nearlyfreespeech.net:/home/public/stats/
echo "http://livereload.com/stats/"
