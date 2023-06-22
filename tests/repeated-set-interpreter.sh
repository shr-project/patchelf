#! /bin/sh -e

SCRATCH=scratch/$(basename "$0" .sh)
PATCHELF=$(readlink -f "../src/patchelf")
READELF=${READELF:-readelf}

rm -rf "${SCRATCH}"
mkdir -p "${SCRATCH}"

cp mkfs.ext4 "${SCRATCH}/"

cd "${SCRATCH}"

###############################################################################
# Test that repeatedly modifying a string inside a shared library does not
# corrupt it due to the addition of multiple PT_LOAD entries
###############################################################################
load_segments_before=$(${READELF} -W -l mkfs.ext4 | grep -c LOAD)

for i in $(seq 1 100)
do
    ${PATCHELF} --set-interpreter $(pwd)/iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii mkfs.ext4
    ldd mkfs.ext4 || { echo "ldd failed after $i --set-interpreter iterations"; exit 2; }
    ${PATCHELF} --set-interpreter /short mkfs.ext4
    ldd mkfs.ext4 || { echo "ldd failed after $i --set-interpreter iterations"; exit 2; }
done

load_segments_after=$(${READELF} -W -l mkfs.ext4 | grep -c LOAD)

###############################################################################
# To be even more strict, check that we don't add too many extra LOAD entries
###############################################################################
echo "Segments before: ${load_segments_before} and after: ${load_segments_after}"
if [ "${load_segments_after}" -gt $((load_segments_before + 2)) ]
then
    exit 1
fi
