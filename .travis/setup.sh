#!/bin/bash
case "$FFMPEG_VERSION" in
    2.3)
        sudo add-apt-repository ppa:archivematica/externals -y
        sudo apt-get update -q
        sudo apt-get install ffmpeg fluxbox
        ;;

    1.2)
        stop
        ;;
    *)
        sudo apt-get update -q
        sudo apt-get install ffmpeg fluxbox
esac