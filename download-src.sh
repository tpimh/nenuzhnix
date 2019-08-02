#!/bin/sh

PACKAGES=$(find . -maxdepth 2 -mindepth 2 -name 'opkg' -type d | sed 's/\.\/\(.*\)\/opkg/\1/')

getfield() {
  grep -e "^$2: " $1/opkg/control | sed 's/^'$2': \(.*\)$/\1/'
}

getsourcefield() {
  grep -e "^$2: " $1/opkg/source | sed 's/^'$2': \(.*\)$/\1/'
}

download() {
  EXTNAME="${1##*/}"
  if [ "$EXTNAME" = "$2" ]
  then
    echo "${EXTNAME}"
    curl -LSq --progress-bar -O $1
  else
    echo "$EXTNAME -> $2"
    rm -f "${EXTNAME}"
    curl -LSq --progress-bar $1 -o $2
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
      EXT=gz
      FILENAME="${PKG}-${BASEVER}.tar.${EXT}"
      RENAME="$FILENAME"
    else
      EXT=$(echo $FILENAME | sed 's/^.*\.//')
      RENAME="${PKG}-${BASEVER}.tar.${EXT}"
    fi
    LINK=$(echo $REPO$FILENAME | sed -e "s/\${PKG}/$PKG/g" -e "s/\${VER}/$VER/g" -e "s/\${BASEVER}/$BASEVER/g" -e "s/\${SUFFIX}/$SUFFIX/g")
    CHECKSUM=$(getsourcefield $PACKAGE MD5)

    if [ ! -z "$REPO" ]
    then
      if [ -e "$RENAME" ]
      then
        if [ "$CHECKSUM  ${RENAME}" != "$(md5sum ${RENAME})" ]
        then
          echo Wrong checksum of tarball for $PKG
          rm "${RENAME}"
        fi
      fi

      if [ ! -e "${RENAME}" ]
      then
        download $LINK $RENAME
        if [ "$CHECKSUM  ${RENAME}" != "$(md5sum ${RENAME})" ]
        then
          echo Downloaded tarball for $PKG has wrong checksum
        fi
      fi
    fi
  fi

  unset PKG VER BASEVER SUFFIX REPO FILENAME EXT RENAME LINK CHECKSUM
done
