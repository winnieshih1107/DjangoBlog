#!/usr/bin/env bash
# =====================================================================
# Configuration Parameters for Database Download
# =====================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# https://drive.google.com/file/d/1cROzhq6EGBWUbmRp8heBWnrso0009hYh/view?usp=sharing
# Google Drive File ID for db.sqlite3
FILE_ID="1cROzhq6EGBWUbmRp8heBWnrso0009hYh"

# Local path where the database will be saved
DB_PATH="$SCRIPT_DIR/db.sqlite3"

# Direct download link constructed from FILE_ID
DOWNLOAD_URL="https://drive.google.com/uc?export=download&id=${FILE_ID}"

GIT_USER_NAME="winnie"
GIT_USER_EMAIL="winnieshih1107@gmail.com"
