#!/usr/bin/env bash

grep -qwE '6|-6' <<< "$1" && MODE='-6' || MODE='-4'
CURL_ARGS=$2
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x6*4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"

MediaUnlockTest_Netflix() {
  local RESULT_1=$(curl ${CURL_ARGS} ${MODE} --user-agent "${UA_Browser}" -SsL --max-time 10 --tlsv1.3 "https://www.netflix.com/title/81280792" 2>&1 | awk '/curl:/{print} /og:video/{print "og:video"}{while(match($0,/"requestCountry":\{"supportedLocales":\[[^]]+\],"id":"[^"]+"/)){c++;s=substr($0,RSTART,RLENGTH);sub(/.*"id":"*/,"",s);sub(/".*/,"",s);if(c==2)print "requestCountry:",s;$0=substr($0,RSTART+RLENGTH)}}')

  grep -q 'curl:' <<< "$RESULT_1" && return 2

  local RESULT_2=$(curl ${CURL_ARGS} ${MODE} --user-agent "${UA_Browser}" -SsL --max-time 10 --tlsv1.3 "https://www.netflix.com/title/70143836" 2>&1 | awk '/curl:/{print} /og:video/{print "og:video"}{while(match($0,/"requestCountry":\{"supportedLocales":\[[^]]+\],"id":"[^"]+"/)){c++;s=substr($0,RSTART,RLENGTH);sub(/.*"id":"*/,"",s);sub(/".*/,"",s);if(c==2)print "requestCountry:",s;$0=substr($0,RSTART+RLENGTH)}}')
  grep -q 'curl:' <<< "$RESULT_2" && return 2

  REGION_1=$(awk '/requestCountry/{print $NF}' <<< "$RESULT_1")

  grep -q 'og:video' <<< "${RESULT_1}${RESULT_2}" && return 0 || return 1
}

MediaUnlockTest_Netflix

case "$?" in
  0 ) echo -n -e "\r Netflix: Yes${REGION_1:+ (Region: ${REGION_1})}\n" ;;
  1 ) echo -n -e "\r Netflix: Originals Only${REGION_1:+ (Region: ${REGION_1})}\n" ;;
  * ) echo -n -e "\r Netflix: Failed\n"
esac
