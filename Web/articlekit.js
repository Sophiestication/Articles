articlekit_iPad = (navigator.platform == "iPad");
articlekit_SupportsTouches = ("createTouch" in document);

Element.prototype.hasClassName = function(A) { return new RegExp("(?:^|\\s+)" + A + "(?:\\s+|$)").test(this.className) };
Element.prototype.addClassName = function(A) { if(!this.hasClassName(A)) { this.className = [this.className, A].join(" ") } };
Element.prototype.removeClassName = function(B) { if(this.hasClassName(B)) { var A = this.className; this.className = A.replace(new RegExp("(?:^|\\s+)" + B + "(?:\\s+|$)", "g"), " ") } };
Element.prototype.toggleClassName = function(A) { this[this.hasClassName(A) ? "removeClassName": "addClassName"](A) };

// parseURI

function parseUri (str) {
	var	o   = parseUri.options,
		m   = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
		uri = {},
		i   = 14;

	while (i--) uri[o.key[i]] = m[i] || "";

	uri[o.q.name] = {};
	uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
		if ($1) uri[o.q.name][$1] = $2;
	});

	return uri;
};

parseUri.options = {
	strictMode: false,
	key: ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"],
	q:   {
		name:   "queryKey",
		parser: /(?:^|&)([^&=]*)=?([^&]*)/g
	},
	parser: {
		strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
		loose:  /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
	}
};

// AKRect

function AKRect(x, y, width, height) {
	this.x = x;
	this.y = y;
	this.width = width;
	this.height = height;
}

AKRect.prototype.getIntersection = function(b) {
	var x0 = Math.max(this.x, b.x);
	var x1 = Math.min(this.x + this.width, b.x + b.width);

	if (x0 <= x1) {
		var y0 = Math.max(this.y, b.y);
		var y1 = Math.min(this.y + this.height, b.y + b.height);

		if (y0 <= y1) {
			return new AKRect(x0, y0, x1 - x0, y1 - y0);
		}
	}

	return null;
}

function hasClass(ele,cls) {
	return ele && ele.className.match(new RegExp('(\\s|^)'+cls+'(\\s|$)'));
}

function addClass(ele,cls) {
	if (ele) if (!this.hasClass(ele,cls)) ele.className += " "+cls;
}

function removeClass(ele,cls) {
	if(!ele) { return; }
	
	if (hasClass(ele,cls)) {
		var reg = new RegExp('(\\s|^)'+cls+'(\\s|$)');
		ele.className=ele.className.replace(reg,' ');
	}
}

Array.prototype.foreach = function(callback) {
	for(var k=0; k<this.length; k++) {
		callback(k, this[k]);
	}
}

Object.prototype.foreach = function(callback) {
	for(var k in this) {
		if(typeof this[k] != 'function') {
			callback(k, this[k]);
		}
	}
}

