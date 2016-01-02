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

VIEWS=()
for(( i=0; $i < 8; i++ )); do
    VIEWS[i]=$(cat "art/${i}.txt")
done

draw() {
    x=0
    DIR_L=$[DIR-1]
    DIR_R=$[DIR+1]
    [ $DIR_L -lt 0 ] && DIR_L=$[DIR_L+4]
    [ $DIR_R -gt 3 ] && DIR_R=$[DIR_R-4]
    [ "$(signAt $[PL_X+DX[DIR_L]] $[PL_Y+DY[DIR_L]])" = "$CH_FREE" ] && x=$[x|1]
    [ "$(signAt $[PL_X+DX[DIR]] $[PL_Y+DY[DIR]])" = "$CH_FREE" ]     && x=$[x|2]
    [ "$(signAt $[PL_X+DX[DIR_R]] $[PL_Y+DY[DIR_R]])" = "$CH_FREE" ] && x=$[x|4]
    printf "%s\n" "${VIEWS[$x]}"
}

# 13x5
minimap() {
    i=$[PL_X-2]
    x=5
    while [ $i -lt 0 ]; do
        echo "             "
        ((i++))
        ((x--))
    done
    L_sp=""
    R_sp=""
    l=$[PL_Y-6]
    r=$[PL_Y+6]
    while [ $l -lt 0 ]; do
        L_sp+=" "
        ((l++))
    done
    while [ $r -gt $T_COLS ]; do
        R_sp+=" "
        ((r--))
    done
    while [ $x -gt 0 ] && [ $i -lt $T_ROWS ]; do
        printf "$L_sp"
        for(( t=$l; $t < r; t++ )); do
            if [ $t -eq $PL_Y ] && [ $i -eq $PL_X ]; then
                printf "${CH_PL[DIR]}"
            else
                signAt $i $t
            fi
        done
        echo "$R_sp"
        ((i++))
        ((x--))
    done
    while [ $x -gt 0 ]; do
        echo "             "
        ((x--))
    done
}

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
    draw
    printmaze
    minimap
done

