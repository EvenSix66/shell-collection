#!/bin/bash

# 域名列表，用空格分隔
DOMAIN_LIST="example1.com example2.com example3.com"

# Webhook 地址
WEBHOOK_URL="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxxxx-xxxxx"

# 定义一个函数来检查 SSL 证书的到期时间
check_ssl_expiration() {
  local domain=$1
  local expiration_date=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -enddate | sed -e 's#notAfter=##')
  local expiration_seconds=$(date -d "$expiration_date" +%s)
  local current_seconds=$(date +%s)
  local remaining_days=$((($expiration_seconds - $current_seconds) / 86400))
  
  # 天数判断
  if [ $remaining_days -le 2 ]; then
    echo "域名:$domain 的证书即将过期"
    curl $WEBHOOK_URL \
      -H 'Content-Type: application/json' \
      -d '{
            "msgtype": "text",
            "text": {
              "content": "域名:'$domain' 的证书即将过期"
            }
          }'
  fi
}

# 遍历域名列表，检查每个域名的 SSL 证书到期时间
for domain in $DOMAIN_LIST; do
  check_ssl_expiration $domain
done

# 0 0 * * * /path/to/check_ssl_expiration.sh
