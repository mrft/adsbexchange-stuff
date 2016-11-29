###
  Used to transform from zip-file (1 file per minute) to a format that contain a map per aircraft.Id
###


fs = require( 'fs' )
util = require( 'util' )
moment = require( 'moment-timezone' )
jsonpatch = require( 'fast-json-patch' )
unzip = require( 'unzipper' )
# async = require( 'async' )
JSONStream = require('JSONStream')

# force Europe/Brussels timezone
moment.tz.setDefault( "Europe/Brussels" );

utils = require( './modules/utils.iced' )

program = require('commander')

require( 'require-cson' )


### # # # # # # # # # # # # # # # #
  
  USE 'commander' TO PARSE command-line OPTIONS

# # # # # # # # # # # # # # # # # ###
program
  .version( '0.0.1' )
  .option( '-d, --date [dateString]', 'Which file you want to parse YYYY-MM-DD' )
  .option( '-m, --militaryOnly', 'Only keep the records flagged as military' )
  .option( '-f, --filter', 'Only keep flights that flew over Kleine-Brogel, Volkel or Buchel airport.' )
  .parse( process.argv )



# Mil  Boolean  Yes  True if the aircraft appears to be operated by the military.



# { aircraft.ID: [ aircraft @ 0000, aircraft @ 0001 ] 
idMap =  {}



addMinuteObjToIdMap = ( obj ) ->
  for aircraft in obj?.acList
    if aircraft.Mil or not program.militaryOnly
      hasCos = aircraft.Cos?
      transformedCos = if hasCos then utils.cos2ArrayOfArrays( aircraft.Cos ) else null
      if not idMap[ aircraft.Id ]?
        # console.log( aircraft.Id )
        aircraft.Cos = transformedCos if hasCos
        idMap[ aircraft.Id ] = aircraft
      else
        cosSoFar = idMap[ aircraft.Id ].Cos || []
        # use the latest values, and join the Cos
        joinedAircraft = aircraft

        # console.log( "Id #{aircraft.Id} already found..." )
        if hasCos
          for c in transformedCos
            # if timestamp equal to latest, don't add
            if ( cosSoFar.length == 0 or cosSoFar[ cosSoFar.length - 1 ][ 2 ] != c[ 2 ] )
              cosSoFar.push( c )

        joinedAircraft.Cos = cosSoFar
        idMap[ aircraft.Id ] = joinedAircraft




# WE ARE GOING TO ONLY KEEP THE FLIGHTS THAT HAVE BEEN SPOTTED AROUND THESE AREAS
airports = require( './airports.cson' )


# for the area around one of the points, using an area that adds these to lat and long should be good enough?
latDiff = 0.2
lngDiff = 0.4


isAround = ( point, referencePoint ) ->
  # console.error( "Is #{ JSON.stringify( point ) } araound #{ JSON.stringify( referencePoint ) }?" )
  return ( ( referencePoint.lat - latDiff ) < point.lat < ( referencePoint.lat + latDiff ) ) and ( ( referencePoint.lng - lngDiff ) < point.lng < ( referencePoint.lng + lngDiff ) ) 




console.error( "Give nodejs extra memory to work with if it goes out-of-mem, like this:" )
console.error( "iced --nodejs '--max-old-space-size=3000' restructure.iced -d 2016-10-14 " )
console.error( "Don't forget about the useful options -militaryOnly and --filter !" )

filename = "#{ program.date }.zip"
console.error( "Trying to unzip: #{filename}" )
counter = 0
tempfilecounter = 0

#allObjects = []

