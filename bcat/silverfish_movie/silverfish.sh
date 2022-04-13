#!/usr/bin/env bash

#download a 1.1GB webm video file from bitcoinsv bcat transactions lol
# wget https://raw.githubusercontent.com/bitsko/silverfish.sh/main/silverfish.sh
# chmod +x silverfish.sh
# ./silverfish.sh ## downloads silverfish.webm
# ./silverfish.sh any_bcat_txid ## might download your bcat file idk

#use at your own risk
#big thanks to https://whatsonchain.com/

# requires bsv npm jq xxd curl grep exiftool bash and several gigamegs
# make sure bsv 2 is installed in current directory and do dependency check
if [ ! -d node_modules/bsv/ ]; then echo "installing BSV js library"; npm i --prefix "$(pwd)" bsv --save ; fi
if [ $(cat package.json | jq .dependencies.bsv | sed 's/\"\^//g' | cut -c 1) -eq "1" ]; then
  echo "bsvjs 1x installed, install bsvjs 2x instead"; exit 1; fi
if ! [ -x "$(command -v jq)" ]; then echo "install jq"; exit 1; fi
if ! [ -x "$(command -v npm)" ]; then echo "install npm"; exit 1; fi
if ! [ -x "$(command -v xxd)" ]; then echo "install xxd"; exit 1; fi
if ! [ -x "$(command -v curl)" ]; then echo "install curl"; exit 1; fi
if ! [ -x "$(command -v grep)" ]; then echo "install grep"; exit 1; fi
if ! [ -x "$(command -v exiftool)" ]; then echo "install exiftool"; exit 1; fi

####################################
#https://github.com/bico-media/bcat#
####################################
#
#"Transactions on the blockchain that includes the bitcom namespace
#15DHFxWZJT58f9nhyGnsRBqrgwK4W6h4Up at the first position after an
#OP_RETURN code shall be called a "Bcat" transaction."
#
#Bcat transaction:
#
#OP_RETURN
#15DHFxWZJT58f9nhyGnsRBqrgwK4W6h4Up
#info
#MIME type
#charset
#name
#flag
#dataparts 1,2,etc
#
#Transactions on the blockchain that include the bitcom namespace
#1ChDHzdd1H4wSjgGMHyndZm6qxEDGjqpJL at the first position after an
#OP_RETURN code shall be called Bcat part transactions
#
#Bcat part:
#
#OP_RETURN
#1ChDHzdd1H4wSjgGMHyndZm6qxEDGjqpJL
#data
#
####################################
#https://github.com/bico-media/bcat#
####################################

save_all_txdata=off
all=/dev/null
if [[ "$save_all_txdata" == "on" ]]; then
  all=".bsv/$hash.voutAsm"
fi

verbose=off
if [[ "$verbose" == "on" ]]; then
  echo "verbose mode activated"
fi

#silverfish.webm unless a different bcat transaction hash is
#specified after the script on the commandline
bcat_tx=79437a613e31b828ed4cfaf97297b1b9f4d766f5cf548fcccd11059d1dc2b8e3
[ -n "$1" ] && bcat_tx="$1" && echo "txid $1 selected"

#max number of bcat parts
max=2250

bCat=15DHFxWZJT58f9nhyGnsRBqrgwK4W6h4Up
bPart=1ChDHzdd1H4wSjgGMHyndZm6qxEDGjqpJL
idk=1Ar7orUhZsqcSNf2xcPQTXapBvEMnXp3Et

date="$EPOCHSECONDS"
withErrors=0

hashlog=".bsv/$bcat_tx.log"
arrayFile=".bsv/$bcat_tx.voutAsm"
#folder where tx info and logs are kept
if [[ ! -d .bsv ]]; then mkdir .bsv; fi
touch "$hashlog"

