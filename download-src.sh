#!/bin/sh

PACKAGES=$(find . -maxdepth 2 -mindepth 2 -name 'opkg' -type d | sed 's/\.\/\(.*\)\/opkg/\1/')

getfield() {
  grep -e "^$2: " $1/opkg/control | sed 's/^'$2': \(.*\)$/\1/'
}

download() {
  if [ "$#" -eq 1 ]; then
    echo ${1##*/}
    rm -f ${1##*/}
    wget -q --show-progress -N $1
  elif [ ${1##*.} = gz ]; then
    echo $2
    rm -f ${1##*/} $2
    wget -q --show-progress -N $1 -O $2
  else
    echo $2
    rm -f ${1##*/} $2
    wget -q --show-progress -N $1
    bsdcat ${1##*/} | gzip - > $2
    rm ${1##*/}
  fi
}

for PACKAGE in $PACKAGES
do
  PKG=$(getfield $PACKAGE Package)
  VER=$(getfield $PACKAGE Version)
  BASEVER=$(echo $VER | cut -d- -f1)
  SUFFIX=$(echo $VER | cut -d- -f2)
  REPO=$(getfield $PACKAGE Repo)
  FILENAME=$(getfield $PACKAGE Tarname)
  if [ -z "$FILENAME" ]
  then
    FILENAME='${PKG}-${BASEVER}.tar.gz'
  else
    RENAME="${PKG}-${BASEVER}.tar.gz"
  fi
  LINK=$(echo $REPO$FILENAME | sed -e "s/\${PKG}/$PKG/g" -e "s/\${VER}/$VER/g" -e "s/\${BASEVER}/$BASEVER/g" -e "s/\${SUFFIX}/$SUFFIX/g")

  if [ "$PACKAGE" != "$PKG" ]
  then
    echo Package name mismatch: "$PACKAGE" != "$PKG"
  fi

  if [ -z "$REPO" ]
  then
    echo "$PKG" has no external source
  else
    download $LINK $RENAME
  fi

  unset PKG VER BASEVER SUFFIX REPO FILENAME RENAME LINK
done
