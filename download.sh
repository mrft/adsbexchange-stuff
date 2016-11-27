#!/bin/bash

date=$1
url=http://history.adsbexchange.com/Aircraftlist.json/${date}.zip

filename="$date.zip"

if [ -a "$filename" ] ; then
	echo "File exists already, so we'll not download it again"
	sleep 2
else
	echo Trying to download $url
	curl $url > $filename
fi