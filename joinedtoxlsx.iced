###
  Use the joined file to generate an xml file for overlaying on google maps
###

fs = require( 'fs' )
util = require( 'util' )
moment = require( 'moment-timezone' )

# force Europe/Brussels timezone
moment.tz.setDefault( "Europe/Brussels" )

utils = require( './modules/utils.js' )

program = require('commander')

color = require( 'onecolor' )

Excel = require('xlsx-populate');



### # # # # # # # # # # # # # # # #
  
  USE 'commander' TO PARSE command-line OPTIONS

# # # # # # # # # # # # # # # # # ###
program
  .version('0.0.1')
  .option('-d, --date [dateString]', 'Which file you want to parse YYYY-MM-DD')
  .parse( process.argv )

if not program.thin?
  program.thin = 1



getStyleId = ( n ) ->
  return "style" + String.fromCharCode( "A".charCodeAt(0) + n )


# excel stores datetimes as a float: nr of days since 1900-01-01 00:00:00
moment2ExcelTimestamp = ( m ) ->
    excelEpoch = moment( '1900-01-03' ) # should be 1900-01-01 but there seems to be a leap-year bug somewhere
    unixEpoch = moment( 0 )
    secondsInADay = 24 * 60 * 60

    daysBetweenExcelAndUnixEpoch = unixEpoch.diff( excelEpoch, "days" )
    console.log( "daysBetweenExcelAndUnixEpoch = #{ daysBetweenExcelAndUnixEpoch }" )
    
    return m.unix() / secondsInADay + daysBetweenExcelAndUnixEpoch



# map = { id: <flightrecord containing Cos array of arrays> }
idMapJoined2Excel = ( m, dateString ) ->

  # Load the input workbook (the template) from file
  excelWorkbook = Excel.fromFileSync( "./Template.xlsx" )

  # Modify the workbook
  sheet = excelWorkbook.getSheet( "Blad1" )

  #for id, flight of m
  #  console.log( "-> #{id} #{flight.Coun}" )

  rowNum = 2
  for id, flight of m
    row = sheet.getRow( rowNum )
    colNum=1
    row.getCell( colNum++ ).setValue( id )
    # <name>Flight #{flight.Id} #{ flight.Cou } | #{ flight.From }->#{ flight.To }</name>
    # <description>Species (see enums.js): #{ flight.Species } Manufacturere: #{ flight.Man } Model: #{ flight.Mdl } RegNr: #{ flight.fReg } MLAT: #{ flight.Mlat }</description>
    row.getCell( colNum++ ).setValue( flight.Cou )
    row.getCell( colNum++ ).setValue( flight.From )
    row.getCell( colNum++ ).setValue( flight.To )
    row.getCell( colNum++ ).setValue( utils.speciesToString( flight.Species ) )
    row.getCell( colNum++ ).setValue( flight.Man )
    row.getCell( colNum++ ).setValue( flight.Mdl )
    t = flight.Cos
    start = moment( t[ 0 ][ 2 ] )
    end = moment( t[ t.length - 1 ][ 2 ] )
    # storing as a 'real' excel date doesn't work properly yet (and date formatting stored in template seems to get lost)
    # row.getCell( colNum++ ).setValue( moment2ExcelTimestamp( start ) )
    # row.getCell( colNum++ ).setValue( moment2ExcelTimestamp( end ) )
    row.getCell( colNum++ ).setValue( start.format( "YYYY-MM-DD hh:mm" ) )  # start as string
    row.getCell( colNum++ ).setValue( end.format( "YYYY-MM-DD hh:mm" ) )    # end as string

    #row.getCell( col++ ).setValue( flight.Mdl )
    rowNum++
    #console.log( "Row #{rowNum} finished" )

  # Write to file
  excelWorkbook.toFileSync( "./#{ dateString }.xlsx" )











# { aircraft.ID: aircraft with Cot = [ concatenated Cot arrays of current aircraft at any minute ]
idMapJoined =  {}



fn = "./#{ program.date }.joined.json"
console.error( "Trying to read file: #{fn}" )
idMapJoined = require( fn )

console.error( "Now let's try to get some stuff done with that map, that contains #{Object.keys( idMapJoined ).length }." )



idMapJoined2Excel( idMapJoined, "#{ program.date }" )

