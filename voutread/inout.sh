#!/bin/bash
#messy output
woc_txhash(){
        net=main; if [[ "$2" == "test" ]]; then net=test; fi; if [[ "$2" == "stn" ]]; then net=stn; fi
        if [[ -p "/dev/stdin" ]]; then hash="$(cat)"; else
        hash="$1"; if [[ -z "$1" ]]; then echo "provide a hash as \$1 or pipe in a hash"; return; fi; fi
        txHash=$(curl -s --location --request GET  "https://api.whatsonchain.com/v1/bsv/$net/tx/hash/$hash")
        jq<<<"$txHash"
        truncateCheck=$(jq<<<"$txHash" | grep '"isTruncated": true' | awk '{ print $2 }')
        if [[ "$truncateCheck" == "true" ]]; then echo $'\n'"Output is Truncated. Use:"$'\n'"woc_rawtxout $1"$'\n'; return; fi
        if [[ -z "$txHash" ]]; then echo "Transaction hash not found. try:"$'\n'"woc_txhash $1 test"$'\n'"or"$'\n'"woc_txhash $1 stn"; return; fi
}
jqs(){
jq $1<<<$(cat) | sed 's/[[]//g;s/[]]//g;s/"//g;s/[[:space:]]*$//g;s/^[[:space:]]*//g;s/[:]//g;s/,//g;s/[{]//g;s/[}]//g' | sed '/^$/d'
}
inout=$(woc_txhash "$1")
zin=$(jq .vin<<<"$inout")
out=$(jq .vout<<<"$inout")
echo $'\n'"***vin***"$'\n'
jqs<<<"$zin"
echo $'\n'"***vout***"$'\n'
jqs<<<"$out"
