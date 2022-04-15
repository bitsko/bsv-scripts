#!/bin/bash
if [[ -p "/dev/stdin" ]]; then
        arrayHash="$(cat)"
else
        arrayHash="$1"
        if [[ -z "$1" ]]; then
                echo "provide a txid as \$1"
                exit 1
        fi
fi
asmtx(){ node<<<"let bsv = require('bsv'); var script = bsv.Script.fromHex('$(curl -s --location --request GET  https://api.whatsonchain.com/v1/bsv/main/tx/"$arrayHash"/out/0/hex)');console.log(script.toAsmString())" | sed 's/ /\n/g'; }
arrayFile=$(asmtx)
if [ $? -ne 0 ]; then
        printf '%s' "cant connect to api"
        exit 1
fi
line=1
while read f; do
        printf '%s\n' "line $line hex : $f"
        text=$(xxd -r -p<<<"$f" | strings)
        if [[ -n "$text" ]]; then
                printf '%s\n' "line $line text: $text"
        fi
        line=$((line + 1))
done<<<"$arrayFile"
printf "\n"
