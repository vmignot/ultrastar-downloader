#!/usr/bin/env bash
set -e


function show_usage() {
  echo
  echo "  Usage: ${0} URL"
  echo
}


URL=$1
DIR_NAME=$2


TMP_DIR=$(mktemp -d)

youtube-dl --output "${TMP_DIR}/%(title)s.%(ext)s" ${URL} --restrict-filenames

RAW_FILENAME=$(ls ${TMP_DIR})

CLEAN_FILENAME_EXT=$(echo "${RAW_FILENAME}" | sed "s/_/ /g")

CLEAN_FILENAME=$(basename "${CLEAN_FILENAME_EXT}" .mp4)
CLEAN_FILENAME=$(basename "${CLEAN_FILENAME}" .mkv)

mkdir -p "${CLEAN_FILENAME}"
mv "${TMP_DIR}/${RAW_FILENAME}" "${CLEAN_FILENAME}/${CLEAN_FILENAME_EXT}"

ffmpeg -y -i "${CLEAN_FILENAME}/${CLEAN_FILENAME_EXT}" -q:a 0 -map a "${CLEAN_FILENAME}/${CLEAN_FILENAME}.mp3"
sacad 


echo "#MP3:${CLEAN_FILENAME}.mp3" > "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"
echo "#VIDEO:${CLEAN_FILENAME_EXT}" >> "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"


