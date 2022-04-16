#!/bin/bash
net=main
[[ -z $(command -v tput) ]] && echo "requires tput" && exit 1
red=$(tput setaf 1)
white=$(tput setaf 7)
blue=$(tput setaf 4)
normal=$(tput sgr0)
green=$(tput setaf 2)
bright=$(tput bold)
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

address_from_scriptsig() {
#if [[ -p "/dev/stdin" ]]; then SCRIPTSIG="$(cat)"; else SCRIPTSIG="$1"; \
#        if [[ -z "$1" ]]; then echo "provide a scriptsig as \$1"; return; fi; fi

theBytes=$(cut -c 1-2<<<"$SCRIPTSIG")
bytesVar=$(echo "ibase=16; $(printf '%s' "$theBytes")" | bc)
hexChar=$((bytesVar * 2)); nextSpot=$((hexChar + 3)); theflag=$((nextSpot + 1)) #jumps sigtype
theBytes=$(cut -c "$nextSpot"-"$theflag"<<<"$SCRIPTSIG")
bytesVar=$(echo "ibase=16; $(printf '%s' "$theBytes")" | bc)
hexChar=$((bytesVar * 2)); nextSpot=$((theflag + 1)); pubChar=$((nextSpot + hexChar))
publicKey=$(cut -c "$nextSpot-$pubChar"<<<"$SCRIPTSIG")
a256and160=$(xxd -r -p<<<"$publicKey" | openssl sha256 | awk '{ print $2 }' \
        | xxd -r -p | openssl ripemd160 | awk '{ print $2 }')
address=$(bx base58check-encode "$a256and160")
printf '%s\n' "$address"; }

woc_txhash(){ jq<<<$(curl -s --location --request GET  "https://api.whatsonchain.com/v1/bsv/$net/tx/hash/$arrayHash"); }
asmtx(){ node<<<"let bsv = require('bsv'); var script = bsv.Script.fromHex('$(curl -s --location --request GET  https://api.whatsonchain.com/v1/bsv/"$net"/tx/"$arrayHash"/out/0/hex)');console.log(script.toAsmString())" | sed 's/ /\n/g'; }
arrayFile=$(asmtx)
if [ $? -ne 0 ]; then
        printf '%s\n' "${red}cant connect to api${normal}"
        exit 1
fi
line=1
echo "${bright}------txid: $arrayHash${normal}"
while read f; do
        if [[ "$opdup" == 1 ]] && [[ "$ophash160" == 1 ]] && [[ "$line" == 3 ]]; then
                p2pkh_address=$(bx base58check-encode "$f")
                printf '%s\n' "${white}pos-$line-hex-: ${normal}${blue}$f ${normal}${bright}Address: $p2pkh_address${normal}"
        else
                printf '%s\n' "${white}pos-$line-hex-: ${normal}${blue}$f${normal}"
        fi
        if [[ "$f" == OP_DUP ]]; then opdup=1; fi
        if [[ "$f" == OP_HASH160 ]]; then ophash160=1; fi
        if [[ -n "$p2pkh_address" ]]; then p2pkh_address=1; fi
        if [[ "$f" == OP_EQUALVERIFY ]]; then opequal=1; fi
        if [[ "$f" == OP_CHECKSIG ]]; then opchecksig=1; fi
        if [[ $(wc -m<<<"$f") -gt 7 ]]; then
                if [[ $(wc -m<<<"$f") -lt 100 ]]; then
                        text=$(xxd -r -p<<<"$f" | strings)
                else
                        text=$(xxd -r -p<<<"$f" | strings -n 7)
                fi
        elif [[ "$f" != 00 ]]; then
                text=$(xxd -r -p<<<"$f")
        else
                text=' '
        fi
        if [[ -n "$text" ]]; then
                if [[ "$text" == 19iG3WTYSsbyos3uJ733yK4zEioi1FesNU ]]; then
                        printf '%s\n' "${white}pos-$line-${bright}text: ${green}$text ${normal}${bright}D:// Bitcoin Dynamic Content Protocol${normal}"
                elif [[ "$text" == 19HxigV4QyBv3tHpQVcUEQyq1pzZVdoAut ]]; then
                        printf '%s\n' "${white}pos-$line-${bright}text: ${green}$text ${normal}${bright}B:// Bitcoin Data Protocol${normal}"
                elif [[ "$text" == 1ChDHzdd1H4wSjgGMHyndZm6qxEDGjqpJL ]]; then
                        printf '%s\n' "${white}pos-$line-${bright}text: ${green}$text ${normal}${bright}B part transaction${normal}"
                elif [[ "$text" == 15DHFxWZJT58f9nhyGnsRBqrgwK4W6h4Up ]]; then
                        printf '%s\n' "${white}pos-$line-${bright}text: ${green}$text ${normal}${bright}BCat transaction${normal}"
                else
                        if [[ $(wc -m<<<"$text") -gt 2 ]]; then
                                printf '%s\n' "${white}pos-$line-${bright}text: ${green}$text${normal}"
                        fi
                fi
        fi
        line=$((line + 1))
if [[ -n "$opdup" ]] && [[ -n "$ophash160" ]] &&  [[ "$p2pkh_address" == 1 ]] &&
        [[ -n "$opequal" ]] && [[ -n "$opchecksig" ]]; then
                echo "------type:${bright} Pay to Public Key Hash transaction${normal}"
fi
done<<<"$arrayFile"
echo "txVouts:"
vouts=$(woc_txhash "$arrayHash" | jq -r .vout[].scriptPubKey.hex)
vout=0
while read -r line; do
        if [[ $(wc -m<<<"$line") == 51 ]]; then
                voutaddress=$(bx base58check-encode "$line")
                echo "Vout $vout Address: $voutaddress"
        else
                echo "$line"
        fi
vout=$((vout + 1 ))
done<<<"$vouts"
