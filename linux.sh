#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PET_NAME="bubuyier-ref"
SOURCE_DIR="${SCRIPT_DIR}/pets/${PET_NAME}/codex-v2"
TARGET_DIR="${HOME}/.codex/pets/${PET_NAME}"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Pet folder not found: $SOURCE_DIR" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"
cp "${SOURCE_DIR}/pet.json" "${TARGET_DIR}/pet.json"
cp "${SOURCE_DIR}/spritesheet.png" "${TARGET_DIR}/spritesheet.png"

echo "Installed ${PET_NAME} to ${TARGET_DIR}"
echo "Restart Codex or refresh the pet picker if it is already open."
