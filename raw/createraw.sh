ncli(){ "$HOME"/.novo-bitcoin/bin/novobitcoin-cli $1 $2 $3 $4 $5 $6; }
export -f ncli
jqs(){ jq "$1"<<<$(cat) | sed 's/[[]//g;s/[]]//g;s/"//g;s/[[:space:]]*$//g;s/^[[:space:]]*//g;s/[:]//g;s/,//g;s/[{]//g;s/[}]//g' | sed '/^$/d'; }
createraw(){
partA="ncli createrawtransaction '[{\"txid\":\""
partB=$(ncli listunspent | jqs .[0].txid)
partC="\",\"vout\":0}]' '{\""
partD=$(ncli listunspent | jqs .[0].address)
partE="\":1}' 0"
bash<<<"$partA$partB$partC$partD$partE"
}
firstPartRaw=$(createraw)
echo "first part of raw tx:"
echo "$firstPartRaw"
echo ""
echo "first part raw decoded:"
ncli decoderawtransaction "$firstPartRaw"
