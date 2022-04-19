#!/bin/bash
ncli(){ "$HOME"/.novo-bitcoin/bin/novobitcoin-cli $1 $2 $3 $4 $5 $6; }
export -f ncli
jqs(){ jq "$1"<<<$(cat) | sed 's/[[]//g;s/[]]//g;s/"//g;s/[[:space:]]*$//g;s/^[[:space:]]*//g;s/[:]//g;s/,//g;s/[{]//g;s/[}]//g' | sed '/^$/d'; }
createraw(){ bash<<<"ncli createrawtransaction '[{\"txid\":\"""$(ncli listunspent | jqs .[0].txid)""\",\"vout\":0}]' '{\"""$(ncli listunspent | jqs .[0].address)""\":1}' 0"; }
firstPartRaw=$(createraw)
echo "first part of raw tx:"
echo "$firstPartRaw"
echo ""
echo "first part raw decoded:"
ncli decoderawtransaction "$firstPartRaw"
