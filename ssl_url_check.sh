  #! /bin/bash
#Author : - Bibhuti Narayan
#Date : - July 2021

#Checking URL list provide or not to check SSL validity.
if [ $# = 0 ]
then
  echo "Please provide URL list as a argument."
  exit 1
fi

#Check openssl installed or not
whereis openssl &>/dev/null &
if [ $? != 0 ]
then
  echo "Required package "openssl" not installed or configured."
  exit 1
fi


#Creating a directory if it doesn't exist to store reports first, for easy maintenance.
if [ ! -d ${PWD}/url_reports ]
then
  mkdir ${PWD}/url_reports
fi
html="${PWD}/url_reports/url-Report-`date +%y%m%d`-`date +%H%M`.html"
email_add="change this to yours"

#url checking from given list
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
if [ $days -lt 30 ]
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
echo "</center>" >> $html
echo "</body>" >> $html
echo "</html>" >> $html
echo "Report has been generated in ${PWD}/url_reports with file-name = $html. Report has also been sent to $email_add."
#Sending Email to the user
#cat $html | mail -s "`hostname` - Daily System Health Report" -a "MIME-Version: 1.0" -a "Content-Type: text/html" -a "From: Bibhuti Narayan <root@localhost>" $email_add
