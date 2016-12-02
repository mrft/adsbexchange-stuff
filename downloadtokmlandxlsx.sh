#!/bin/bash

date=$1
./download.sh $date


restructuredfilename="$date.joined.json"

if [ -a "$restructuredfilename" ] ; then
	echo "Restructured JSON file exists already, so we'll not generate it again"
	sleep 2
else
	echo "Trying to generate $restructuredfilename"
	node --max-old-space-size=5000 restructure.js -d "$date" --filter --militaryOnly
fi


echo
echo "GENERATE kml file"
echo "-----------------"
echo

t=1
node --max-old-space-size=5000 joinedtokml.js -d "$date" --thin $t > "$date.kml" ; ls -hl "$date.kml"
size=$(ls -l "$date.kml" | awk -F " " '{print $5}')

# google maps only allows uploading a new layer of 5MB or less, so if the file is too big, filter out positions until it fits !!!
maxsize=5000000
while (( $size > $maxsize ))
do
	c=$( expr $size / $maxsize )
	echo ; echo "c=$c" ;  echo
	if (( $c > 2 )); then ((t*=$c)) ; else (( t++ )) ; fi
	#if (( $size > 8000000 )); then ((t*=2)) ; else (( t++ )) ; fi
	echo
	echo "Size of kml file is now: $size, try to make it smaller using $t..."
	echo
	node --max-old-space-size=5000 joinedtokml.js -d "$date" --thin $t > "$date.kml" ; ls -hl "$date.kml"
	size=$(ls -l "$date.kml" | awk -F " " '{print $5}')
done;


echo
echo "GENERATE xlsx file"
echo "------------------"
echo
node --max-old-space-size=5000 joinedtoxlsx.js -d "$date" ; ls -hl "$date.xlsx"
