#!/usr/bin/bash
# USE AT YOUR OWN RISK
# NO CLAIM OF FITNESS FOR ANY PURPOSE
# dependencies: npm, bsv (js), openssl

if [[ $3 == "iter" ]]; then
        iteration_count="$4"
else
        iteration_count=10000
fi

date="$EPOCHSECONDS"

if [[ $1 -ne "encrypt" ]]; then
        if [[ $1 -ne "decrypt" ]];then
                echo "Usage: ./sslkey <encrypt or decrypt> <number of keys or file name>,"\
                $'\n'"example: ./sslkey encrypt 5"$'\n'"example: ./sslkey decrypt file.name"\
                $'\n'"example: ./sslkey encrypt 5 iter 12000"$'\n'"example: ./sslkey decrypt file.name iter 12000"
                exit 1
        fi
fi

if [[ ! -x $(command -v openssl) ]]; then
        echo "OpenSSL not Installed"
        exit 1
fi
if [[ ! -x $(command -v npm) ]]; then
        echo "npm is not Installed"
        exit 1
fi

if [[ "$1" == 'encrypt' ]] ; then
        keycount="$2"
        if [ ! -d node_modules/bsv/ ]; then
                npm i bsv --prefix "$(pwd)" --save &>/dev/null
        fi
        if [[ "$(npm list bsv | awk NR==2 | tr -dc '0-9' | cut -c 1)" == "2" ]];then vkey=PrivKey; pkey=PubKey; fi
        if [[ "$(npm list bsv | awk NR==2 | tr -dc '0-9' | cut -c 1)" == "1" ]];then vkey=PrivateKey; pkey=PublicKey; fi
        declare -a keylist
        while [ "$keycount" -gt 0 ]; do
                keygen=$(node<<<"var bsv = require('bsv'); var prvK = bsv.$vkey.fromRandom(); console.log(bsv.Address.from$pkey(bsv.$pkey.from$vkey(prvK)).toString(),prvK.toString())")
                keylist+=("$keygen")
                keycount=$(("$keycount"-1))
                printf '%s' "."
        done
        echo ""
        for value in "${keylist[@]}"; do
                awk '{ print $1 }'<<<"$value" | tee -a pubkeys."$date".txt
        done
        sed 's/ /+/g'<<<"${keylist[@]}" | openssl aes-256-ecb -pbkdf2 -iter "$iteration_count" -salt -out keys."$date".aes
        echo "pubkeys.""$date"".txt, keys.""$date"".aes iteration count: $interation_count"
        exit 0
elif [[ "$1" == 'decrypt' ]] ; then
        yourfile="$2"
        openssl aes-256-ecb -d -salt -pbkdf2 -iter "$iteration_count" -in "$yourfile" \
        | sed 's/+/\n/g' | paste -d ' ' - - > "$yourfile".txt
        echo "$yourfile".txt
        exit 0
else
        echo "error"
        exit 1
fi
