#!/bin/sh

download() {
  if [ "$#" -eq 1 ]; then
    wget $1
  elif [ ${1##*.} = gz ]; then
    wget $1 -O $2
  else
    wget $1 -O - | xzcat - | gzip - > $2
  fi
}

while read line; do
  download $line
done <links.txt