readStream = fs.createReadStream( filename ).pipe( unzip.Parse() )
await readStream
  .on( 'entry', ( entry ) ->
    counter++
    fileName = entry.path
    type = entry.type # 'Directory' or 'File' 
    size = entry.size

    console.error( "Trying to parse #{fileName}" )
    # DEBUG !!!
    #if counter > 60
    #  #entry.autodrain()
    #  readStream.removeListener( "entry", () ->
    #                      console.error( "Removed listener..." )
    #  )
    #  return


    err = obj = null
    await utils.streamToJson( entry, defer( err, obj ) )
    # console.log( "Parsed #{fileName}: #{util.inspect(obj).substr(0,40)}" )
    #console.log( "Size = #{ Math.round( utils.roughSizeOfObject( obj ) / 1000000 ) }" )

    entry.autodrain()


    addMinuteObjToIdMap( obj )
    

    mu = process.memoryUsage()
    mu.rss = Math.round( mu.rss / 1000000)
    mu.heapTotal = Math.round( mu.heapTotal / 1000000 )
    mu.heapUsed = Math.round( mu.heapUsed / 1000000 ) 
    console.error( " #{ util.inspect( mu ) } --- idMap contains #{ Object.keys( idMap ).length } = " ) #{ Math.round( utils.roughSizeOfObject( idMap ) / 1000000 ) if counter % 30 == 0}MB 
  )
  .on( 'end', () ->
    console.error( "End does seem to fire, but let's wait for close event..." )
    # defer() 
  )
  .on( 'error', ( error ) ->
          console.log( "Error: #{ error }" )
    )
  .on( 'close', defer() )


# OLD VERSION starting from an already unzipped zip file (folder containing a lot of json files)
###
startTimeForFile = program.date
# each minute of the day
parallel = 5
upperLimit = 24*60
for i in [0...upperLimit] by parallel
  f = ( cb ) ->
    data = {}
    await for j in [0...parallel]
      k = i + j
      if k < upperLimit
        currentTimeForFile = moment( startTimeForFile ).add( k, "minutes" )
        currentFileName = "#{ currentTimeForFile.format( 'YYYY-MM-DD/YYYY-MM-DD-HHmm' ) }Z.json"
        console.log( "Trying to read file: #{currentFileName}" )

        data[ j ] = null
        utils.fileToJson( currentFileName, defer( err, data[ j ] ) )
        if err?
          console.error( err )

    for j in [0...parallel]
      addMinuteObjToIdMap( data[ j ] )
    cb()

  await f( defer() )
  # console.log( "Run #{i} finished" )
###



console.error( "Finished building idMap, now try to save to disk" )



#fn = "#{ program.date }.restructured.json"
fn = "./#{ program.date }.joined.json"
wstr = fs.createWriteStream( fn, {} )
#jsonstr = JSONStream.stringifyObject().pipe( wstr )
#for k, v of idMap
#  jsonstr.write( [ k, v ] )
#jsonstr.end()


# OUTPUT to stdout
wstr.write( "{\n" )
#console.log( "{" )
first = true
for id, f of idMap
  # check if the Cos array contains points that are in the given regions
  trailInOneOfRegions = false
  if program.filter
    if f.Cos?
      for r in f.Cos
        p = { lat: r[ 0 ], lng: r[ 1 ] }
        #if ( Buchel.lat - latDiff < p.lat < Buchel.lat + latDiff ) and ( Buchel.lng - lngDiff < p.lng < Buchel.lng + lngDiff )
        #  console.error( JSON.stringify( r ) )
        if r[ 3 ] <= 5000 and ( isAround( p, airport ) for airport in airports )
          trailInOneOfRegions = true
          break
  if trailInOneOfRegions or not program.filter
    wstr.write( "#{ if first then '' else ', ' }#{ JSON.stringify( id ) }: #{ JSON.stringify( f ) }\n" )
    #console.log( "#{ if first then '' else ', ' }#{ JSON.stringify( k ) }: #{ JSON.stringify( v ) }" )
    first = false
wstr.write( "}" )
#console.log( "}" )
  



#await utils.jsonToFile( idMap, fn, defer( err ) )
#if err?
#  console.error( "Error writing file: #{fn}" )
#  process.exit( -1 )
