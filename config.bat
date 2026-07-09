@echo off
:: =====================================================================
:: Configuration Parameters for Database Download
:: =====================================================================

::https://drive.google.com/file/d/1cROzhq6EGBWUbmRp8heBWnrso0009hYh/view?usp=sharing
:: Google Drive File ID for db.sqlite3
set "FILE_ID=1cROzhq6EGBWUbmRp8heBWnrso0009hYh"

:: Local path where the database will be saved
set "DB_PATH=%~dp0db.sqlite3"

:: Direct download link constructed from FILE_ID
set "DOWNLOAD_URL=https://drive.google.com/uc?export=download&id=%FILE_ID%"

set "GIT_USER_NAME=winnie"
set "GIT_USER_EMAIL=winnieshih1107@gmail.com"
