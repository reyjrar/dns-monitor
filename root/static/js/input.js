/* AutoComplete Options */
var autocompleteOpts = {
	minChars:2,
	selectOnly:0,
	selectFirst:0,
	delay:200
};

function toggleFormElem( elm, enabled ) {
	if(!elm) {
		return;
	}

	if( elm.tagName && (
		elm.tagName == 'input' ||
		elm.tagName == 'textarea' ||
		elm.tagName == 'select'  )
	) {
		elm.disabled = !enabled;
	}
}

function ternClassApply( sectID, elmName, value, matchClass, noMatchClass ) {
	var elms = document.getElementsByName(elmName);
	sectID = '#'+sectID;

	var cbToggleClass = function() {
		var match = groupCompare( elms, value );

		if( match ) {
			$(sectID).removeClass(noMatchClass);
			$(sectID).addClass(matchClass);
		}
		else {
			$(sectID).removeClass(matchClass);
			$(sectID).addClass(noMatchClass);
		}
	};

	$( cbToggleClass );

	for(var i=0; i < elms.length; i++) {
		/* IE Fires change event too late, so we have to send onclick */
		$(elms[i]).bind( 'click', cbToggleClass);
		/* This will get onblur for all those tricky keyboard users */
		$(elms[i]).bind('change', cbToggleClass );
	}

}

function showDepSection( elmName, sectID, value ) {
	var elms = document.getElementsByName(elmName);

	sectID = '#'+sectID;
	var cbShowDep = function() {
		var show = groupCompare( elms, value );
		if( show ) {
			$(sectID).show();
		}
		else{
			$(sectID).hide();
		}

		descendDOM( $(sectID), toggleFormElem, show );
	};

	$( cbShowDep );

	for(var i=0; i < elms.length; i++) {
		/* IE Fires change event too late, so we have to send onclick */
		$(elms[i]).bind( 'click', cbShowDep);
		/* This will get onblur for all those tricky keyboard users */
		$(elms[i]).bind('change', cbShowDep );
	}
}