nameFunc(){
mvd="moved by bcat mimetype"
fileType=$(file --extension "$file" | awk '{ print $2 }' | cut -c -4)
theSuffix=$(exiftool "$file" | grep "File Type Extension" | awk '{ print $5 }')
if [[ $(echo "$file" | rev | cut -c -3 | rev) != "$theSuffix" ]] && [[ -n "$theSuffix" ]] &&
   [[ "$file" != *"."* ]]; then
     mv "$file" "$file.$theSuffix"
if [[ "$verbose" == "on" ]]; then
     echo "moved by exiftool (1)"
fi
  file="$file.$theSuffix"
fi
if [[ "$file" != *"."* ]];then
  if [[ "$mime" == "application/pdf" ]]; then
    mv "$file" "$file".pdf
    if [[ "$verbose" == "on" ]]; then
      echo "$mvd"
    fi
    file="$file".pdf
  elif [[ "$mime" == "video/mp4" ]]; then
    isBIE=$(xxd -b -p "$file" | head -n 1 | xxd -r -p | head -c 3)
    if [[ "$isBIE" != "BIE" ]]; then
    mv "$file" "$file".mp4
      if [[ "$verbose" == "on" ]]; then
        echo "$mvd"
      fi
    file="$file".mp4
    elif [[ "$isBIE" == "BIE" ]]; then
      mv "$file" "$file".BIE.mp4
      if [[ "$verbose" == "on" ]]; then
        echo "BIE detected, named by bcat mimetype"
      fi
      echo "encrypted file detected."
      echo "see twetch.com"
      echo "$bcat_tx"
      file="$file".BIE.mp4
    fi
  elif [[ "$mime" == "video/quicktime" ]]; then
    if [[ "$verbose" == "on" ]]; then
      echo "$mvd"
    fi
    mv "$file" "$file".mov
    file="$file".mov
  elif [[ "$mime" == "image/jpg" ]]; then
    if [[ "$verbose" == "on" ]]; then
      echo "$mvd"
    fi
    mv "$file" "$file".jpg
    file="$file".jpg
  elif [[ "$mime" == "audio/mpeg" ]]; then
    if [[ "$verbose" == "on" ]]; then
      echo "$mvd"
    fi
    mv "$file" "$file".mpeg
    file="$file".mpeg
  elif [[ "$mime" == "image/jpeg" ]]; then
    if [[ "$verbose" == "on" ]]; then
      echo "$mvd"
    fi
    mv "$file" "$file".jpeg
    file="$file".jpeg
  elif [[ "$mime" == "image/png" ]]; then
    if [[ "$verbose" == "on" ]]; then
      echo "$mvd"
    fi
    mv "$file" "$file".png
    file="$file".png
  else
    type=$(xxd -b -p "$file" | head -n 1 | xxd -r -p | head -c 3)
    if [[ "$verbose" == "on" ]]; then
      echo "$type""$mime"
      echo "unlisted mimetype"
    fi
  fi
fi
if [[ "$fileType" != "???" ]] && [[ "$file" != *"."* ]]; then
  mv "$file" "$file"."$fileType"
  if [[ "$verbose" == "on" ]]; then
    echo "moved by file --extension"
  fi
  file="$file"."$fileType"
fi
}

#load the bcat transaction array from bcat tx
if ! [ -f "$arrayFile" ]; then
  if [[ "$verbose" == "on" ]]; then
    echo "Creating voutAsm file"
  fi
  gethex=$(curl -s --location --request GET  "https://api.whatsonchain.com/v1/bsv/main/tx/$bcat_tx/out/0/hex")
  declare -a voutAsm=( $(echo \
    "let bsv = require('bsv'); var script = bsv.Script.fromHex('$gethex'); console.log(script.toAsmString())"\
    | node | sed 's/ /\n/g' | tee "$arrayFile" ) )
else
  declare -a voutAsm=( $(cat "$arrayFile") )
    if [[ "$verbose" == "on" ]]; then
      echo "voutAsm loaded from file"
    fi
fi

#make sure the op_false and the arrays with out it are interpreted the same
if [[ $(echo "${voutAsm[0]}") != "0" ]]; then
  voutAsm=("0" "${voutAsm[@]}")
fi

