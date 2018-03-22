#!/bin/sh

download() {
  if [ "$#" -eq 1 ]; then
    echo ${1##*/}
    curl --progress-bar -O $1
  elif [ ${1##*.} = gz ]; then
    echo $2
    curl --progress-bar $1 -o $2
  else
    echo $2
    curl --progress-bar $1 -o - | xzcat - | gzip - > $2
  fi
}

while read line; do
  download $line
done <links.txt
