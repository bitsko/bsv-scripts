#!/bin/bash
[[ -z $(command -v tput) ]] && echo "requires tput" && exit 1
red=$(tput setaf 1)
white=$(tput setaf 7)
blue=$(tput setaf 4)
normal=$(tput sgr0)
green=$(tput setaf 2)
if [[ -p "/dev/stdin" ]]; then
        arrayHash="$(cat)"
else
        arrayHash="$1"
        if [[ -z "$1" ]]; then
                printf '%s\n' "${red}provide a txid as \$1${normal}"
                exit 1
        fi
fi

if [[ $(wc -m<<<"$arrayHash") -ne 65 ]]; then printf '%s\n' "${red}input not 64 characters${normal}"; exit 1; fi

asmtx(){ node<<<"let bsv = require('bsv'); var script = bsv.Script.fromHex('$(curl -s --location --request GET  https://api.whatsonchain.com/v1/bsv/main/tx/"$arrayHash"/out/0/hex)');console.log(script.toAsmString())" | sed 's/ /\n/g'; }
arrayFile=$(asmtx)
if [ $? -ne 0 ]; then
        printf '%s\n' "${red}cant connect to api${normal}"
        exit 1
fi
line=1
echo "${BRIGHT}------txid: $arrayHash${normal}"
while read f; do
        printf '%s\n' "${white}pos-$line-hex-: ${blue}$f${normal}"
        text=$(xxd -r -p<<<"$f" | strings)
        if [[ -n "$text" ]]; then
                printf '%s\n' "${white}pos-$line-${BRIGHT}text: ${green}$text${normal}"
        fi
        line=$((line + 1))
done<<<"$arrayFile"
printf "\n"
