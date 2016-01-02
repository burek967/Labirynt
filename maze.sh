#!/bin/bash
# Simple maze generating script using randomized DFS.

CH_WALL='\u2588'  # '█'
#CH_FREE='\xA0'    # ' '
CH_FREE=' '
CH_PATH='+'

T_ROWS=25
T_COLS=25
maze=()

# Usage: setmaze [ROWS [COLUMNS]]
setmaze() {
    T_ROWS=$1
    T_COLS=$2
    [ -z $T_ROWS ] && T_ROWS=25
    [ -z $T_COLS ] && T_COLS=25
    # We want both dimensions to be odd
    [ $[$T_ROWS % 2] -eq 0 ] && ((T_ROWS++))
    [ $[$T_COLS % 2] -eq 0 ] && ((T_COLS++))
    T_SIZE=$[$T_ROWS*$T_COLS]
    maze=()
    for(( i=0 ; $i < $T_SIZE ; i++ )); do
        maze[$i]=$CH_WALL
    done
    maze[2*$T_COLS-1]=$CH_FREE
}

#printf '\e[8;%s;%st' $[$T_ROWS+1] $T_COLS

# Usage: genmaze
genmaze() {
    local V1=$1
    local V2=$2
    [ -z $1 ] && V1=$[$T_ROWS-2]
    [ -z $2 ] && V2=1
    maze[$T_COLS*$V1+$V2]=$CH_FREE
    local neighbors=()
    [ $V2 -gt 1 ]            && neighbors+=($V1 $[$V2-2])
    [ $[$V2+2] -lt $T_COLS ] && neighbors+=($V1 $[$V2+2])
    [ $V1 -gt 1 ]            && neighbors+=($[$V1-2] $V2)
    [ $[$V1+2] -lt $T_ROWS ] && neighbors+=($[$V1+2] $V2)
    
    # Visit neighbouring vertices in random order
    local tmp=$(seq 0 $[(${#neighbors[*]})/2-1] | shuf)
    for i in $tmp; do
        x=${neighbors[2*$i]}
        y=${neighbors[2*$i+1]}
        [ "${maze[$T_COLS*$x+$y]}" == "$CH_FREE" ] && continue
        maze[$T_COLS*($V1+$x)/2+($y+$V2)/2]=$CH_FREE
        genmaze $x $y
    done
}

# Usage: solve X Y
# X,Y - starting point coordinates
solve() {
    maze[$T_COLS*$1+$2]="$CH_PATH"
    if [ $[$1*$T_COLS+$2] -eq $[2*$T_COLS-2] ]; then
        maze[2*$T_COLS-1]="$CH_PATH"
        return 1
    fi
    local neighbors=()
    [ $2 -gt 1 ]            && [ "${maze[$T_COLS*$1+$2-1]}" = "$CH_FREE" ]   && neighbors+=($1 $[$2-2])
    [ $[$2+2] -lt $T_COLS ] && [ "${maze[$T_COLS*$1+$2+1]}" = "$CH_FREE" ]   && neighbors+=($1 $[$2+2])
    [ $1 -gt 1 ]            && [ "${maze[$T_COLS*($1-1)+$2]}" = "$CH_FREE" ] && neighbors+=($[$1-2] $2)
    [ $[$1+2] -lt $T_ROWS ] && [ "${maze[$T_COLS*($1+1)+$2]}" = "$CH_FREE" ] && neighbors+=($[$1+2] $2)
    tmp=$(seq 0 $[(${#neighbors[*]})/2-1])
    for i in $tmp; do
        local x=${neighbors[2*$i]}
        local y=${neighbors[2*$i+1]}
        maze[$T_COLS*($1+$x)/2+($y+$2)/2]="$CH_PATH"
        solve $x $y
        [ $? -eq 1 ] && return 1
        maze[$T_COLS*($1+$x)/2+($y+$2)/2]="$CH_FREE"
    done
    maze[$T_COLS*$1+$2]="$CH_FREE"
    return 0
}

# Usage: printmaze
printmaze() {
    local t=0
    for(( i=0; $i < $T_ROWS; i++ )); do
        for(( j=0; $j < $T_COLS; j++ )); do
            if [ $t -eq $[$PL_X*$T_COLS+$PL_Y] ]; then
                printf "${CH_PL[DIR]}"
            else
                printf "${maze[$t]}"
            fi
            ((t++))
        done
        printf '\n'
    done
}

# todo: bfs do późniejszego użycia przy wskazówkach

#setmaze 20 50
#genmaze
#solve $[$T_ROWS-2] 1
#printmaze
