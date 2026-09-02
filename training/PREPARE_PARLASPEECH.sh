#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace/DubLabSRB"
DATA="$ROOT/ParlaSpeech"
ARCHIVES="$DATA/archives"
SOURCE="$DATA/source"

mkdir -p "$ARCHIVES" "$SOURCE"

PART1_URL="https://www.clarin.si/repository/xmlui/bitstream/handle/11356/1834/ParlaSpeech-RS.v1.0.part1.tgz?isAllowed=y&sequence=2"
PART2_URL="https://www.clarin.si/repository/xmlui/bitstream/handle/11356/1834/ParlaSpeech-RS.v1.0.part2.tgz?isAllowed=y&sequence=3"

PART1_MD5="83ff0608114a8c2701f712112ce88f03"
PART2_MD5="628efb94708a9e10d02fd825ac853a4c"

download_extract () {
    NAME="$1"
    URL="$2"
    EXPECTED_MD5="$3"

    FILE="$ARCHIVES/$NAME"
    MARKER="$SOURCE/.${NAME}.extracted.ok"

    echo
    echo "========================================"
    echo "Preparing $NAME"
    echo "========================================"

    if [ -f "$MARKER" ]; then
        echo "Already extracted successfully."
        echo "Marker: $MARKER"
        rm -f "$FILE"
        return 0
    fi

    if [ -f "$FILE" ]; then
        echo "Existing archive found."
        echo "Checking existing MD5..."

        ACTUAL_MD5="$(md5sum "$FILE" | awk '{print $1}')"

        if [ "$ACTUAL_MD5" = "$EXPECTED_MD5" ]; then
            echo "Archive is already complete."
            echo "Download skipped."
        else
            echo "Archive is incomplete or differs from expected."
            echo "Resuming download..."

            curl -L \
                --fail \
                --retry 10 \
                --retry-delay 10 \
                --continue-at - \
                "$URL" \
                -o "$FILE"
        fi
    else
        echo "Archive not found."
        echo "Starting download..."

        curl -L \
            --fail \
            --retry 10 \
            --retry-delay 10 \
            --continue-at - \
            "$URL" \
            -o "$FILE"
    fi

    echo
    echo "Checking final MD5..."

    ACTUAL_MD5="$(md5sum "$FILE" | awk '{print $1}')"

    if [ "$ACTUAL_MD5" != "$EXPECTED_MD5" ]; then
        echo "ERROR: MD5 mismatch!"
        echo "Expected: $EXPECTED_MD5"
        echo "Actual:   $ACTUAL_MD5"
        echo "Archive kept for diagnosis/resume: $FILE"
        exit 1
    fi

    echo "MD5: OK"

    echo
    echo "Extracting..."

    tar -xzf "$FILE" -C "$SOURCE"

    touch "$MARKER"

    echo "Extraction: OK"
    echo "Marker created: $MARKER"

    echo
    echo "Deleting archive to save disk space..."

    rm -f "$FILE"

    echo
    echo "Disk status:"
    df -h /workspace
}

download_extract \
    "ParlaSpeech-RS.v1.0.part1.tgz" \
    "$PART1_URL" \
    "$PART1_MD5"

download_extract \
    "ParlaSpeech-RS.v1.0.part2.tgz" \
    "$PART2_URL" \
    "$PART2_MD5"

echo
echo "========================================"
echo "ParlaSpeech audio extracted"
echo "========================================"

echo -n "FLAC files found: "
find "$SOURCE" -type f -iname '*.flac' | wc -l

echo
du -sh "$SOURCE"
df -h /workspace
