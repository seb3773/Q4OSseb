#!/bin/sh
echo && echo "► Local IP(s):" && ip -c -o a | awk '{print $2,$4}' | column -t && echo "► Foreign IP:" && curl -s "https://ipapi.co/$*/yaml" | awk '/ip:/{IP=$2} /asn:/{ASN=$2} /city:/{$1="";CITY=$0;} /country_name:/{$1="";COUNTRY=$0} /org:/{$1="";print "\033[0;32m" IP "\033[0m, " ASN "," $0 "," CITY "," COUNTRY}' && echo


