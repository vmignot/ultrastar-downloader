#!/usr/bin/env bash
set -e


function show_usage() {
  echo
  echo "  Usage: ${0} URL [ NAME ]"
  echo
  echo "Dependencies:"
  echo "  - youtube-downloader"
  echo "  - sacad"
  echo "  - html-xml-utils"
  echo 
  echo "Env vars:"
  echo "  - USDB_ANIMUX_DE_USERNAME"
  echo "  - USDB_ANIMUX_DE_PASSWORD"
}

if [[ $# -eq 0 ]]; then
  show_usage
  exit 0
fi

URL=$1
CLEAN_FILENAME=$2


TMP_DIR=$(mktemp -d)
echo "TMP_DIR: ${TMP_DIR}"

## Download video on tmp dir, and move it in local dir with cleaned name
youtube-dl --output "${TMP_DIR}/%(title)s.%(ext)s" ${URL} --restrict-filenames

RAW_FILENAME=$(ls ${TMP_DIR})

CLEAN_FILENAME_EXT=$(echo "${RAW_FILENAME}" | sed "s/_/ /g")

if [[ -z "${CLEAN_FILENAME}" ]] ; then
  CLEAN_FILENAME=$(basename "${CLEAN_FILENAME_EXT}" .mp4)
  CLEAN_FILENAME=$(basename "${CLEAN_FILENAME}" .mkv)
fi


mkdir -p "${CLEAN_FILENAME}"
mv "${TMP_DIR}/${RAW_FILENAME}" "${CLEAN_FILENAME}/${CLEAN_FILENAME_EXT}"

## Extract artist / title from name
IFS='-'; SPLITTED=(${CLEAN_FILENAME}); unset IFS;

ARTIST="$(echo -e "${SPLITTED[0]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
TITLE="$(echo -e "${SPLITTED[1]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

touch "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"

## If USDB credentials are set, download first match
if [[ -n ${USDB_ANIMUX_DE_USERNAME}  ]]; then
  ## Auth and save cookie
  curl -c "${TMP_DIR}/cookie.txt" -XPOST http://usdb.animux.de/\?\&link\=login -d "user=${USDB_ANIMUX_DE_USERNAME}&pass=${USDB_ANIMUX_DE_PASSWORD}&remember=1&login=Login"

  ## Get ID of first match
  ID=$(curl -b "@${TMP_DIR}/cookie.txt" -XPOST http://usdb.animux.de/?link=list -d "interpret=${ARTIST// /+}&title=${TITLE// /+}" | hxnormalize -x | hxselect 'tr.list_tr2>td' | awk -F'[()]' '{print $2}')

  TXT=$(curl -b "@${TMP_DIR}/cookie.txt" -XPOST "http://usdb.animux.de/?link=gettxt&id=${ID}" -d "wd=1" | hxnormalize -x | hxselect -c "textarea[name=txt]") 
  echo "${TXT}" > "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"
fi

rm -rf "${TMP_DIR}"

## Add more info
echo "#MP3:${CLEAN_FILENAME}.mp3" | cat - "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt" > temp && mv temp "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"
echo "#COVER:${CLEAN_FILENAME} [CO].png" | cat - "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt" > temp && mv temp "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"
echo "#VIDEO:${CLEAN_FILENAME_EXT}" | cat - "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt" > temp && mv temp "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"
#sed -i "1i#MP3:${CLEAN_FILENAME}.mp3"        "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"
#sed -i "1i#COVER:${CLEAN_FILENAME} [CO].png" "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"
#sed -i "1i#VIDEO:${CLEAN_FILENAME_EXT}"      "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"

## Get MP3 from file
ffmpeg -y -i "${CLEAN_FILENAME}/${CLEAN_FILENAME_EXT}" -q:a 0 -map a "${CLEAN_FILENAME}/${CLEAN_FILENAME}.mp3"

## Get cover
sacad "${ARTIST}" "${TITLE}" 800 "${CLEAN_FILENAME}/${CLEAN_FILENAME} [CO].png"

