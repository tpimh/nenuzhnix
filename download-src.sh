#!/bin/sh

download() {
  if [ "$#" -eq 1 ]; then
    echo ${1##*/}
    wget -q --show-progress -N $1
  elif [ ${1##*.} = gz ]; then
    echo $2
    wget -q --show-progress -N $1 -O $2
  else
    echo $2
    wget -q --show-progress -N $1 -O - | xzcat - | gzip - > $2
  fi
}

while read line; do
  download $line
done <links.txt

git clone --recursive https://github.com/sba1/simplegit.git simplegit-20180325
rm -rf simplegit-20180325/.git* simplegit-20180325/genopts/.git* simplegit-20180325/libgit2
tar cfz simplegit-20180325.tar.gz simplegit-20180325
rm -rf simplegit-20180325
