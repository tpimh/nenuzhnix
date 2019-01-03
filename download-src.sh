#!/bin/sh

PACKAGES=$(find . -maxdepth 2 -mindepth 2 -name 'opkg' -type d | sed 's/\.\/\(.*\)\/opkg/\1/')

getfield() {
  grep -e "^$2: " $1/opkg/control | sed 's/^'$2': \(.*\)$/\1/'
}

getsourcefield() {
  grep -e "^$2: " $1/opkg/source | sed 's/^'$2': \(.*\)$/\1/'
}

download() {
  if [ "$#" -eq 1 ]; then
    echo ${1##*/}
    curl -LSq --progress-bar -O $1
  elif [ ${1##*.} = gz ]; then
    echo $2
    rm -f ${1##*/}
    curl -LSq --progress-bar $1 -o $2
  else
    echo $2
    rm -f ${1##*/}
    curl -LSq --progress-bar -O $1
    bsdcat ${1##*/} | gzip -n - > $2
    rm ${1##*/}
  fi
}

for PACKAGE in $PACKAGES
do
  PKG=$(getfield $PACKAGE Package)
  VER=$(getfield $PACKAGE Version)
  BASEVER=$(echo $VER | cut -d- -f1)
  SUFFIX=$(echo $VER | cut -d- -f2)

  if [ "$PACKAGE" != "$PKG" ]
  then
    echo Package name mismatch: "$PACKAGE" != "$PKG"
  fi

  if [ -r "$PACKAGE/opkg/source" ]
  then
    REPO=$(getsourcefield $PACKAGE Repo)
    FILENAME=$(getsourcefield $PACKAGE Filename)
    if [ -z "$FILENAME" ]
    then
      FILENAME='${PKG}-${BASEVER}.tar.gz'
    else
      RENAME="${PKG}-${BASEVER}.tar.gz"
    fi
    LINK=$(echo $REPO$FILENAME | sed -e "s/\${PKG}/$PKG/g" -e "s/\${VER}/$VER/g" -e "s/\${BASEVER}/$BASEVER/g" -e "s/\${SUFFIX}/$SUFFIX/g")
    CHECKSUM=$(getsourcefield $PACKAGE MD5)

    if [ ! -z "$REPO" ]
    then
      if [ -e "${PKG}-${BASEVER}.tar.gz" ]
      then
        if [ "$CHECKSUM  ${PKG}-${BASEVER}.tar.gz" != "$(md5sum "${PKG}-${BASEVER}.tar.gz")" ]
        then
          echo Wrong checksum of tarball for $PKG
          rm "${PKG}-${BASEVER}.tar.gz"
        fi
      fi

      if [ ! -e "${PKG}-${BASEVER}.tar.gz" ]
      then
        download $LINK $RENAME
        if [ "$CHECKSUM  ${PKG}-${BASEVER}.tar.gz" != "$(md5sum "${PKG}-${BASEVER}.tar.gz")" ]
        then
          echo Downloaded tarball for $PKG has wrong checksum
        fi
      fi
    fi
  fi

  unset PKG VER BASEVER SUFFIX REPO FILENAME RENAME LINK CHECKSUM
done
