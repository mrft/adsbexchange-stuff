fs = require( 'fs' )
JSONStream = require('JSONStream')
util = require( 'util' )

# virtual radar server enums: see https://github.com/vradarserver/vrs/blob/master/VirtualRadar.WebSite/Site/Web/script/vrs/enums.js
VRSenums = require( './VRS.js' )



`
function roughSizeOfObject( object ) {

    var objectList = [];
    var stack = [ object ];
    var bytes = 0;

    while ( stack.length ) {
        var value = stack.pop();

        if ( typeof value === 'boolean' ) {
            bytes += 4;
        }
        else if ( typeof value === 'string' ) {
            bytes += value.length * 2;
        }
        else if ( typeof value === 'number' ) {
            bytes += 8;
        }
        else if
        (
            typeof value === 'object'
            && objectList.indexOf( value ) === -1
        )
        {
            objectList.push( value );

            for( var i in value ) {
                stack.push( value[ i ] );
            }
        }
    }
    return bytes;
}
`

exports.roughSizeOfObject = roughSizeOfObject

exports.streamToString = ( str, callback ) ->
	fullData = ""

	str.on( 'data',  ( data ) ->
						fullData += data unless data?.length == 0
		)

	await str.on( 'end', defer() )
	callback( null, fullData )


exports.streamToJson = ( str, callback ) ->
	err = data = null

	str.pipe( JSONStream.parse( '*' ) )

	await exports.streamToString( str, defer( err, data ) )

	json = JSON.parse( data )
	callback( err, json )


exports.fileToString = ( fileName, callback ) ->
	rstr = fs.createReadStream( fileName, {} )

	exports.streamToString( rstr, callback )


exports.fileToJson = ( fileName, callback ) ->
	rstr = fs.createReadStream( fileName, {} )

	exports.streamToJson( rstr, callback )
	###
	fullData = ""

	rstr.on( 'data',  ( data ) ->
						fullData += data unless data.length == 0
		)

	await rstr.on( 'end', defer() )

	fd = JSON.parse( fullData )
	callback( null, fd )
	###

exports.jsonToFile = ( json, fileName, callback ) ->
	err = null
	await fs.writeFile( fileName, JSON.stringify( json, null, 2 ), defer(err) )
	callback( err )

exports.cos2ArrayOfArrays = ( cos = [] ) ->
	result = []
	for i in [0...cos.length] by 4
		result.push( [ cos[ i + 0 ], cos[ i + 1 ], cos[ i + 2 ], cos[ i + 3 ] ] )
	return result


exports.speciesToString = ( sp ) ->
  for k,v of VRSenums.Species
    if v == sp
      return k

