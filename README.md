# adsbexchange-stuff

## What is it for

Downloading data from [absbexchange.com](https://www.adsbexchange.com/) and turning a filtered version (military flights above certain areas) into kml and xlsx files, for easier processing by humans.

## Prerequisites

You'll want to have [nodejs](http://maxtaco.github.io/coffee-script/) installed. I prefer to [install nodejs as a non-root user](https://degreesofzero.com/article/how-to-install-nodejs-as-a-non-root-user.html).

The code is written in IcedCoffeeScript, which is basically coffeescript - a compile-to-js language - enhanced with await/defer keywords as an elegant solution to the 'nodejs callback hell' problem.

## Getting started

The only thing you should do is run
<code>
npm install
</code>

after you have cloned the repository. This will install all dependencies, and call `npm run build` afterwards, so all the .iced files will be compiled to .js files.


## Usage

If you run 

<code language="bash">./downloadtokmlandxlsx.sh 2016-11-27</code>

the file 2016-11-27.zip will be downloaded from adsbexchange, then it will be restructured and filtered (only military flights that flew over one of the positions in airports.cson) into a new json file that contains 1 record per flight.

This new file will be used as the basis for creating 2 'human-readable' files: 
* a kml file that can easily be imported as a new layer in a google map created in your google drive.
* a xlsx file that contains all the airplanes that have been spotted during that day

That's it.