if [[ $(echo "${voutAsm[2]}" | xxd -r -p) == "$bCat" ]]\
  && [[ $(echo "${voutAsm[3]}" | xxd -r -p) != "$idk" ]]; then
  zero=$(echo "${voutAsm[0]}")
  opreturn=$(echo "${voutAsm[1]}")
  address=$(echo "${voutAsm[2]}" | xxd -r -p)
  info=$(echo "${voutAsm[3]}" | xxd -r -p)
  if [[ -n $(echo "${voutAsm[4]}") ]]; then mime=$(echo "${voutAsm[4]}" | xxd -r -p);fi
  if [[ -n $(echo "${voutAsm[5]}") ]]; then charset=$(echo "${voutAsm[5]}" | xxd -r -p); fi
  file=$(echo "${voutAsm[6]}" | xxd -r -p | sed 's/ //g;s/-//g;s/://g')
  if [[ "${voutAsm[7]}" -ne "00" ]]; then flag=$(echo "${voutAsm[7]}" | xxd -r -p);fi
    if [[ "$info" == "dogefiles" ]] && [[ "$mime" == "video/mp4" ]]\
    && [[ "$charset" == "binary" ]] && [[ "$file" == "dogefile" ]]; then
      echo "########################################################"
      echo "#this is a dogefile video, and it probably wont play :(#"
      echo "########################################################"
      echo "info: $info"
      echo "mimetype: $mime"
      echo "charset: $charset"
      echo "filename: $file"
      echo "dataflag: $flag"

      while true; do
        read -p "Quit?"$'\n' yn
        case $yn in
          [Yy]* ) exit 0;;
          [Nn]* ) echo "downloading..."; break;;
          [Qq]* ) exit 0;;
              * ) echo "Please answer yes no or quit.";;
        esac
     done
   fi

elif [[ $(echo "${voutAsm[2]}" | xxd -r -p) == "$bPart" ]]; then
  echo "this is a bcat part transaction"
  exit 1
elif [[ $(echo "${voutAsm[2]}" | xxd -r -p ) == "$idk" ]]; then
  file="$bcat_tx"
  #if [[ "$verbose" == "on" ]]; then
  #   echo "${voutAsm[@]}" | sed 's/ /\n/g' > "$bcat_tx".vout.Asm
  #fi
  echo "${voutAsm[3]}" | xxd -r -p >> "$file"
  echo "bitcom: $idk"
  theSuffix=$(exiftool "$file" | grep "File Type Extension" | awk '{ print $5 }')
  if [[ $(echo "$file" | rev | cut -c -3 | rev) != "$theSuffix" ]] && [[ -n "$theSuffix" ]] &&
     [[ "$file" != *"."* ]]; then
     mv "$file" "$file.$theSuffix"
  if [[ "$verbose" == "on" ]]; then
     echo "moved by exiftool (1)"
  fi
    file="$file.$theSuffix"
    echo "$file"
  fi
  exit 0
elif [[ $(echo "${voutAsm[3]}" | xxd -r -p ) == "$idk" ]]; then
  zero=$(echo "${voutAsm[0]}")
  opreturn=$(echo "${voutAsm[1]}")
  address=$(echo "${voutAsm[2]}" | xxd -r -p)
  idk=$(echo "${voutAsm[3]}" | xxd -r -p)
  mime=$(echo "${voutAsm[4]}" | xxd -r -p)
  file=$(echo "${voutAsm[6]}" | xxd -r -p)
  echo "not sure what an $idk tx is"
elif [[ $(echo "${voutAsm[2]}" | xxd -r -p) == "twetch" ]]; then
  echo "this is a twetch transaction."
  echo "see twetch.com/t/$bcat_tx"
  if [[ "$verbose" == "on" ]]; then
    echo "create variables for array elements of bcat array part of script"
  fi
  exit 1
else
  echo "Cant parse the first Bcat transaction hash"
  if [[ "$verbose" == "on" ]]; then
    echo "${voutAsm[0]} ${voutAsm[1]}"
  fi
  exit 1
fi

echo "$bcat_tx.voutAsm"
echo "***Bcat************"
echo "opcode: $opreturn"
echo "bcat address: $address"
echo "info: $info"
echo "mimetype: $mime"
echo "charset: $charset"
echo "filename: $file"
echo "dataflag: $flag"
echo "******************"
while true; do
  read -p "Yes to Download or no to Quit?"$'\n' ynq
  case $ynq in
    [Yy]* ) echo "downloading..."; break;;
    [Nn]* ) exit 0;;
    [Qq]* ) exit 0;;
        * ) echo "Please answer yes no or quit.";;
  esac
done
touch "$file"
echo "$file"

