#!/bin/sh

>x

N=${1:-10}

for i in `seq $N`; do
        n --headless --startuptime x +q
done

echo $(echo "($(grep editing.files.in.windows x|cut -f1 -d' '|paste -s -d+))/$N"|bc)ms avg. over $N runs

rm x
