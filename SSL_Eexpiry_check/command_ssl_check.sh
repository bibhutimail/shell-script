
#!/bin/bash
url_list=$1
rm -rf /tmp/url_ssl_list.txt
while read line; do
data=`echo | openssl s_client -servername $line -connect $line:443 2>/dev/null | openssl x509 -noout -enddate | sed -e 's#notAfter=##'`

ssldate=`date -d "${data}" '+%s'`
nowdate=`date '+%s'`
diff="$((${ssldate}-${nowdate}))"

echo $line $((${diff}/86400)) >>/tmp/url_ssl_list.txt
done < $url_list