#resume from prior hash in array
if [[ $(wc -l "$hashlog" | awk '{ print $1 }') -ne "0" ]]; then
  while true; do
    read -p "Previous download found. yes to resume the download, no to start a new download, or quit to quit."$'\n>' ynq
    case $ynq in
      [Yy]* ) echo "restarting download from:" ; break;;
      [Nn]* ) echo "renaming prior hashlog and file to ""$hashlog"."$date".log \
                "and" "$file"."$date" ; mv "$hashlog" "$hashlog"."$date".log 2>/dev/null ; \
                if [ -f "$file" ]; then mv "$file" "$file"."$date" 2>/dev/null ;fi ; break;;
      [Qq]* ) exit 0;;
      * ) echo "Please answer yes no or quit.";;
    esac
  done
fi
touch "$hashlog"

#resume download
if [[ $(wc -l "$hashlog" | awk '{ print $1 }') -ne "0" ]]; then
  lastPiece=$(tail -n 1 "$hashlog" | awk '{ print $1 }')
  echo $(tail -n 1 "$hashlog" | awk '{ print $1,$2 }')$'\n'
  for i in "${!voutAsm[@]}"; do
    if [[ "${voutAsm[$i]}" = "${lastPiece}" ]]; then
      lastIndexCount=$(echo "${i}")
      lastIndexCount=$((lastIndexCount+1))
      for hash in "${voutAsm[@]:$lastIndexCount:$max}"; do
        asmtx2=$(echo "let bsv = require('bsv'); var script = bsv.Script.fromHex(\
          '$(curl -s --location --request GET  "https://api.whatsonchain.com/v1/bsv/main/tx/$hash/out/0/hex")'\
          ); console.log(script.toAsmString())" | node)
          #try to catch a failure state and retry
          if [ $? -ne 0 ]; then echo "RETRYING $hash"; withErrors=1; asmtx2=$(echo \
            "let bsv = require('bsv'); var script = bsv.Script.fromHex('$(curl -s --location --request GET  "\
            https://api.whatsonchain.com/v1/bsv/main/tx/$hash/out/0/hex\
            ")'); console.log(script.toAsmString())" | node)
          fi
          if [ $? -ne 0 ]; then
            echo "problem downloading txout;"
            if [[ "$verbose" == "on" ]]; then
              echo "on resume download script, #? ne 0 x2"
            fi
          exit 1
          fi
        
        declare -a pvoutAsm=( $(echo "$asmtx2" | sed 's/ /\n/g' | tee "$all" ) )
        bPartCheck2=$(echo "${pvoutAsm[2]}" | xxd -r -p) #OP_RETURN is position 1 of the array, leading 0 in array
        if [ "$bPartCheck2" == "$bPart" ]; then #bcatpart address is next position in array
          echo "${pvoutAsm[3]}" | xxd -r -p >> "$file" \
            && linecount=$(wc -l "$hashlog" | awk '{ print $1 }') \
            && linecount=$((linecount+1))
          echo "$hash $linecount "$(sha256sum "$file" | awk '{ print $1 }') >> "$hashlog"
          stat=$(ls -hal "$file" | awk '{ print $5,$9 }')
          echo "BCAT_PART" "$linecount" "$hash" "$stat"" restarted"
        else
          echo "Error Downloading bCatPart $hash on resume"
          echo "is your network down?"
          echo "${pvoutAsm[0]} ${pvoutAsm[1]}"
          #bcat_piece_errors=$((bcat_piece_errors+1)); if [[ "$bcat_piece_errors" -eq "5" ]]; then exit 1;fi
          #echo "$bcat_piece_errors"
#         linecount=$((linecount-1))
          #lastIndexCount=$((lastIndexCount-1))
          exit 1
        fi
      done
      echo "finished building $file from prior download"
      if [ "$withErrors" -eq 1 ]; then echo "with errors"; fi
      nameFunc
      exit 0
    fi
  done
fi

