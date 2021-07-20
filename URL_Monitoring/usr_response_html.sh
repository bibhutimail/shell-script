#! /bin/bash
#Author : - Bibhuti Narayan
#Date : - July 2021
if [ $# = 0 ]
then
  echo "Please provide URL list as a argument."
  exit 1
fi

#Check openssl installed or not
whereis curl &>/dev/null &
if [ $? != 0 ]
then
  echo "Required package "curl" not installed or configured."
  exit 1
fi


#Creating a directory if it doesn't exist to store reports first, for easy maintenance.
if [ ! -d ${PWD}/url_reports ]
then
  mkdir ${PWD}/url_reports
fi
html="${PWD}/url_reports/url-Report-`date +%y%m%d`-`date +%H%M`.html"
email_add="Update_with_your_ID"

#url checking from given list
url_list=$1
rm -rf /tmp/url_responce_list.txt

while read line; do
echo -n "$line " >> /tmp/url_responce_list.txt
curl -sI $line | head -n 1 |cut -d " " -f 2 >> /tmp/url_responce_list.txt
done < $url_list

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
echo "<h2><span class=\"label label-primary\">Report Generated from : `hostname`</span></h2>" >> $html
echo "<h3><legend>Platinum Application Report</legend></h3>" >> $html
echo "</center>" >> $html
echo "</fieldset>" >> $html
echo "<center>" >> $html
echo "<h2><span class=\"label label-info\">URL Details : </span></h2>" >> $html
echo "<h3><span class=\"label label-info\">Response-Code:- 302 is ok ( URL Redirected ) : </span></h3>" >> $html
echo "<br>" >> $html
echo "<table class=\"pure-table pure-table-bordered\">" >> $html
echo "<thead>" >> $html
echo "<tr>" >> $html
echo "<th>URL Name</th>" >> $html
echo "<th>Response-Code</th>" >> $html
echo "<th>Status</th>" >> $html
echo "<th>Remarks</th>" >> $html
echo "</tr>" >> $html
echo "</thead>" >> $html
echo "<tbody>" >> $html


while read url Response Status remarks;
do
	if [ $Response -eq 302 ] || [ $Response -eq 200 ]
	then
		echo "<td>$url</td>" >> $html
		else
		echo "<td style="background-color:#FF0000" > $url </td>" >> $html
	fi
  echo "<td>$Response</td>" >> $html
  
	if [ $Response -eq 302 ]
	then
		echo "<td>Moved Temporarily</td>" >> $html
		else
		echo "<td>$Status</td>" >> $html
	fi
echo "<td>$remarks</td>" >> $html
echo "</tr>" >> $html
done < /tmp/url_responce_list.txt

echo "</tbody>" >> $html
echo "</table>" >> $html
echo "<br>" >> $html
echo "</center>" >> $html
echo "<h5><legend>For any Modification/Addition contact:- <Put_Script_Auther_Name></legend></h5>" >> $html
echo "</body>" >> $html
echo "</html>" >> $html
echo "Report has been generated in ${PWD}/url_reports with file-name = $html. Report has also been sent to $email_add."
#Sending Email to the user
cat $html | /usr/sbin/sendmail -s "`hostname` - HTTPS URL validity Report" -a "MIME-Version: 1.0" -a "Content-Type: text/html" -a "From: Bibhuti Narayan <root@localhost>" $email_add
