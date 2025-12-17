#!/usr/bin/env bash

# Disney+ 检测函数
MediaUnlockTest_DisneyPlus() {
  # ========= 1. 获取设备注册的assertion =========
  local assertion=$(curl --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/devices" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -H "content-type: application/json; charset=UTF-8" -d '{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","attributes":{}}' 2>&1 | sed 's/.*assertion":"\([^"]\+\)".*/\1/')

  grep -q 'curl:' <<< "$assertion" && return 1

  # ========= 2. 获取Disney+的Cookie信息 =========
  local Media_Cookie=$(curl -s --retry 3 --max-time 10 "https://raw.githubusercontent.com/1-stream/RegionRestrictionCheck/main/cookies" | sed -n '1p;8p' &)

  local PreDisneyCookie=$(sed -n '1p' <<< "$Media_Cookie")

  local disneycookie=$(sed "s/DISNEYASSERTION/${assertion}/g" <<< "$PreDisneyCookie")

  # ========= 3. 使用assertion获取token =========
  local TokenContent=$(curl --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/token" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycookie" 2>&1)

  grep -qE 'forbidden-location|403 ERROR' <<< "$TokenContent" && return 1

  local fakecontent=$(sed -n '2p' <<< "$Media_Cookie")

  local refreshToken=$(sed 's/.*"refresh_token":[ ]*"\([^"]\+\)".*/\1/' <<< "$TokenContent")

  local disneycontent=$(sed "s/ILOVEDISNEY/${refreshToken}/g" <<< "$fakecontent")

  # ========= 4. 使用token获取用户区域信息 =========
  local tmpresult=$(curl --user-agent "${UA_Browser}" -X POST -sSL --max-time 10 "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycontent" 2>&1)

  grep -q 'curl:' <<< "$tmpresult" && return 1

  # ========= 5. 检查预览页面 =========
  local previewchecktmp=$(curl -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.disneyplus.com")

  grep -q 'curl:' <<< "$previewchecktmp" && return 1

  local isUnavailable=$(grep -E 'preview.*unavailable' <<< $tmpresult)

  local region=$(sed -n 's/.*"countryCode":[ ]*"\([^"]\+\)".*/\1/p' <<< "$tmpresult")

  local inSupportedLocation=$(sed -n 's/.*"inSupportedLocation":[ ]*\([^,]\+\),.*/\1/p' <<< "$tmpresult")

  if [ -z "$region" ]; then
      return 2
  elif [[ "$region" == "JP" ]]; then
      region="JP"
      return 0
  elif [ -n "$isUnavailable" ]; then
      return 3
  elif [[ "$inSupportedLocation" == "true" ]]; then
      region="$region"
      return 0
  elif [[ "$inSupportedLocation" == "false" ]]; then
      region="$region"
      return 4
  else
      return 5
  fi
}

# 设置变量
grep -qwE '6|-6' <<< "$1" && MODE='-6' || MODE='-4'
CURL_ARGS=$2
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x6*4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"

# 执行检测
MediaUnlockTest_DisneyPlus

# Disney+ 返回码说明:
# 0: 成功解锁(包括日本地区)
# 1: 网络连接错误
# 2: 未知区域
# 3: 不可用
# 4: 即将支持该区域
# 5: 检测失败
case "$?" in
  0 )
    echo -n -e "\r Disney+: Yes (Region: ${region^^}).\n"
    ;;
  1 )
    echo -n -e "\r Disney+: No (Network Error).\n"
    ;;
  2 )
    echo -n -e "\r Disney+: No (Unknown).\n"
    ;;
  3 )
    echo -n -e "\r Disney+: No (Unavailable).\n"
    ;;
  4 )
    echo -n -e "\r Disney+: Available For [Disney+ ${region:-Unknown}] Soon.\n"
    ;;
  5 )
    echo -n -e "\r Disney+: No (Failed).\n"
    ;;
  * )
    echo -n -e "\r Disney+: No.\n"
    ;;
esac