#first run
if [[ $(wc -l "$hashlog" | awk '{ print $1 }') -eq "0" ]]; then
  bCheck2=$(echo "${voutAsm[2]}" | xxd -r -p)
  cCheck=$(echo "${voutAsm[3]}" | xxd -r -p)
  if [[ "$bCheck2" == "$bCat" ]]; then
    echo "bcat part transaction hashes:"
    if [[ "$cCheck" != "$idk" ]];then
      for hash in "${voutAsm[@]:8:$max}"; do
        asmtx2=$(echo "let bsv = require('bsv'); var script = bsv.Script.fromHex('$(curl -s --location --request GET  \
        "https://api.whatsonchain.com/v1/bsv/main/tx/$hash/out/0/hex")'); console.log(script.toAsmString())" | node)
        #try to catch a failure state and retry
        if [ $? -ne 0 ]; then echo "RETRYING $hash"; withErrors=1; asmtx2=$(echo \
          "let bsv = require('bsv'); var script = bsv.Script.fromHex('$(curl -s --location --request GET  \
          "https://api.whatsonchain.com/v1/bsv/main/tx/$hash/out/0/hex")'); console.log(script.toAsmString())" | node)
        fi
        if [ $? -ne 0 ]; then 
          echo "problem downloading txout;"
          if [[ "$verbose" == "on" ]]; then
            echo "on first run script, #? ne 0 x2"
          fi
          exit 1
        fi
        declare -a pvoutAsm=( $(echo "$asmtx2" | sed 's/ /\n/g' | tee "$all") )
        bPartCheck2=$(echo "${pvoutAsm[2]}" | xxd -r -p) #OP_RETURN is position 1 of the array
        if [ "$bPartCheck2" == "$bPart" ] \
          && [[ $(echo "${voutAsm[3]}" | xxd -r -p) != "$idk" ]]; then #bcatpart address is next position in array
          echo "${pvoutAsm[3]}" | xxd -r -p >> "$file" \
            && linecount=$(wc -l "$hashlog" | awk '{ print $1 }') \
            && linecount=$((linecount+1))
          echo "$hash $linecount "$(sha256sum "$file" | awk '{ print $1 }') >> "$hashlog"
          stat=$(ls -hal "$file" | awk '{ print $5,$9 }')
          echo "BCAT_PART" "$linecount" "$hash" "$stat"
        else
          getlinks=$(curl -s -X POST https://api.whatsonchain.com/v1/bsv/main/search/links -H \
            'Content-Type: application/json' -d '{ "query": "$hash" }' | jq .results)
          if [[ "$getlinks" == "null" ]]; then
            echo "this is not valid ?"
          fi
          echo "Error Downloading bCatPart $hash"
          echo "${pvoutAsm[0]} ${pvoutAsm[1]}"
          if [[ "$verbose" == "on" ]]; then
            echo "first run loop else bpartcheck ne bpart"
          fi
          exit 1
        fi
      done
      echo "finished building $file"
      if [ "$withErrors" -eq 1 ]; then echo "with errors"; fi
      nameFunc
    fi
    elif [[ $(echo "${voutAsm[3]}" | xxd -r -p) == "$idk" ]]; then
      asmtx2=$(echo "let bsv = require('bsv'); var script = bsv.Script.fromHex('$(curl -s --location --request GET  \
      "https://api.whatsonchain.com/v1/bsv/main/tx/$hash/out/0/hex")'); console.log(script.toAsmString())" | node)
      declare -a pvoutAsm=( $(echo "$asmtx2" | sed 's/ /\n/g' | tee "$all") )
      echo "this tx is not bcat"
      echo "it is an $idk tx"
      echo "${pvoutAsm[3]}" | xxd -r -p >> "$file"
      for hash in "${voutAsm[@]:8:$max}"; do
      echo "$hash  $idk"
      if [[ "$verbose" == "on" ]]; then
        echo "${voutAsm[@]}" > "$hash".voutAsm
        echo "${pvoutAsm[@]}" > "$hash".pvoutAsm
      fi
      done
      exit 1
    else
      echo "is this a Bcat tx? ${voutAsm[0]} ${voutAsm[1]}"
      if [[ "$verbose" == "on" ]]; then
        echo "script location else loop at #logisempty no bitcom address match"
        echo $(echo "${voutAsm[2]}" | xxd -r -p)
        curl -s -X POST https://api.whatsonchain.com/v1/bsv/main/search/links -H \
          'Content-Type: application/json' -d '{ "query": "$hash" }' | jq
      fi
      exit 1
  fi
fi
