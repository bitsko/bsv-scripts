#!/bin/bash
if ! [ -x "$(command -v npm)" ]; then echo "install npm"; return; fi
if [ $(npm list bsv | awk NR==2 | tr -dc '0-9' | cut -c 1) -eq "1" ]; then
        echo "bsvjs 1x installed, needs bsvjs 2x"; return; fi
if [ ! -d node_modules/bsv/ ]; then npm i --prefix "$(pwd)" bsv --save &>/dev/null; fi
if [[ -p "/dev/stdin" ]]; then
        txid="$(cat)"
else
        txid="$1"
        if [[ -z "$1" ]]; then
                echo "provide an txid as \$1"
                exit 1
        fi
fi
jqs(){ jq $1<<<$(cat) | \
                sed 's/[[]//g;s/[]]//g;s/"//g;s/[[:space:]]*$//g;s/^[[:space:]]*//g;s/[:]//g;s/,//g;s/[{]//g;s/[}]//g' | \
                        sed '/^$/d'; }
wochashtx() { curl -s --location --request GET  "https://api.whatsonchain.com/v1/bsv/main/tx/hash/$txid"; }
wochash=$(wochashtx)

address_from_scriptsig() {
#https://hackernoon.com/scriptsig-a-bitcoin-architecture-deep-dive-fs1i3zvy
SCRIPTSIG="$line"
theBytes=$(echo "$SCRIPTSIG" | cut -c 1-2)
hexChar=$(expr `echo "ibase=16; $(printf $theBytes)" | bc` "*" 2)
nextSpot=$((hexChar + 3))
theflag=$((nextSpot + 1))
theFlag=$(echo $SCRIPTSIG | cut -c "$nextSpot"-"$theflag")
hexChar2=$(expr `echo "ibase=16; $(printf $theFlag)" | bc` "*" 2)
nextSpot=$((theflag + 1))
hexchar=$((nextSpot + hexChar2))
publicKey=$(echo $SCRIPTSIG | cut -c "$nextSpot-$hexchar")
after256and160=$(echo "$publicKey" | xxd -r -p | openssl sha256 | awk '{ print $2 }' \
        | xxd -r -p | openssl ripemd160 | awk '{ print $2 }')
address=$(bx base58check-encode "$after256and160")
echo "$address"
}

echo "txid: $txid"
vinScriptsig=$(jqs .vin<<<"$wochash" | grep hex | awk '{ print $2 }')
while IFS=' ' read -r line; do
        vinAddress=$(address_from_scriptsig)
        echo "vin : $(address_from_scriptsig)"
done<<<"$vinScriptsig"
voutAddresses=$(jq .vout<<<"$wochash" | grep -A 1 addresses |  sed 's/"//g;s/[addresses: []//g;s/--//g;s/^[ \t]*//;/^[[:space:]]*$/d')
voutOPreturn=$(jq .vout[].scriptPubKey.asm<<<"$wochash" | grep OP_RETURN | sed 's/"//g' | awk '{ print $1,$2 }')
if [[ -n "$voutAddresses" ]]; then
        while IFS=' ' read -r line; do
                echo "vout: $line"
        done<<<"$voutAddresses"
fi
opReturnType=$(jq .vout[].scriptPubKey.opReturn.type<<<"$wochash")
opReturnAction=$(jq .vout[].scriptPubKey.opReturn.action<<<"$wochash")

optype(){
while IFS=' ' read -r type; do
        if [[ "$type" != "null" ]]; then
                echo "$type"
        fi
done<<<"$opReturnType"
}

opaction() {
while IFS=' ' read -r action; do
        if [[ "$action" != "null" ]]; then
                echo "$action"
        fi
done<<<"$opReturnAction"
}

if [[ -n "$voutOPreturn" ]]; then
        echo "vout: $voutOPreturn $(optype) $(opaction)"
fi
