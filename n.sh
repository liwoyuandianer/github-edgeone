# Netflix 返回码说明:
# 0: 成功解锁
# 1: 仅支持原创内容
# 2: 网络连接错误

#!/usr/bin/env bash

# 设置变量
grep -qwE '6|-6' <<< "$1" && MODE='-6' || MODE='-4'
CURL_ARGS=$2

# ==== 1. 检查 Lego Series  (乐高系列) 内容链接 ====
RESULT_1=$(curl ${CURL_ARGS} ${MODE} --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x6*4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -SsL --max-time 10 --tlsv1.3 "https://www.netflix.com/title/81280792" 2>&1 | awk '/curl:/{print}/og:video/{print "og:video"}{if(!found&&match($0,/"requestCountry":\{"supportedLocales":\[[^]]+\],"id":"[^"]+"/)){s=substr($0,RSTART,RLENGTH);sub(/.*"id":"*/,"",s);sub(/".*/,"",s);print "requestCountry:",s;found=1}}')

grep -q 'curl:' <<< "$RESULT_1" && echo -n -e "\r Netflix: Failed\n" && exit 2

# ==== 2. 检查 Breaking Bad (绝命毒师) 内容链接 ====
RESULT_2=$(curl ${CURL_ARGS} ${MODE} --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x6*4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -SsL --max-time 10 --tlsv1.3 "https://www.netflix.com/title/70143836" 2>&1 | awk '/curl:/{print}/og:video/{print "og:video"}{if(!found&&match($0,/"requestCountry":\{"supportedLocales":\[[^]]+\],"id":"[^"]+"/)){s=substr($0,RSTART,RLENGTH);sub(/.*"id":"*/,"",s);sub(/".*/,"",s);print "requestCountry:",s;found=1}}')

grep -q 'curl:' <<< "$RESULT_2" && echo -n -e "\r Netflix: Failed\n" && exit 2

# ============ 3. 从结果中提取地区代码 ============
REGION_1=$(awk '/requestCountry:/{print $NF}' <<< "$RESULT_1")

# ======== 4. 检查是否能访问 Netflix 内容 ========
if grep -q 'og:video' <<< "${RESULT_1}${RESULT_2}"; then
  echo -n -e "\r Netflix: Yes${REGION_1:+ (Region: ${REGION_1})}\n"
  exit 0
else
  echo -n -e "\r Netflix: Originals Only${REGION_1:+ (Region: ${REGION_1})}\n"
  exit 1
fi
