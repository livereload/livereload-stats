#!/bin/bash
mkdir -p data/apache-bz2
mkdir -p data/apache
echo "RSYNC data/apache-bz2"
rsync -azv 'andreyvit_livereload@ssh.phx.nearlyfreespeech.net:/home/logs/access_log.*.bz2' data/apache-bz2/
cd data/apache
for i in ../apache-bz2/*.bz2; do
  dst="$(basename "$i" .bz2)"

  if /usr/bin/test "$i" -nt "$dst"; then
    echo BUNZIP $(basename "$i")
    bunzip2 -c $i >"$dst"
  fi
done
for i in access_log.*[abcdef]; do
  marker="$i.DONEZ"
  if /usr/bin/test "$i" -nt "$marker"; then
    echo "CONCAT $i"
    cat $i >>${i%?}
    touch $marker
  fi
done
