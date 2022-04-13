#!/usr/bin/bash
#bash bcat retriever
if [ ! -d node_modules/bsv/ ]; then echo "installing BSV js library"; npm i --prefix "$(pwd)" bsv --save ; fi
if [ $(npm list bsv | awk NR==2 | tr -dc '0-9' | cut -c 1) -eq "1" ]; then echo "bsvjs 1x installed, needs bsvjs 2x"; exit 1; fi
if ! [ -x "$(command -v npm)" ]; then echo "install npm"; exit 1; fi
if ! [ -x "$(command -v xxd)" ]; then echo "install xxd"; exit 1; fi
if ! [ -x "$(command -v curl)" ]; then echo "install curl"; exit 1; fi
arrayHash="$1"; if [[ -z "$1" ]]; then echo "provide a txid as \$1"; exit 1; fi
siteToPing=taal.com; arrayFile=".$arrayHash".voutAsm; infofile="$arrayFile".tmp; firstRun=0; firstRun1=0; resumeNo=0
netCheck(){ ping -c 1 "$siteToPing" &>/dev/null; if [ $? != 0 ]; then echo "cant ping $siteToPing, are you online?"; exit 1; fi }
asmtx(){ echo -n "let bsv = require('bsv'); var script = bsv.Script.fromHex('$(curl -s --location --request GET  "https://api.whatsonchain.com/v1/bsv/main/tx/$arrayHash/out/0/hex")'); console.log(script.toAsmString())" | node | sed 's/ /\n/g'
} ; netCheck
suffFunc(){ if [[ -x "$(command -v exiftool)" ]] && [[ -x "$(command -v grep)" ]]; then
        Suff=$(exiftool "$file" | grep "File Type Extension" | awk '{ print $5 }')
        if [[ $(echo "$file" | rev | cut -c -3 | rev) != "$Suff" ]] && [[ -n "$Suff" ]] &&
        [[ "$file" != *"."* ]]; then mv "$file" "$file.$Suff"; file="$file.$Suff"; echo "$file"; fi; fi }
fname(){ awkF=$(awk '{if(NR==7) print $0}' "$infofile")
        if [[ -n "$awkF" ]]; then file=$( echo "$awkF" | sed 's/ //g;s/-//g;s/://g'); else file=file"$1"; fi }
if [[ -f "$arrayFile" ]]; then while true; do
        read -p "Previous download found. yes to resume the download, no to start a new download, or quit to quit."$'\n>' ynq
        case $ynq in
                [Yy]* ) echo "restarting download"; break;;
                [Nn]* ) rm "$arrayFile"; rm "$infofile"; resumeNo=1; break;;
                [Qq]* ) exit 0;;
                * ) echo "Please answer yes no or quit.";;
        esac; done; fi
if [[ ! -f "$arrayFile" ]]; then firstRun=1; firstRun1=1
        asmtx > "$arrayFile" && echo "downloading tx array"
        if [ $? -ne 0 ];then echo "cant connect to api"; exit 1; fi
        for f in $(head -n 8 "$arrayFile"); do printf "$f" | xxd -r -p >> "$infofile"; echo "" >> "$infofile"; done
        fname; if [[ "$resumeNo" == 1 ]]; then rm "$file"; fi
        if [[ $(head -n 1 "$arrayFile") == 0 ]]; then sed -i 1,8d "$arrayFile"; else sed -i 1,7d "$arrayFile"; fi
        echo $(wc -l "$arrayFile" | awk '{ print $1 }') >> "$infofile"; fi
if [[ -f "$arrayFile" ]]; then declare -a voutAsm=( $(cat "$arrayFile") )
        if [[ "$firstRun" == 0 ]]; then echo "loading tx array from file"; fi; fi
head -n 8 "$infofile"
total=$(wc -l "$arrayFile" | awk '{ print $1 }')
grandTotal=$(tail -n 1 "$infofile")
while [[ -n "$arrayFile" ]]; do
        if [[ -s "$arrayFile" ]]; then linesLeft=$(wc -l "$arrayFile" | awk '{ print $1 }')
        else suffFunc; echo "finished building $file"; if [[ ! -s "$arrayFile" ]]; then
                rm "$arrayFile"; if [[ -f "$infofile" ]]; then rm "$infofile" ;fi; exit 0; fi; fi
        count=$((total-linesLeft))
        arrayHash=$(head -n 1 "$arrayFile")
        declare -a pvoutAsm=( $(asmtx) )
        if [ $? -ne 0 ]; then echo "problem downloading txVout"; netCheck; echo "idk"; exit 1; fi
        if [[ "$firstRun" == 0 ]]; then fname; firstRun=1 ; fi
        echo -n "${pvoutAsm[3]}" | xxd -r -p >> "$file"
        stat=$(ls -hal "$file" | awk '{ print $5,$9 }')
        stats="$arrayHash $stat $count of $total"; if [[ "$firstRun1" == 1 ]]; then echo "$stats";fi
        if [[ "$firstRun1" == 0 ]]; then echo "$stats out of $grandTotal"; fi
        sed -i 1d "$arrayFile"
done
