#!/usr/bin/env bash
set -e


function show_usage() {
  echo
  echo "  Usage: ${0} URL [ NAME ]"
  echo
}


URL=$1
CLEAN_FILENAME=$2


TMP_DIR=$(mktemp -d)

youtube-dl --output "${TMP_DIR}/%(title)s.%(ext)s" ${URL} --restrict-filenames

RAW_FILENAME=$(ls ${TMP_DIR})

CLEAN_FILENAME_EXT=$(echo "${RAW_FILENAME}" | sed "s/_/ /g")

if [[ -z "${CLEAN_FILENAME}" ]] ; then
	CLEAN_FILENAME=$(basename "${CLEAN_FILENAME_EXT}" .mp4)
	CLEAN_FILENAME=$(basename "${CLEAN_FILENAME}" .mkv)
fi


mkdir -p "${CLEAN_FILENAME}"
mv "${TMP_DIR}/${RAW_FILENAME}" "${CLEAN_FILENAME}/${CLEAN_FILENAME_EXT}"

echo "#MP3:${CLEAN_FILENAME}.mp3" > "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"
echo "#COVER:${CLEAN_FILENAME} [CO].png" >> "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"
echo "#VIDEO:${CLEAN_FILENAME_EXT}" >> "${CLEAN_FILENAME}/${CLEAN_FILENAME}.txt"

ffmpeg -y -i "${CLEAN_FILENAME}/${CLEAN_FILENAME_EXT}" -q:a 0 -map a "${CLEAN_FILENAME}/${CLEAN_FILENAME}.mp3"
sacad "${CLEAN_FILENAME}" "${CLEAN_FILENAME}" 600 "${CLEAN_FILENAME}/${CLEAN_FILENAME} [CO].png"

rm -rf "${TMP_DIR}"
