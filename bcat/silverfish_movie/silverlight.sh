#!/usr/bin/bash
[[ ! -d .bsv ]] && mkdir .bsv
if [ ! -d node_modules/bsv/ ]; then echo "installing BSV js library"
        npm i --prefix "$(pwd)" bsv --save ; fi
if [ $(npm list bsv | awk NR==2 | tr -dc '0-9' | cut -c 1) -eq "1" ]; then
        echo "bsvjs 1x installed, install bsvjs 2x instead"; exit 1; fi
if ! [ -x "$(command -v npm)" ]; then echo "install npm"; exit 1; fi
if ! [ -x "$(command -v xxd)" ]; then echo "install xxd"; exit 1; fi
if ! [ -x "$(command -v curl)" ]; then echo "install curl"; exit 1; fi
arrayHash=79437a613e31b828ed4cfaf97297b1b9f4d766f5cf548fcccd11059d1dc2b8e3
arrayFile=.bsv/"$arrayHash".voutAsm
file=silverfish.webm
siteToPing=taal.com
firstRun=0

netCheck(){
ping -c 1 "$siteToPing" &>/dev/null; if [ $? != 0 ]; then
        echo "cant ping $siteToPing, are you online?"; exit 1; fi
}
netCheck

if [[ -f "silverfish.webm" ]]; then
while true; do
    read -p "Previous download found. yes to resume the download, no to start a new download, or quit to quit."$'\n>' ynq
    case $ynq in
      [Yy]* ) echo "restarting download"; break;;
      [Nn]* ) echo "deleting prior silverfish.webm"
              rm silverfish.webm; rm "$arrayFile"; break;;
      [Qq]* ) exit 0;;
      * ) echo "Please answer yes no or quit.";;
    esac
done
fi
if [[ ! -f "$arrayFile" ]]; then
        firstRun=1
        asmtx=$(echo "let bsv = require('bsv'); var script = bsv.Script.fromHex(\
                '$(curl -s --location --request GET  "https://api.whatsonchain.com/v1/bsv/main/tx/$arrayHash/out/0/hex")'\
                ); console.log(script.toAsmString())" | node | sed 's/ /\n/g')
        if [ $? -ne 0 ];then echo "cant connect to api"; exit 1; fi
        echo "$asmtx" > "$arrayFile"
        echo "downloading tx array"
        sed -i 1,8d "$arrayFile"
fi
if [[ -f "$arrayFile" ]]; then
        declare -a voutAsm=( $(cat "$arrayFile") )
        if [[ "$firstRun" == 0 ]]; then echo "loading tx array from file"; fi
fi
while [[ -n "$arrayFile" ]]; do
        linesLeft=$(wc -l "$arrayFile" | awk '{ print $1 }')
        total=2233;
        count=$((total-linesLeft))
        if [[ "$count" == 2233 ]]; then echo "finished building $file" ; exit 0; fi
        nextHash=$(head -n 1 "$arrayFile")
        asmtx=$(echo "let bsv = require('bsv'); var script = bsv.Script.fromHex(\
                '$(curl -s --location --request GET  "https://api.whatsonchain.com/v1/bsv/main/tx/$nextHash/out/0/hex")'\
                ); console.log(script.toAsmString())" | node | sed 's/ /\n/g')
        if [ $? -ne 0 ]; then echo "problem downloading txVout"; netCheck; echo "idk"; exit 1; fi
        declare -a pvoutAsm=( $(echo "$asmtx") )
        echo "${pvoutAsm[3]}" | xxd -r -p >> "$file"
        stat=$(ls -hal "$file" | awk '{ print $5,$9 }')
        echo "$nextHash $stat $count of $total"
        sed -i 1d "$arrayFile"
done
