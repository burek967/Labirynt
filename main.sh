#!/bin/bash

. maze.sh

setmaze 20 50
genmaze

signAt() {
    printf "${maze[$1*$T_COLS+$2]}"
}

MINIMAP=0
PL_X=$[$T_ROWS-2]
PL_Y=1

# up,right,down,left
DX=(-1 0 1  0)
DY=(0  1 0 -1)
CH_PL=("\u25B2" "\u25B6" "\u25BC" "\u25C0")
DIR=0
[ "$(signAt $PL_X 2)" = "$CH_FREE" ] && DIR=1

printmaze
while read -sn 1 key; do
    case $key in
        k|K) echo "UPARR"
            if [ "$(signAt $[PL_X+DX[DIR]] $[PL_Y+DY[DIR]])" = "$CH_FREE" ]; then
                PL_X=$[PL_X+DX[DIR]]
                PL_Y=$[PL_Y+DY[DIR]]
            fi
            ;;
        j|J) echo "DNARR"
            DIR=$[DIR-2]
            [ $DIR -lt 0 ] && DIR=$[DIR+4]
            ;;
        h|H) echo "LTARR"
            DIR=$[DIR-1]
            [ $DIR -lt 0 ] && DIR=$[DIR+4]
            ;;
        l|L) echo "RTARR"
            DIR=$[DIR+1]
            [ $DIR -gt 3 ] && DIR=$[DIR-4]
            ;;
    esac
    printmaze
done

