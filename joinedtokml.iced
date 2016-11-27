###
	Use the joined file to generate an xml file for overlaying on google maps
###

fs = require( 'fs' )
util = require( 'util' )
moment = require( 'moment-timezone' )
jsonpatch = require( 'fast-json-patch' )
unzip = require( 'unzip' )

# force Europe/Brussels timezone
moment.tz.setDefault( "Europe/Brussels" )

utils = require( './modules/utils.iced' )

program = require('commander')

color = require( 'onecolor' )


### # # # # # # # # # # # # # # # #
  
  USE 'commander' TO PARSE command-line OPTIONS

# # # # # # # # # # # # # # # # # ###
program
  .version('0.0.1')
  .option('-d, --date [dateString]', 'Which file you want to parse YYYY-MM-DD')
  .option('-t, --thin <n>', 'Remove half of the points from the kml file', parseInt )
  .parse( process.argv )

if not program.thin?
	program.thin = 1


# generates a partial kml string representing the given flight
# it will contain individual placemarks for every flight's position
# it wil contain a LINE placemark that draws the line through all the positions
flight2KmlPlaceMarks = ( flight, styleUrl ) ->
	# console.log( "flight2KmlPlaceMarks #{ flight.Id }" )
	lineString = ""
	trailPlaceMarks = ""
	#trail
	t = flight.Cos
	for i in [0...t.length]
		# ANR: 51.189442, 4.460278
		if i > 0
			prev_i = i - 1

		if ( i % program.thin ) == 0
			lineString += "#{ t[ i ][ 1 ] },#{ t[ i ][ 0 ] },#{ t[ i ][ 3 ] }\n"
		if ( i % 500 ) == 0 or i == t.length or ( t[ i ][ 3 ] < 2000 and ( i % ( 20 * program.thin ) ) == 0 )
			trailPlaceMarks += "<Placemark>
							      <name>#{ moment.unix( t[ i ][ 2 ] / 1000 ).format( "YY-MM-DD hh:mm:ss" ) } | #{t[i][3]}ft</name>
							      <description>[#{flight.Id}]</description>
							      <Point id=\"#{t[i][2]}\">
							        <extrude>0</extrude>
							        <altitudeMode>clampToGround</altitudeMode>
							        <coordinates>#{t[i][1]},#{t[i][0]},#{t[i][3]}</coordinates>
							      </Point>
							    </Placemark>
							"
			#altitudeMode:	<!-- kml:altitudeModeEnum: clampToGround, relativeToGround, or absolute -->
			#coordinates:	<!-- lon,lat[,alt] -->

	linePlaceMark = "<Placemark>
						  <name>Flight #{flight.Id} #{ flight.Cou } | #{ moment.unix( t[ 0 ][ 2 ] / 1000 ).format( "YYYY-MM-DD hh:mm" ) } -> #{ moment.unix( t[ t.length - 1 ][ 2 ] / 1000 ).format( "YYYY-MM-DD hh:mm" ) } | #{ flight.From }->#{ flight.To }</name>
						  <description>Species: #{ utils.speciesToString( flight.Species ) } Manufacturere: #{ flight.Man } Model: #{ flight.Mdl } RegNr: #{ flight.fReg } MLAT: #{ flight.Mlat }</description>
						  <styleUrl>##{ styleUrl }</styleUrl>
						  <LineString>
						    <extrude>1</extrude>
						    <tessellate>1</tessellate>
						    <altitudeMode>relativeToGround</altitudeMode>
						    <coordinates>
						    #{lineString}
						    </coordinates>
						  </LineString>
						</Placemark>
					"

	return """#{linePlaceMark}
			  #{trailPlaceMarks}
		   """

	# console.error( "Linestring = #{lineString}" )


getStyleId = ( n ) ->
	return "style" + String.fromCharCode( "A".charCodeAt(0) + n )

# map = { id: <flightrecord containing Cos array of arrays> }
idMapJoined2Kml = ( m ) ->
	kmlSnippets = []


	c = color( 'hsv( 0, 100%, 100% )' )
	styles = ""
	for i in [0..25]
			color = c.hue( i * 4 / 100 ).hex().substr(1)
			#console.error( "Color = #{color}" )
			styles += 	"<Style id=\"#{ getStyleId( i ) }\">
					      <LineStyle>
					        <color>7f#{ color }</color>
					        <width>2</width>
					      </LineStyle>
					      <PolyStyle>
					        <color>aa#{ color }</color>
					      </PolyStyle>
					    </Style>\n"


	console.log( """
					<?xml version="1.0" encoding="UTF-8"?>
					<kml xmlns="http://www.opengis.net/kml/2.2">
					  <Document>
					    <name>Flights #{ program.date }</name>
					    <description>Flight</description>
					    #{ styles }
					    <Style id="yellowLineGreenPoly">
					      <LineStyle>
					        <color>7f00ffff</color>
					        <width>2</width>
					      </LineStyle>
					      <PolyStyle>
					        <color>7f00ff0f</color>
					      </PolyStyle>
					    </Style>
					    <Style id="shortestDistance">
					      <LineStyle>
					        <color>ff0000ff</color>
					        <width>2</width>
					      </LineStyle>
					      <PolyStyle>
					        <color>ff0000ff</color>
					      </PolyStyle>
					    </Style>
					"""	)


	counter = 0
	for id, flight of m
		console.log( flight2KmlPlaceMarks( flight, getStyleId( counter % 25 ) ) )
		#console.log( flight2KmlPlaceMarks( flight, "yellowLineGreenPoly" ) )
		counter++

	# add one point just in case everything is empty
	if Object.keys( m ).length == 0
		KleineBrogel = { lat: 51.169724, lng: 5.4711109 }
		console.log( "<Placemark>
						      <name>No flights found...</name>
						      <description></description>
						      <Point id=\"x\">
						        <extrude>0</extrude>
						        <altitudeMode>clampToGround</altitudeMode>
						        <coordinates>#{ KleineBrogel.lng },#{ KleineBrogel.lat },#{0}</coordinates>
						      </Point>
						    </Placemark>
						" )

	console.log( """
						</Document>
					</kml>
				""" )
	return null














# { aircraft.ID: aircraft with Cot = [ concatenated Cot arrays of current aircraft at any minute ]
idMapJoined =  {}



fn = "./#{ program.date }.joined.json"
console.error( "Trying to read file: #{fn}" )
idMapJoined = require( fn )

console.error( "Now let's try to get some stuff done with that map, that contains #{Object.keys( idMapJoined ).length }." )



idMapJoined2Kml( idMapJoined )



