/* Code to find the first parent node of tagName */
function findFirstParent( elmType, child ) {
	var parent = child.parentNode;
	if( parent ) {
		if( parent.tagName.toLowerCase() == elmType.toLowerCase() ) {
			return parent;
		}
		return findFirstParent( elmType, parent );
	}
	return null;
}

/* Recurse through the children, calling a function at each child */
function descendDOM ( elm, cb, arg ) {
	if( !$(elm) ) {
		alert(' elm not defined' );
		return true;
	}
	// Call the callback
	cb( $(elm), arg );

	// call descendDOM() for the children
	var kids = $(elm).children();
	for(var i=0; i < kids.length; i++) {
		descendDOM(kids[i], cb, arg);
	}
	
	// Base case, return!
	return true;
}

/* Compare the current value of groupings */
function groupCompare( group, value ) {
	var currVal = null;
	var debug = null;

	if( group.length == 1 ) {
		if( group[0].type == "checkbox" && group[0].checked == true ) {
			currVal = group[0].value;
		}
		else if( group[0].type == "radio" && group[0].checked == true) {
			currVal = group[0].value;
		}
	}
	else {
		for(var i = 0; i < group.length; i++) {
			if( group[i].type == "checkbox" && group[i].checked == true ) {
				currVal = group[i].value;	
			}
			else if( group[i].type == "radio" && group[i].checked == true ) {
				currVal = group[i].value;	
			}
		}
	}
	return currVal == value;
}

