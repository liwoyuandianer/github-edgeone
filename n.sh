#!/usr/bin/env bash

grep -E '6|-6' <<< "$1" && MODE='-6' || MODE='-4'
CURL_ARGS=$2

MediaUnlockTest_Netflix() {
  local RESULT_1=$(curl ${CURL_ARGS} ${MODE} --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.64" -SsL --max-time 10 --tlsv1.3 "https://www.netflix.com/title/81280792" 2>&1 | grep -E 'curl:|og:video|requestCountry')

  grep -q 'curl:' <<< $RESULT_1 && return 2

  local RESULT_2=$(curl ${CURL_ARGS} ${MODE} --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.64" -SsL --max-time 10 --tlsv1.3 "https://www.netflix.com/title/70143836" 2>&1 | grep -E 'curl:|og:video|requestCountry')

  grep -q 'curl:' <<< $RESULT_2 && return 2

  REGION_1=$(awk '{while(match($0,/"requestCountry":\{"supportedLocales":\[[^]]+\],"id":"[^"]+"/)){c++;s=substr($0,RSTART,RLENGTH);sub(/.*"id":"*/,"",s);sub(/".*/,"",s);if(c==2){print s;exit}$0=substr($0,RSTART+RLENGTH)}}' <<< "$RESULT_1")

  grep -q 'og:video' <<< "${RESULT_1}${RESULT_2}" && return 0 || return 1
}

MediaUnlockTest_Netflix

case "$?" in
  0 ) echo -n -e "\r Netflix: Yes (Region: ${REGION_1})\n" ;;
  1 ) echo -n -e "\r Netflix: Originals Only (Region: ${REGION_1})\n" ;;
  * ) echo -n -e "\r Netflix: Failed\n"
esac
