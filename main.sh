#!/bin/bash

ROWS_OLD=$(tput lines)
COLS_OLD=$(tput cols)

printf "\e[8;22;39t"

. maze.sh

setmaze 20 50
genmaze

signAt() {
    printf "${maze[$1*$T_COLS+$2]}"
}

MINIMAP=1
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

IFS=$'\n'

startScreen() {
    clear
    tput cup 1 12
    tput setaf 6
    printf "L A B I R Y N T"
    tput cup 3 2
    tput setaf 4
    printf "ZASADY GRY"
    tput cup 5 4
    tput setaf 3
    printf "Kieruj się w stronę wyjścia!"
    tput cup 6 5
    printf "(prawy górny róg)"
    tput cup 8 2
    tput setaf 4
    printf "STEROWANIE"
    tput cup 10 4
    tput setaf 2
    printf "strzałki/hjkl"
    tput cup 11 5
    tput setaf 3
    printf "poruszanie się po labiryncie"
    tput cup 13 4
    tput setaf 2
    printf "m"
    tput cup 14 5
    tput setaf 3
    printf "przełącza minimapę"
    tput cup 16 4
    tput setaf 2
    printf "q"
    tput cup 17 5
    tput setaf 3
    printf "wyjście z gry"

    tput cup 20 2
    tput setaf 4
    printf "NACIŚNIJ DOWOLNY KLAWISZ"
    read -n 1
}

draw() {
    x=0
    DIR_L=$[DIR-1]
    DIR_R=$[DIR+1]
    [ $DIR_L -lt 0 ] && DIR_L=$[DIR_L+4]
    [ $DIR_R -gt 3 ] && DIR_R=$[DIR_R-4]
    [ "$(signAt $[PL_X+DX[DIR_L]] $[PL_Y+DY[DIR_L]])" != "$(printf $CH_WALL)" ] && x=$[x|1]
    [ "$(signAt $[PL_X+DX[DIR]] $[PL_Y+DY[DIR]])" != "$(printf $CH_WALL)" ]     && x=$[x|2]
    [ "$(signAt $[PL_X+DX[DIR_R]] $[PL_Y+DY[DIR_R]])" != "$(printf $CH_WALL)" ] && x=$[x|4]
    if [ $MINIMAP -ne 0 ]; then
        VIEW=(${VIEWS[x]})
        MAP=($(minimap))
        printf "%s\n" "${VIEWS[$x]}" | head -14
        printf "%s+-------------+%s\n" ${VIEW[14]:0:12} ${VIEW[14]:27:12}
        for ((i=0; $i < 5 ;i++)); do
            printf "%s|\e[33m%s\e[34m|%s\n" ${VIEW[i+15]:0:12} ${MAP[i]} ${VIEW[i+15]:27:12}
        done
    else
        echo "${VIEWS[$x]}"
    fi
    echo   "+-----------+-------------+-----------+"
    [ $MINIMAP -eq 0 ] && printf "   Kierunek: ${CH_PL[DIR]}\r" 
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
    r=$[PL_Y+7]
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

updateRanking() {
    [ ! -f ranking.db ] && touch ranking.db
    scores=($(cat ranking.db | base64 --decode))
    ask=0
    lastScore=$(echo ${scores[9]} | cut -d ';' -f 1)
    if [ -z "$lastScore" ] || [ "$lastScore" -gt "$1" ]; then
        echo "Świetny wynik! Podaj swoje imię: "
        read name
        name=$(echo $name | sed 's/;//g')
        scores+=("$1;$name;$(date +'%d-%m-%Y %R')")
        sortedScores=($(printf '%s\n' ${scores[@]} | sort -ns))
        printf '%s\n' ${sortedScores[@]} | head -10 | base64 > ranking.db
    fi
    S=($(cat ranking.db | base64 --decode))
    echo ${#S[@]}
    echo "+-------+----------------------+----------------------+"
    for line in ${S[@]}; do
        tmp=($(echo $line | sed 's/;/\n/g'))
        printf "| %5ss| %-20s | %-20s |\n" ${tmp[0]} ${tmp[1]:0:20} ${tmp[2]:0:20}
    done
    echo "+-------+----------------------+----------------------+"
}

startScreen
draw
startTime=$(date +%s)
moves=0
while read -sn 1 key; do
    if [ $key = '[' ]; then
        read -sn 1 tmp
        case $tmp in
            A) key='k' ;;
            B) key='j' ;;
            C) key='l' ;;
            D) key='h' ;;
        esac
    fi
    NEWDIR=-1
    case $key in
        h|H) NEWDIR=3 ;;
        j|J) NEWDIR=2 ;;
        k|K) NEWDIR=0 ;;
        l|L) NEWDIR=1 ;;
        m|M) MINIMAP=$[1-MINIMAP] ;;
        q|Q)
            #printf "\e[8;%d;%dt" $[T_ROWS+3] $T_COLS
            printf "\e[8;%d;%dt" $ROWS_OLD $COLS_OLD
            clear
            tput sgr0
            printmaze
            echo "Przegrana"
            echo "Liczba ruchow: $moves"
            exit 0
            ;;
    esac
    if [ $NEWDIR -ge 0 ]; then
        if [ $NEWDIR -ne 2 ]; then
            DIR=$[$[DIR+NEWDIR]%4]
            NEWDIR=$DIR
        else
            NEWDIR=$[$[DIR+2]%4]
        fi
        if [ "$(signAt $[PL_X+DX[NEWDIR]] $[PL_Y+DY[NEWDIR]])" != "$(printf $CH_WALL)" ]; then
            ((moves++))
            maze[PL_X*T_COLS+PL_Y]='.'
            PL_X=$[PL_X+DX[NEWDIR]]
            PL_Y=$[PL_Y+DY[NEWDIR]]
        fi
        if [ $PL_X -eq 1 ] && [ $PL_Y -eq $[T_COLS-1] ]; then
            #printf "\e[8;%d;%dt" $[T_ROWS+3] $T_COLS
            TIME=$[$(date +%s)-startTime]
            printf "\e[8;%d;%dt" $ROWS_OLD $COLS_OLD
            clear
            tput sgr0
            printmaze
            echo "Wygrana!"
            echo "Labirynt pokonano w ${moves} ruchach."
            echo "Czas: ${TIME}s"
            updateRanking $TIME
            exit 0
        fi
    fi
    draw
    #printmaze
    #minimap
done

