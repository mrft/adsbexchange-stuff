# adsbexchange-stuff

## What is it for

Downloading data from [absbexchange.com](https://www.adsbexchange.com/) and turning a filtered version (military flights above certain areas) into kml and xlsx files, for easier processing by humans.

## Prerequisites

You'll want to have [icedcoffeescript](http://maxtaco.github.io/coffee-script/) installed globally

<code>
npm install -g iced-coffee-script
</code>

(IcedCoffeeScript is basically coffeescript - a compile-to-js language - enhanced with await/defer keywords as an elegant solution to the 'nodejs callback hell' problem)

## Usage

If you run 

<code language="bash">./downloadtokmlandxlsx.sh 2016-11-27</code>

the file 2016-11-27.zip will be downloaded from adsbexchange, then it will be restructured and filtered (only military flights that flew over one of the positions in airports.cson) into a new json file that contains 1 record per flight.

This new file will be used as the basis for creating 2 'human-readable' files: 
* a kml file that can easily be imported as a new layer in a google map created in your google drive.
* a xlsx file that contains all the airplanes that have been spotted during that day

That's it.
