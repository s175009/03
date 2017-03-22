volantis@sup1:/usr/local/bin$ cat office_climat_checker.sh
#!/bin/bash

temp_lo='19'
temp_hi='26'
humi_lo_l0='25'
humi_lo='30'
humi_hi='65'
mail_recipients="office.krakow@pega.com"
#mail_recipients="krzysztof.mrozek@pega.com"
mail_subject="Office temperature/humidity warning"


function getData() {
#query="select s.sensor as sensor, l.location, cast(avg(s.temp) as decimal(4,2)) as temp, cast(avg(s.humi) as decimal(4,2)) as humi from remote_sensors s, sensor_location l where s.sensor = l.sensor and s.time  > DATE_SUB(now(), INTERVAL 20 MINUTE) group by s.sensor having (temp not between $temp_lo and $temp_hi) or (humi not between $humi_lo and $humi_hi) order by l.location, s.sensor"
query="select s.sensor as sensor, l.location, cast(avg(s.temp) as decimal(4,2)) as temp, cast(avg(s.humi) as decimal(4,2)) as humi from remote_sensors s, sensor_location l where s.sensor = l.sensor and s.time  > DATE_SUB(now(), INTERVAL 20 MINUTE) group by s.sensor having (temp not between $temp_lo and $temp_hi) or ((location = 'level1' and humi not between $humi_lo and $humi_hi) or (location = 'level0' and humi not between $humi_lo_l0 and $humi_hi)) order by l.location, s.sensor"

OIFS="$IFS" ; IFS=$'\n' ; oset="$-" ; set -f

while IFS="$OIFS" read -a l
do
  printf "<tr><td>%s</td><td><a href='http://sup1.rpega.com/office/charts.php?sensor=%s'>%s</a></td><td>%s</td><td>%s</td></tr>\n" ${l[1]} ${l[0]} ${l[0]} ${l[2]} ${l[3]}
done < <(mysql -B -N -u root test -e "${query}")
set -"$oset" ; IFS="$OIFS" ; unset oset
}

function printHTML() {
/bin/echo -e "
<html>
 <head>
  <style>
        body {font-family:verdana; font:12px;}
        p {font-weight:bold;}
        .tab {border-collapse:collapse; font:11px; background-color:#ffc;}
        .tab th, .tab td {border: 1px solid black;}
        .b0 {font-weight: bold;}
        .a1 {background-color:#dda;}
        .b1 {background-color:#dda;font-weight:bold;}
        th {background: #ddd;}
        td {vertical-align: top; padding: 2px 7px 2px 7px;border-bottom:1px solid #dda}
        .big {font: 18px;}
  </style>
 </head>
 <body>
        <p>This is a warning notification from one of the sensors. Average parameters of the air quality fell out of the defined thresholds for the past 20 minutes.</p>
        <table class="tab">
                <tr><th>Level</th><th>Sensor</th><th>Avg. Temp</th><th>Avg. Humid</th></tr>\n"
printf "\t\t%s\n" "${@}"
echo -e "       </table>
        <p>Threshold values:<br />Temperature out of $temp_lo-$temp_hi degrees range<br />Humidity out of $humi_lo-$humi_hi%RH range</p>
 </body>
</html>
"
}

DATA=$(getData)

if [ ! -z "${DATA}" ]; then

        printHTML ${DATA} | mail -a"From:Office Temperature Checker<pega.office.climatchecker@gmail.com>" -a"BCC:piotr.bak@pega.com" -a "Content-type: text/html" -a "X-Priority: 1 (Highest)" -e  -s "$mail_subject" $mail_recipients
fi 
