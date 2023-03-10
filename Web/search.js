function AKDocumentSearchController() {
	this.results = [];
	this.highlightedResultIndex = -1;
	this.active = false;
	this.contentOffset = this.currentContentOffset();
}

AKDocumentSearchController.prototype.setSearchResultIndicatorInsets = function(searchResultIndicatorInsets) {
	this.searchResultIndicatorInsets = searchResultIndicatorInsets;
}

AKDocumentSearchController.prototype.find = function(text) {
	var results = [];
	var ranges = [];
	
	this.cancel();
	
	if(text.length == 0) {
		return 0;
	}
	
	while(window.find(text, false, false, false, false, false, false)) {
		var range = document.getSelection().getRangeAt(0);
		ranges.push(range);
	}
	
	for(var rangeIndex = 0; rangeIndex < ranges.length; ++rangeIndex) {
		var range = ranges[rangeIndex];
		
		var highlighter = document.createElement("span");
		
		highlighter.className = "articlekit-searchresult";
		
        try {
            range.surroundContents(highlighter);
		} catch(e) {
            continue;
        }

		results.push(highlighter);
	}
	
	this.results = results;
	
	if(results.length > 0) {
		this.highlightResultAtIndex(0);
	}
	
	document.getSelection().removeAllRanges();
	
	return results.length;
}

AKDocumentSearchController.prototype.cancel = function() {
	for(var resultIndex = 0; resultIndex < this.results.length; ++resultIndex) {
		var resultNode = this.results[resultIndex];
		
		resultNode.parentNode.insertBefore(
			resultNode.firstChild,
			resultNode);
		resultNode.parentNode.removeChild(resultNode);
	}
	
	this.results = [];
	this.highlightedResultIndex = -1;
	this.highlightedRangeIndex = 0;
}

AKDocumentSearchController.prototype.highlightResultAtIndex = function(resultIndex) {
	var highlightedElement = document.getElementById("articlekit-highlighted-searchresult");
	
	if(resultIndex >= 0 && resultIndex < this.results.length) {
		var resultNode = this.results[resultIndex];
	
		if(resultNode == highlightedElement) {
			return;
		}
		
		if(highlightedElement) {
			highlightedElement.removeAttribute("id");
		}
		
		resultNode.id = "articlekit-highlighted-searchresult";
		this.highlightedResultIndex = resultIndex;
		
		this.scrollNodeIntoViewIfNeeded(resultNode);
		
		var rect = resultNode.getBoundingClientRect();
		var rectString = "{{" + rect.left + "," + rect.top + "},{" + rect.width + "," + rect.height + "}}";

		document.location = "x-articlekit-internal://documentDidHighlightSearchResult?" +
			"index=" + resultIndex + "&" +
			"resultCount=" + this.results.length + "&" +
			"rect=" + encodeURIComponent(rectString);
	} else {
		if(highlightedElement) {
			highlightedElement.removeAttribute("id");
		}
		
		this.highlightedResultIndex = -1;
	}
}

AKDocumentSearchController.prototype.findPrevious = function() {
	var resultIndex = this.highlightedResultIndex - 1;
	
	if(resultIndex < 0) {
		resultIndex = this.results.length - 1;
	}
	
	this.highlightResultAtIndex(resultIndex);
}

AKDocumentSearchController.prototype.findNext = function() {
	var resultIndex = this.highlightedResultIndex + 1;
	
	if(resultIndex >= this.results.length) {
		resultIndex = 0;
	}
	
	this.highlightResultAtIndex(resultIndex);
}

AKDocumentSearchController.prototype.setActive = function(active) {
	if(active != this.active) {
		this.active = active;
        
        if(active) {
        	window.addEventListener("scroll", function(event) {
				documentSearchController.contentOffset = documentSearchController.currentContentOffset();
			}, false);
        } else {
        	window.removeEventListener("scroll", this, false);
            this.cancel();
        }
	}
}

AKDocumentSearchController.prototype.scrollNodeIntoViewIfNeeded = function(node) {
	node.scrollIntoViewIfNeeded(true);
	
	var contentOffset = this.currentContentOffset();
	var nodeRect = node.getBoundingClientRect();
	
	var footerViewHeight = this.footerViewHeight();
	
	var contentRectOffset = document.getContentRectOffset();
	
	if(nodeRect.bottom > window.innerHeight - footerViewHeight) {
		var horizontalOffset = (contentRectOffset.y + nodeRect.top + nodeRect.height * 0.5) - window.innerHeight * 0.5 + footerViewHeight;
		
		window.scrollTo(0.0, horizontalOffset);
		
		contentOffset.y = contentRectOffset.y;
	}
	
//	if(contentOffset.x != this.contentOffset.x ||
//	   contentOffset.y != this.contentOffset.y) {
//		document.location = "x-articlekit-internal://flashScrollIndicators";
//	}
	
	this.contentOffset = contentOffset;
}

AKDocumentSearchController.prototype.currentContentOffset = function() {
	return document.getContentRectOffset();
}

AKDocumentSearchController.prototype.footerViewHeight = function() {
	if(this.searchResultIndicatorInsets) {
		return searchResultIndicatorInsets.bottom;
	}
	
	return Math.abs(window.orientation) == 90.0 ?
		32.0 :
		44.0;
}

var documentSearchController = new AKDocumentSearchController();
