#!/bin/sh
set -e
cd /data
if [ ! -f MCGalaxyCLI.exe ]; then
  cp -r /opt/mcgalaxy/. /data/
fi
exec mono MCGalaxyCLI.exe
