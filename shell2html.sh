#! /bin/bash
#Author : - Shashank Srivastava
#Date : - 18 September, 2017

#Checking if this script is being executed as ROOT. For maintaining proper directory structure, this script must be run from a root user.
if [ $EUID != 0 ]
then
  echo "Please run this script as root so as to see all details! Better run with sudo."
  exit 1
fi

#Declaring variables
#set -x
os_name=`uname -v | awk {'print$1'} | cut -f2 -d'-'`
upt=`uptime | awk {'print$3'} | cut -f1 -d','`
ip_add=`ifconfig | grep "inet addr" | head -2 | tail -1 | awk {'print$2'} | cut -f2 -d:`
num_proc=`ps -ef | wc -l`
root_fs_pc=`df -h /dev/sda1 | tail -1 | awk '{print$5}'`
root_fs_pc_numeric=`df -h /dev/sda1 | tail -1 | awk '{print$5}' | cut -f1 -d'%'`
total_root_size=`df -h /dev/sda1 | tail -1 | awk '{print$2}'`
#load_avg=`uptime | cut -f5 -d':'`
load_avg=`cat /proc/loadavg  | awk {'print$1,$2,$3'}`
ram_usage=`free -m | head -2 | tail -1 | awk {'print$3'}`
ram_total=`free -m | head -2 | tail -1 | awk {'print$2'}`
ram_pc=`echo "scale=2; $ram_usage / $ram_total * 100" | bc | cut -f1 -d '.'`
inode=`df -i / | head -2 | tail -1 | awk {'print$5'}`
inode_numeric=`df -i / | head -2 | tail -1 | awk {'print$5'} | cut -f1 -d '%'`
os_version=`uname -v | cut -f2 -d'~' | awk {'print$1'} | cut -f1 -d'-' | cut -c 1-5`
num_users=`who | wc -l`
cpu_free=`top b -n1 | head -5 | head -3 | tail -1 | awk '{print$8}' | cut -f1 -d ','`
last_reboot=`who -b | awk '{print$3, $4}'`

#Creating a directory if it doesn't exist to store reports first, for easy maintenance.
if [ ! -d ${HOME}/health_reports ]
then
  mkdir ${HOME}/health_reports
fi
html="${HOME}/health_reports/Server-Health-Report-`hostname`-`date +%y%m%d`-`date +%H%M`.html"
email_add="change this to yours"
for i in `ls /home`; do sudo du -sh /home/$i/* | sort -nr | grep G; done > /tmp/dir.txt
ps aux | awk '{print$2, $4, $6, $11}' | sort -k3rn | head -n 10 > /tmp/memstat.txt

#url_list
url_list=$1
rm -rf /tmp/url_ssl_list.txt
while read line; do
data=`echo | openssl s_client -servername $line -connect $line:443 2>/dev/null | openssl x509 -noout -enddate | sed -e 's#notAfter=##'`

ssldate=`date -d "${data}" '+%s'`
nowdate=`date '+%s'`
diff="$((${ssldate}-${nowdate}))"

echo $line $((${diff}/86400)) "NA" "NA" >>/tmp/url_ssl_list.txt
done < $url_list

top b -n1 | head -17 | tail -11 | awk '{print $1, $2, $9, $12}' | grep -v PID > /tmp/cpustat.txt
#Generating HTML file
echo "<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">" >> $html
echo "<html>" >> $html
echo "<head>" >> $html
echo "<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">" >> $html
echo "<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">" >> $html
echo "<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>" >> $html
echo "<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>" >> $html
echo -e "<script type="text/javascript">
google.charts.load('current', {'packages':['gauge']});
google.charts.setOnLoadCallback(drawChart);

function drawChart() {

  var data = google.visualization.arrayToDataTable([
  ['Label', 'Value'],
  ['# of Processes', $num_proc],
  ['# of Users', $num_users]
  ]);

  var options = {
    width: 600, height: 175,
    redFrom: 90, redTo: 100,
    yellowFrom:75, yellowTo: 90,
    minorTicks: 5
  };

  var chart = new google.visualization.Gauge(document.getElementById('chart_div'));

  chart.draw(data, options);
}
</script>" >> $html
echo "<link rel="stylesheet" href="https://unpkg.com/purecss@0.6.2/build/pure-min.css">" >> $html
echo "<body>" >> $html
echo "<fieldset>" >> $html
echo "<center>" >> $html
echo "<h2><span class=\"label label-primary\">Linux Server Report : `hostname`</span></h2>" >> $html
echo "<h3><legend>Script authored by BIBHUTI NARAYAN</legend></h3>" >> $html
echo "</center>" >> $html
echo "</fieldset>" >> $html
echo "<center>" >> $html
echo "<h2><span class=\"label label-info\">URL Details : </span></h2>" >> $html
echo "<br>" >> $html
echo "<table class=\"pure-table pure-table-bordered\">" >> $html
echo "<thead>" >> $html
echo "<tr>" >> $html
echo "<th>URL Name</th>" >> $html
echo "<th>Days Remaining</th>" >> $html
echo "<th>Comments</th>" >> $html
echo "<th>Remarks</th>" >> $html
echo "</tr>" >> $html
echo "</thead>" >> $html
echo "<tbody>" >> $html
echo "<tr>" >> $html
while read url days comments remarks;
do
if [ $days -lt 70 ]
then
echo "<td style="background-color:#FF0000" > $url " >> $html
else
echo "<td>$url</td>" >> $html
fi
echo "<td>$days</td>" >> $html
  echo "<td>$comments</td>" >> $html
  echo "<td>$remarks</td>" >> $html
  echo "</tr>" >> $html
done < /tmp/url_ssl_list.txt
echo "</tbody>" >> $html
echo "</table>" >> $html

echo "<br>" >> $html
echo "<h2><span class=\"label label-primary\">Pictorial Data : </span></h2>" >> $html
echo "<center><div id="chart_div"></div></center>" >> $html
echo -e "<br>
<div class=\"panel panel-primary\" style=\"width: 40%;\">
<div class=\"panel-heading\">
</center>
</div>
</div>" >> $html
echo "</body>" >> $html
echo "</html>" >> $html
echo "Report has been generated in ${HOME}/health_reports with file-name = $html. Report has also been sent to $email_add."
#Sending Email to the user
cat $html | mail -s "`hostname` - Daily System Health Report" -a "MIME-Version: 1.0" -a "Content-Type: text/html" -a "From: Shashank Srivastava <root@shashank.com>" $email_add
