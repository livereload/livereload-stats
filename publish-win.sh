#!/bin/bash
echo "RSYNC data/html to http://livereload.com/stats/win/"
rsync -vrz data/html/ andreyvit_livereload@ssh.phx.nearlyfreespeech.net:/home/public/stats/win/
echo "http://livereload.com/stats/win/"
