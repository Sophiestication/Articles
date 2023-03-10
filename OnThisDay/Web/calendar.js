function addEvent(groupID, markup) {
	var lastEvent = document.querySelector('#group-' + groupID + ' ul li:last-child')
	
	var newEvent = document.createElement('li');
	lastEvent.parentNode.insertBefore(newEvent, lastEvent);
	newEvent.outerHTML = markup;
}

function getEventCount(groupID) {
	var count = document.querySelectorAll('#group-' + groupID + ' ul li').length;
	return count > 0 ?
		count - 1 :
		0;
}

function hideMoreElement(groupID) {
	var moreElement = document.querySelector('#group-' + groupID + ' ul li.more');
	moreElement.parentNode.removeChild(moreElement);
}

function setMoreElementLabel(groupID, label) {
	var moreElement = document.querySelector('#group-' + groupID + ' ul li.more a');
	moreElement.innerHTML = label;
}

function showMessage(messageText, messageDetailText) {
	var message = document.getElementById('message');
	
	removeClass(message, 'networkError');
	removeClass(message, 'hidden');
	
	var calendar = document.getElementById('calendar');
	addClass(calendar, 'hidden');
	
	message.querySelector('.text').innerHTML = messageText;
	message.querySelector('.detailText').innerHTML = messageDetailText;
}

function showNetworkError(messageText, messageDetailText) {
	showMessage(messageText, messageDetailText);

	var message = document.getElementById('message');
	addClass(message, 'networkError');
}

function hideMessage() {
	var calendar = document.getElementById('calendar');
	removeClass(calendar, 'hidden');

	var message = document.getElementById('message');
	addClass(message, 'hidden');
}

function messageShown() {
	var message = document.getElementById('message');
	return hasClass(message, 'hidden') ? "0" : "1";
}

function getMetadataFromElementAtPoint(x, y) {
	var node = elementFromViewportPoint(x, y);
    if(!node) { return null; }
    
    var eventNode = node.getFirstAncestorOrSelfWithTagName("li");
    if(!eventNode) { return null; }
    
    var eventGroup = eventNode.getFirstAncestorOrSelfOfClass("event-group");
    if(!eventGroup) { return null; }
    
    var yearNode = eventNode.querySelector(".year");
    if(!yearNode) { return null; }
    
    var contentNode = eventNode.querySelector(".content");
    if(!contentNode) { return null; }
    
    var linkNodes = contentNode.querySelectorAll("a[href]:not(.new)");
    var links = new Array();
    
    for(var linkIndex = 0; linkIndex < linkNodes.length; ++linkIndex) {
    	links.push(linkNodes[linkIndex].getAttribute("href"));
    }
    
    var metadata = {
    	"year": yearNode.innerText,
        "content": contentNode.innerText,
        "kind": eventGroup.getAttribute("kind"),
        "links": links
    };
    
    return JSON.stringify(metadata);
}

function hasClass(ele,cls) {
	return ele.className.match(new RegExp('(\\s|^)'+cls+'(\\s|$)'));
}
 
function addClass(ele,cls) {
	if (!this.hasClass(ele,cls)) ele.className += " "+cls;
}
 
function removeClass(ele,cls) {
	if (hasClass(ele,cls)) {
    	var reg = new RegExp('(\\s|^)'+cls+'(\\s|$)');
		ele.className=ele.className.replace(reg,' ');
	}
}

Node.prototype.getFirstAncestorOrSelfWithTagName = function(tagName) {
	if(this.tagName.toLowerCase() == tagName) {
		return this;
	}
	
	var parentNode = this.parentElement;
	
	if(parentNode) {
		return parentNode.getFirstAncestorOrSelfWithTagName(tagName);
	}

	return null;
}

Node.prototype.getFirstAncestorOrSelfOfClass = function(className) {
	if(hasClass(this, className)) {
		return this;
	}
	
	var parentNode = this.parentElement;
	
	if(parentNode) {
		return parentNode.getFirstAncestorOrSelfOfClass(className);
	}

	return null;
}

function documentCoordinateToViewportCoordinate(x,y) {
	var coordinate = new Object();
	
    coordinate.x = x - window.pageXOffset;
	coordinate.y = y - window.pageYOffset;
	
    return coordinate;
}

function viewportCoordinateToDocumentCoordinate(x,y) {
	var coordinate = new Object();
  
	coordinate.x = x + window.pageXOffset;
	coordinate.y = y + window.pageYOffset;
  
	return coordinate;
}

function elementFromPointIsUsingViewPortCoordinates() {
	if(window.pageYOffset > 0) {     // page scrolled down
		return (document.elementFromPoint(0, window.pageYOffset + window.innerHeight -1) == null);
	} else if (window.pageXOffset > 0) {   // page scrolled to the right
		return (document.elementFromPoint(window.pageXOffset + window.innerWidth -1, 0) == null);
	}
	
    return false; // no scrolling, don't care
}

function elementFromDocumentPoint(x, y) {
	if(this.elementFromPointIsUsingViewPortCoordinates()) {
		var coord = documentCoordinateToViewportCoordinate(x, y);
		return document.elementFromPoint(coord.x, coord.y);
	} else {
		return document.elementFromPoint(x, y);
	}
}

function elementFromViewportPoint(x, y) {
    if(this.elementFromPointIsUsingViewPortCoordinates()) {
		return document.elementFromPoint(x, y);
	} else {
		var coord = viewportCoordinateToDocumentCoordinate(x, y);
        return document.elementFromPoint(coord.x, coord.y);
	}
}