Node.prototype.getParentOrSelfLink = function() {
	if(this.webkitMatchesSelector(":link") || this.hasAttribute("onclick") || hasClass(this, "table-cell")) {
		return this;
	}
	
	if(this.parentElement) {
		return this.parentElement.getParentOrSelfLink();
	}
	
	return null;
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

Node.prototype.getFirstAncestorOfClass = function(className) {
	var parentNode = this.parentElement;
	
	if(parentNode) {
		if(hasClass(parentNode, className)) {
			return parentNode;
		} else {
			return parentNode.getFirstAncestorOfClass(className);
		}
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

Node.prototype.getFirstAncestorOrSelfMatchingSelector = function(selector) {
	if(this.webkitMatchesSelector(selector)) {
		return this;
	}
	
	var parentNode = this.parentElement;
	
	if(parentNode) {
		return parentNode.getFirstAncestorOrSelfMatchingSelector(selector);
	}

	return null;
}


Node.prototype.getPreviousSiblingMatchingSelector = function(selector) {
	var previousSibling = this.previousElementSibling;
	
	if(previousSibling) {
		if(previousSibling.webkitMatchesSelector(selector)) {
			return previousSibling;
		} else {
			return previousSibling.getPreviousSiblingNotMatchingSelector(selector);
		}
	}
	
	return null;
}


Node.prototype.getPreviousSiblingNotMatchingSelector = function(selector) {
	var previousSibling = this.previousElementSibling;
	
	if(previousSibling) {
		if(previousSibling.webkitMatchesSelector(selector)) {
			return previousSibling.getPreviousSiblingNotMatchingSelector(selector);
		} else {
			return previousSibling;
		}
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

Document.prototype.elementFromPointIsUsingViewPortCoordinates = function() {
	if(window.pageYOffset > 0) {     // page scrolled down
		return (this.elementFromPoint(0, window.pageYOffset + window.innerHeight -1) == null);
	} else if (window.pageXOffset > 0) {   // page scrolled to the right
		return (this.elementFromPoint(window.pageXOffset + window.innerWidth -1, 0) == null);
	}
	
    return false; // no scrolling, don't care
}

Document.prototype.elementFromDocumentPoint = function(x, y) {
	if(this.elementFromPointIsUsingViewPortCoordinates()) {
		var coord = documentCoordinateToViewportCoordinate(x, y);
		return this.elementFromPoint(coord.x, coord.y);
	} else {
		return this.elementFromPoint(x, y);
	}
}

Document.prototype.elementFromViewportPoint = function(x, y) {
    if(this.elementFromPointIsUsingViewPortCoordinates()) {
		return this.elementFromPoint(x, y);
	} else {
		var coord = viewportCoordinateToDocumentCoordinate(x, y);
        return this.elementFromPoint(coord.x, coord.y);
	}
}

Document.prototype.getContentRectOffset = function() {
//	if(document.webkitBuild >= 534.46) {
//		return new WebKitPoint(window.scrollX, -window.scrollY);
//	}

	if(document.webkitBuild < 533.17) {
		return new WebKitPoint(0.0, 0.0);
	}
	
	return new WebKitPoint(window.scrollX, window.scrollY);
}

Document.prototype.getLinkFromPoint = function(x, y) {
	var node = document.elementFromViewportPoint(x, y);
    var link = node ? node.getParentOrSelfLink() : null;
    
    if(!link) {
    	var padding = 11.0;
		link = this.getLinkFromRect(x - padding, y - padding, padding * 2.0, padding * 2.0);
    }
    
    return link;
}

Document.prototype.getLinkFromRect = function(x, y, width, height) {
	var node = document.elementFromViewportPoint(x + width * 0.5, y + height * 0.5);
	
	var link = null;

	if(node) {
		link = node.getParentOrSelfLink();
		
		if(!link && node != document.documentElement && node != document.body) {
			var targetRect = new AKRect(x, y, width, height);
			
			var childNodes = node.querySelectorAll(":link");
			
			for(var childIndex=0; childIndex<childNodes.length; ++childIndex) {
				var childNode = childNodes[childIndex];
				var rects = childNode.getClientRects();
				
				for(var rectIndex=0; rectIndex<rects.length; ++rectIndex) {
					var rect = rects[rectIndex];
					
					// var contentRectOffset = document.getContentRectOffset();
					
					var intersectionRect = targetRect.getIntersection(
						new AKRect(rect.left /* + contentRectOffset.x */, rect.top /* + contentRectOffset.y */, rect.width, rect.height));
					
					if(intersectionRect != null && intersectionRect.height > 0) {
						return childNode;
					}
				}
			}
		}
	}
	
	if(!link && node) {
		link = node.getFirstAncestorOrSelfOfClass("table-placeholder");
	}

	return link;
}

// AKDocumentController
function AKDocumentController() {
	this.chapterIndexVisible = false;
	this.highlightedLink = null;
	this.highlighter = null;
    
    var documentController = this;
	
	document.addEventListener("DOMContentLoaded", function() {
		// documentController.adjustDocumentFontSize();
		documentController.restructureDocument();

		if(articlekit_SupportsTouches) {
			document.location = "x-articlekit-internal://documentDidLoad";
        }
	}, false);
	
	document.webkitBuild = this.getWebKitBuild();
}

AKDocumentController.prototype.getWebKitBuild = function() {
	var build = 0;
   
    var regexp = /WebKit\/([\d.]+)/;
    var result = regexp.exec(navigator.userAgent);

    if(result) {
        build = parseFloat(result[1]);
    }

    return build;
}

AKDocumentController.prototype.adjustDocumentFontSize = function() {
	// adjust the document font size
    var documentURI = parseUri(document.location);
   
    if(documentURI && documentURI.queryKey) {
    	var documentFontSize = documentURI.queryKey["documentFontSize"];
        
        if(documentFontSize) {
        	addClass(document.body, documentFontSize);
        }
    }
}

AKDocumentController.prototype.restructureDocument = function() {
	if(navigator.platform == "iPad") { addClass(document.documentElement, "articlekit-ipad"); }

	this.restructureReferencesChapter();
	this.restructureSimpleImagePreviews();
	this.restructureImagePreviews();

    this.restructureTablePlaceholders();
	
	if(hasClass(document.body, "articlekit-tablesheet")) {
		this.restructureTableSheets();
	}
}

AKDocumentController.prototype.restructureSimpleImagePreviews = function() {
	var imagePreviews = document.querySelectorAll("#mw-content-text > .floatleft > .image");
	
	for(var imagePreviewIndex = 0; imagePreviewIndex < imagePreviews.length; ++imagePreviewIndex) {
		var imagePreview = imagePreviews[imagePreviewIndex];
		this.restructureSimpleImagePreview(imagePreview);
	}
}

AKDocumentController.prototype.restructureSimpleImagePreview = function(imagePreview) {
	if(!imagePreview) { return; }
	
	var wrapper = imagePreview.parentElement;
	if(wrapper.children.length > 1) { return; }
	
	wrapper.removeClassName("floatleft");
	wrapper.addClassName("floatright");
}

AKDocumentController.prototype.restructureImagePreviews = function() {
	var imagePreviews = document.querySelectorAll(".thumb.center, .thumb.tnone, .thumb.tleft, .thumbnail-placeholder");
	
	for(var imagePreviewIndex = 0; imagePreviewIndex < imagePreviews.length; ++imagePreviewIndex) {
		var imagePreview = imagePreviews[imagePreviewIndex];
		this.restructureImagePreview(imagePreview);
	}
}

AKDocumentController.prototype.restructureImagePreview = function(imagePreview) {
	if(!imagePreview) { return; }
	
    if(imagePreview.hasAttribute("style") && !hasClass(imagePreview, "thumbnail-placeholder")) {
		imagePreview.removeAttribute("style");
	}

	var childs = document.querySelectorAll("div[style], .thumbinner, .image, img");
	for(var childIndex = 0; childIndex < childs.length; ++childIndex) {
		var child = childs[childIndex];
		child.removeAttribute("style");
		child.removeAttribute("width");
		child.removeAttribute("height");
	}
	
	if(imagePreview.webkitMatchesSelector(".center, .tnone")) {
		var previousSibling = imagePreview.getPreviousSiblingNotMatchingSelector(".tleft, .tright, .tnone, .center2, .floatleft, .floatright, .thumb, .image");
	
		if(previousSibling && previousSibling.webkitMatchesSelector("#jump-to-nav, .rellink, h1, h2, h3")) {
			removeClass(imagePreview, "tnone");
			removeClass(imagePreview, "center");
			
			addClass(imagePreview, "tright");
		}

		if(imagePreview.getPreviousSiblingMatchingSelector(".tright, .floatright") || imagePreview.getFirstAncestorOfClass("tright")) {
			removeClass(imagePreview, "tnone");
			removeClass(imagePreview, "center");
			
			addClass(imagePreview, "tright");
		}
	}

	if(imagePreview.webkitMatchesSelector(".tleft")) {
		removeClass(imagePreview, "tleft");
		addClass(imagePreview, "tright");
	}
    
    var context = this;
    var listener = imagePreview.querySelector("img");

    if(!listener) { listener = imagePreview.getParentOrSelfLink(); }
    if(!listener) { listener = imagePreview; }
    
    listener.onclick = null;
    
    listener.addEventListener("click", function(event) {
		var link = event.target.getParentOrSelfLink();
		var metadata = context.getLinkMetadata(link);
            
        document.location = "x-articlekit-internal://presentItem?metadata=" + encodeURIComponent(metadata);
    }, true);
}

AKDocumentController.prototype.restructureTablePlaceholders = function() {
	var tablePlaceholders = document.querySelectorAll(".table-placeholder");
	
	for(var tablePlaceholderIndex = 0; tablePlaceholderIndex < tablePlaceholders.length; ++tablePlaceholderIndex) {
		var tablePlaceholder = tablePlaceholders[tablePlaceholderIndex];
		this.restructureTablePlaceholder(tablePlaceholder);
	}
}

AKDocumentController.prototype.restructureTablePlaceholder = function(tablePlaceholder) {
	if(!tablePlaceholder) { return; }
    
    var context = this;
    
    tablePlaceholder.addEventListener("click", function(event) {
    	var link = event.target.getParentOrSelfLink();
        
        if(!link) {
        	link = event.target.getFirstAncestorOrSelfOfClass("table-placeholder");
        }
        
        if(!link) { return; }
        
        var metadata = encodeURIComponent(context.getLinkMetadata(link));
        
        var action = "x-articlekit-internal://presentItem";
        if(metadata) {
        	action += "?metadata=" + metadata;
        }
        
    	document.location = action;
    }, false);

	var sibling = this.getPreviousTablePlaceholderOrImageSibling(tablePlaceholder);
	if(sibling && hasClass(sibling, "tright")) {
		addClass(tablePlaceholder, "tright");
	}
}

AKDocumentController.prototype.getPreviousTablePlaceholderOrImageSibling = function(tablePlaceholder) {
	if(!tablePlaceholder) { return null; }

	var sibling = tablePlaceholder.previousElementSibling;

	if(sibling && sibling.tagName == "TABLE") { sibling = this.getPreviousTablePlaceholderOrImageSibling(sibling); }
	if(sibling && hasClass(sibling, "dablink")) { sibling = this.getPreviousTablePlaceholderOrImageSibling(sibling); }
	if(sibling && hasClass(sibling, "table-placeholder")) { return sibling; }
	if(sibling && hasClass(sibling, "tright")) { return sibling; }

	return null;
}

AKDocumentController.prototype.restructureReferencesChapter = function() {
	var references = document.querySelectorAll(".reference");

	for(var referenceIndex = 0; referenceIndex < references.length; ++referenceIndex) {
		var referenceNode = references[referenceIndex];
		referenceNode.parentNode.removeChild(referenceNode);
	}
	
	references = document.querySelectorAll(".references, .reflist");

	for(var referenceIndex = 0; referenceIndex < references.length; ++referenceIndex) {
        var node = references[referenceIndex];
		
		while(node.parentNode &&
		     (node.parentNode.id != "bodyContent" &&
			 !hasClass(node.parentNode, "mw-content-ltr") &&
			 !hasClass(node.parentNode, "mw-content-rtl"))) {
            node = node.parentNode
        }
		
        var previousSibling = node ?
			node.previousElementSibling :
			null;
					
		var metadataNode = null;
			
		if(previousSibling && (hasClass(previousSibling, "metadata") || hasClass(previousSibling, "noprint|portal"))) {
			metadataNode = previousSibling;
			previousSibling = metadataNode.previousElementSibling;
		}

		if(previousSibling && (previousSibling.tagName == "H2" || previousSibling.tagName == "H3")) {
			addClass(previousSibling, "hidden");
			addClass(node, "hidden");
			addClass(metadataNode, "hidden");

			if(previousSibling.tagName == "H3") {
				var sibling = previousSibling.previousElementSibling;
				if(sibling.tagName == "H2") { addClass(sibling, "hidden"); }
			}
        }
    }
}

AKDocumentController.prototype.restructureTableSheets = function() {
	var tableHeaders = document.querySelectorAll(".articlekit-tablesheet > table .fn, .articlekit-tablesheet > table th.summary");
	
	for(var tableHeaderIndex = 0; tableHeaderIndex < tableHeaders.length; ++tableHeaderIndex) {
		var tableRow = tableHeaders[tableHeaderIndex].getFirstAncestorOrSelfWithTagName("tr");
		
		if(tableRow) {
			tableRow.parentNode.removeChild(tableRow);
		}
	}
}

AKDocumentController.prototype.getMetadataForLinkAtPoint = function(x, y) {
	var targetLink = document.getLinkFromPoint(x, y);

	if(targetLink) {
		var metadata = this.getLinkMetadata(targetLink);
		return metadata;
	}
	
	return null;
}

AKDocumentController.prototype.getLinkMetadata = function(targetLink) {
	if(targetLink) {
		var summary = targetLink.getFirstAncestorOrSelfOfClass("article-summary");

		if(summary) {
			return this.getSummaryMetadata(summary, targetLink);
		}

		if(hasClass(targetLink, "image")) {
			return this.getImageMetadata(targetLink);
		}
		
		if(hasClass(targetLink, "external|ext|extiw")) {
			return this.getExternalLinkMetadata(targetLink);
		}
		
		if(hasClass(targetLink, "table-cell")) {
			return this.getTableCellMetadata(targetLink);
		}
		
		return this.getArticleLinkMetadata(targetLink);
	}
	
	return null;
}

AKDocumentController.prototype.getArticleLinkMetadata = function(targetLink) {
	var metadata = new Object();
	
	metadata["type"] = "regular";
	metadata["URL"] = targetLink.href;
	metadata["rects"] = this.getClientRectStrings(targetLink);
	metadata["readLater"] = this.getReadLaterMetadata(targetLink);
	
	return JSON.stringify(metadata);
}

AKDocumentController.prototype.getExternalLinkMetadata = function(targetLink) {
	var metadata = new Object();
	
	metadata["type"] = "external";
	metadata["URL"] = targetLink.href;
	metadata["rects"] = this.getClientRectStrings(targetLink);
	
	return JSON.stringify(metadata);
}

AKDocumentController.prototype.getTableCellMetadata = function(targetLink) {
	var metadata = new Object();
	
	metadata["type"] = "table-cell";
	metadata["URL"] = targetLink.href;
	metadata["id"] = targetLink.id;
	
	return JSON.stringify(metadata);
}

AKDocumentController.prototype.getSummaryMetadata = function(summary, targetLink) {
	var metadata = new Object();
	
	metadata["type"] = "table-cell";
	metadata["URL"] = targetLink.href;
	metadata["id"] = summary.id;
	
	return JSON.stringify(metadata);
}

AKDocumentController.prototype.getImageMetadata = function(targetImage) {
	var imageNode = targetImage.querySelector("img");

	var rect = imageNode.getBoundingClientRect();
	
	var borderLeft = parseFloat(window.getComputedStyle(imageNode, null).getPropertyValue("border-left-width"));
	var borderTop = parseFloat(window.getComputedStyle(imageNode, null).getPropertyValue("border-top-width"));
	var borderRight = parseFloat(window.getComputedStyle(imageNode, null).getPropertyValue("border-right-width"));
	var borderBottom = parseFloat(window.getComputedStyle(imageNode, null).getPropertyValue("border-bottom-width"));

	var imageID = this.getImageID(targetImage);
	
	var metadata = new Object();
	
	metadata["type"] = "image";
	
	var contentRectOffset = document.getContentRectOffset();
	metadata["boundingRect"] = "{{" + (rect.left + contentRectOffset.x) + "," + (rect.top + contentRectOffset.y) + "},{" + rect.width + "," + rect.height + "}}";
	metadata["rect"] = "{{" + (rect.left + borderLeft + contentRectOffset.x) + "," + (rect.top + borderTop + contentRectOffset.y) + "},{" + (rect.width - borderLeft - borderRight) + "," + (rect.height - borderTop - borderBottom) + "}}";
	
	metadata["URL"] = targetImage.href;
	metadata["previewURL"] = imageNode.src;
	metadata["id"] = imageID;
	metadata["caption"] = this.getImagePreviewCaption(imageID);
	
	return JSON.stringify(metadata);
}

AKDocumentController.prototype.getImageID = function(node) {
	if(node.hasAttribute("id")) {
		if(node.id.match("^AKImage") == "AKImage") {
			return node.id;
		}
	}
	
	var parentNode = node.parentNode;
	
	if(parentNode) {
		return this.getImageID(parentNode);
	}
	
	return null;
}

AKDocumentController.prototype.getReadLaterMetadata = function(targetLink) {
	// Retrieve the surounding text blocks
	var selection = document.getSelection();
	
	selection.removeAllRanges();
	
	var targetRange = document.createRange();
	targetRange.selectNodeContents(targetLink);
	
	selection.addRange(targetRange);
	selection.modify("extend", "backward", "sentence");
	
	var leadingRange = selection.getRangeAt(0);
	
	var targetText = targetRange.toString();
	var targetTextOffset = null;
	
	// iOS 5.0 or later
	if(document.webkitBuild >= 534.46 && document.webkitBuild < 536.26) {
		targetTextOffset = leadingRange.toString().length;
	} else {
		targetTextOffset = leadingRange.toString().length - targetText.length;
	}
	
	selection.modify("extend", "forward", "sentence");
	
	var followingRange = selection.getRangeAt(0);
	
	targetRange.setStart(leadingRange.startContainer, leadingRange.startOffset);
	targetRange.setEnd(followingRange.endContainer, followingRange.endOffset);
	
	if(targetLink.getFirstAncestorOrSelfWithTagName("li") != null) {
		targetRange.setEndBefore(followingRange.endContainer);
	}

	// Retrieve the client rects for our text ranges
	var rects = this.getClientRectStrings(targetRange);
	var boundingRect = this.getBoundingClientRectString(targetRange);

	// Cleanup
	selection.removeAllRanges();
	
	// Special case for table rows and preview captions
	var parentElement = targetLink.getFirstAncestorOrSelfMatchingSelector(".thumbcaption, tr");
	
	if(parentElement != null) {
		boundingRect = this.getBoundingClientRectString(parentElement);
		rects = [ boundingRect ];
	}
	
	// Make the metadata hash
	var metadata = new Object();
	
	metadata["boundingRect"] = boundingRect;
	metadata["rects"] = rects;
	metadata["text"] = targetRange.toString();
	metadata["targetTextRange"] = "{" + targetTextOffset + ", " + targetText.length + "}";

	return metadata;
}

AKDocumentController.prototype.getChapterIndexMetadata = function() {
	var chapters = document.querySelectorAll("h2");
	var metadata = new Array();
	
	for(var nodeIndex=0; nodeIndex<chapters.length; ++nodeIndex) {
		var node = chapters[nodeIndex];
		var chapterMetadata = new Object();
		
		if(node.id.length == 0) {
			node.id = "articlekit-chapter-" + nodeIndex;
		}
		
		chapterMetadata["id"] = node.id;
		chapterMetadata["tag"] = node.tagName;
		chapterMetadata["offset"] = node.offsetTop;

		metadata.push(chapterMetadata);
	}
	
	return JSON.stringify(metadata);
}

AKDocumentController.prototype.getClientRectStrings = function(element) {
	var rects = element.getClientRects();
	var rectStrings = new Array();
	
	var contentRectOffset = document.getContentRectOffset();
	
	for(var rectIndex=0; rectIndex<rects.length; ++rectIndex) {
		var rect = rects[rectIndex];
		
		rectStrings.push(
			"{{" + (rect.left + contentRectOffset.x) + "," + (rect.top + contentRectOffset.y) + "},{" + rect.width + "," + rect.height + "}}"
		);
	}
	
	return rectStrings;
}

AKDocumentController.prototype.getBoundingClientRectString = function(element) {
	var rect = element.getBoundingClientRect();
	var contentRectOffset = document.getContentRectOffset();
	
	return "{{" + (rect.left + contentRectOffset.x) + "," + (rect.top + contentRectOffset.y) + "},{" + rect.width + "," + rect.height + "}}";
}

AKDocumentController.prototype.getImagePreviewCaption = function(imagePreviewID) {
	if(!imagePreviewID) { return ""; }
	
	var previewNode = document.getElementById(imagePreviewID);
	var captionNode = previewNode.querySelector(".thumbcaption");
	
	if(!captionNode) {
		var thumbnailNode = previewNode.getFirstAncestorOrSelfOfClass("thumbinner");
	
		if(thumbnailNode) {
			captionNode = thumbnailNode.querySelector(".thumbcaption");
		}
	}
	
	if(captionNode) {
		return this.getTextForNode(captionNode);
	}

	var galleryboxNode = previewNode.getFirstAncestorOrSelfOfClass("gallerybox");
	
	if(galleryboxNode) {
		var galleryText = galleryboxNode.querySelector(".gallerytext");
		
		if(galleryText) {
			return this.getTextForNode(galleryText);
		}
	}
	
	return "";
}

AKDocumentController.prototype.setImagePreview = function(thumbnailID, imageURLString, markupString) {
	var controller = this;
	var delay = 0.125;
	
	var image = new Image();
	
	var completion = function() {
		var placeholderNode = document.getElementById(thumbnailID);
		var imageNode = controller.getImageElementFromHTML(markupString);

		var img = imageNode.querySelector("#" + thumbnailID + "Element");
		if(!img) { img = imageNode.querySelector("img[src='" + thumbnailID + "']"); } // legacy fallback
		if(!img) { img = imageNode; }

        if(img) {
        	img.src = imageURLString;
        }

		if(placeholderNode && placeholderNode.parentNode) {
        	placeholderNode.parentNode.replaceChild(imageNode, placeholderNode);
        	controller.restructureImagePreview(imageNode);
		}

		if(img) {
			var backgroundElement = document.createElement("span");
			backgroundElement.className = "ak-image-background userSelectionDisabled userInteractionDisabled";

			var style = window.getComputedStyle(img, null);
			backgroundElement.style.width = style.getPropertyValue("width");
			backgroundElement.style.height = style.getPropertyValue("height");

			img.parentElement.appendChild(backgroundElement);
		}
	}
	
	image.onload = function() { window.setTimeout(completion, delay); };
	image.src = imageURLString;
	
	if(image.complete) {
		window.setTimeout(completion, delay);
	}
}

AKDocumentController.prototype.getImageElementFromHTML = function(HTML) {
	var wrapper = document.createElement("span");
	
	wrapper.innerHTML = HTML;
	
	if(wrapper.childNodes.length == 0) {
		return null;
	}
	
	var element = wrapper.childNodes[0];
	
	return element;
}

AKDocumentController.prototype.getTextForNode = function(node) {
	var range = document.createRange();
	range.selectNodeContents(node);
	return range.toString();
}

AKDocumentController.prototype.getSelectedText = function() {
	return window.getSelection().toString();
}

AKDocumentController.prototype.getSelectedHTML = function() {
	var selection = window.getSelection();
	
	if(selection.rangeCount > 0) {
		var fragment = selection.getRangeAt(0).cloneContents();
	
		var images = fragment.querySelectorAll("img[articlekit_src]");
		
		for(var imageIndex = 0; imageIndex < images.length; ++imageIndex)  {
			var image = images[imageIndex];
			image.src = image.getAttribute("articlekit_src");
		}
	
		var nodes = fragment.childNodes;
		var markupString = "";
		
		for(var nodeIndex = 0; nodeIndex < nodes.length; ++nodeIndex)  {
			var node = nodes[nodeIndex];
			
			markupString += node.outerHTML ?
				node.outerHTML :
				node.textContent;
		}
		
		return markupString;
	}
	
	return null;
}

AKDocumentController.prototype.presentFontSizeBezel = function(event) {
	if(event.scale > 1.25) {
		document.location = "x-articlekit-internal://increaseFontSize";
	} else if(event.scale <= 0.75) {
		document.location = "x-articlekit-internal://decreaseFontSize";
	}
}

var articleKitDocumentController = new AKDocumentController();
