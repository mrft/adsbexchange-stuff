// This JS should be copy pasted to the developer console, in order to record the DOM
// We use diffDOM to efficiently store each 'frame', instead of storing the whole DOM again every time

//'https://raw.githubusercontent.com/fiduswriter/diffDOM/gh-pages/diffDOM.js' FAILS because mimetype = text
var diffDOMurl = "https://cdn.jsdelivr.net/diffdom/0.0.1/diffdom.min.js"; var myScript = document.createElement('script'); myScript.setAttribute( 'src', diffDOMurl ); document.head.appendChild(myScript);
var storeDiffs = { diffs: [], timer: null, docPrev: document.documentElement.cloneNode( true ), origHtml: null };
function storeDiffsStart( ) {
	if ( ! storeDiffs.timer ) {
		storeDiffs.origHtml = document.documentElement.outerHTML
		storeDiffs.timer = setInterval( function() {
				e = document.documentElement
				storeDiffs.diffs.push( dd.diff( storeDiffs.docPrev, e ) )
				storeDiffs.docPrev = e.cloneNode( true )
			}, 10000 );
	}
}

function storeDiffsStop( ) {
	if ( storeDiffs.timer ) {
		clearInterval( storeDiffs.timer )
		storeDiffs.timer = null
	}
}



// We should be able to replay the 'recording' afterwards, by pasting this code (including the recorded data!) in the developer console later on