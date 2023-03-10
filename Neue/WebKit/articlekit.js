// Foundation

Element.prototype.hasClassName = function(className) { return this.classList.contains(className); };
Element.prototype.addClassName = function(className) { this.classList.add(className); };
Element.prototype.removeClassName = function(className) { this.classList.remove(className); };

Element.prototype.getAncestorOrSelfHavingClassName = function(className) {
	if(this.hasClassName(className)) { return this; }
	if(this.parentElement) { return this.parentElement.getAncestorOrSelfHavingClassName(className); }
	
	return null;
};

Element.prototype.getAncestorOrSelfByTagName = function(tagName) {
	if(this.tagName.toLowerCase() == tagName) { return this; }
	if(this.parentElement) { return this.parentElement.getAncestorOrSelfByTagName(tagName); }

	return null;
}

Element.prototype.isHeadingElement = function() {
	var tagName = this.tagName.toLowerCase();
	return tagName == "h1" || tagName == "h2" || tagName == "h3" || tagName == "h4" || tagName == "h5" || tagName == "h6";
}

Array.prototype.foreach = function(callback) {
	for(var k=0; k<this.length; k++) {
		callback(k, this[k]);
	}
}

NodeList.prototype.foreach = function(callback) {
	for(var k=0; k<this.length; k++) {
		callback(k, this.item(k));
	}
}

Object.prototype.foreach = function(callback) {
	for(var k in this) {
		if(typeof this[k] != "function") {
			callback(k, this[k]);
		}
	}
}

String.prototype.endsWith = function(suffix) {
    return this.indexOf(suffix, this.length - suffix.length) !== -1;
}

// UUID

function newUUID() {
	return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
    	var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
    	return v.toString(16);
	});
}

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

// ARKArticle

function ARKArticle(articleURL) {
	this.articleURL = articleURL;
	this.articleURI = parseUri(articleURL);
	
	this.identifier = newUUID();
	
	this.obsoleteElements = [];
	this.images = [];
}

ARKArticle.prototype.load = function() {
	var xhr = new XMLHttpRequest();
	var context = this;
	
	xhr.onreadystatechange = function() {
		if(xhr.readyState != XMLHttpRequest.DONE) { return; }
		
		if((xhr.status >= 200 && xhr.status < 300) || xhr.status == 0) {
			var response = null;
			
			if(xhr.responseXML || xhr.responseText.length > 0) {
				response = context.parseArticle(xhr);
			}
			
			if(response) {
				context.completion(response, "success");
			} else {
				context.failure(xhr, "error");
			}
		} else {
			context.failure(xhr, "error");
		}
	};
	
	xhr.open("GET", this.articleURL);
	
	xhr.setRequestHeader("User-Agent", "ArticleKit/3.0");
	xhr.setRequestHeader("Cookie", "stopMobileRedirect=true");
	xhr.setRequestHeader("X-Frame-Options", "deny");
	xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
	
	xhr.responseType = "document";
	// xhr.overrideMimeType("text/html");
	
	xhr.send();
	
	this.xhr = xhr;
}

ARKArticle.prototype.parseArticle = function(xhr) {
	var responseDocument = xhr.response;
	
	if(!responseDocument) {
		responseDocument = (new DOMParser()).parseFromString(xhr.responseText, "text/html");
	}
	
	if(!responseDocument) { return null; }
	
	// keep the document title
	this.title = responseDocument.title;
	
	// make a new document fragment from our article document
	var fragment = document.createDocumentFragment();
	
	responseDocument.getElementById("content").childNodes.foreach(function(index, node) {
		if(node.nodeType != Node.ELEMENT_NODE) { return; }
		if(node.nodeName.toLowerCase() == "script") { return; }
		
		fragment.appendChild(document.importNode(node, true));
	});
	
	delete responseDocument;
	
	// parse localizations
	this.localizations = this.parseLocalizations(fragment);
	
	// parse table of contents
	this.tableOfContents = this.parseTableOfContents(fragment);
	
	// parse the geo coordinate
	this.coordinate = this.parseGeoLocation(fragment);
	
	// restructure the article DOM
	this.restructureArticle(fragment);
	
	// make a new content element
	var content = document.createElement("article");
	
	var bodyContent = fragment.querySelector("#mw-content-text, .mw-content-ltr, .mw-content-rtl");
	
	content.setAttribute("dir", bodyContent.getAttribute("dir"));
	content.setAttribute("lang", bodyContent.getAttribute("lang"));
	
	var currentSection = document.createElement("section");
	
	// add the article title
	var articleTitle = fragment.querySelector(".firstHeading");
	
	if(articleTitle) {
		articleTitle.cloneNode(true);
		articleTitle.removeAttribute("id");

		currentSection.appendChild(articleTitle);
		
		this.title = articleTitle.innerText;
	}
	
	// add the remaining content elements
	bodyContent.childNodes.foreach(function(index, node) {
		if(node.nodeType != Node.ELEMENT_NODE) { return; }
		
		if(node.isHeadingElement()) {
			/*var scrollView = document.createElement("aside");
			scrollView.className = "ak-scrollview";

			var contentView = document.createElement("img");
			contentView.src = "http://upload.wikimedia.org/wikipedia/commons/5/51/Niagra_Falls-wide_image-NPS.jpg";
			contentView.width = 960;
			contentView.height = 148;
			contentView.className = "ak-content";
			scrollView.appendChild(contentView);

			currentSection.appendChild(scrollView);*/

			content.appendChild(currentSection);
			currentSection = document.createElement("section");
		}
		
		currentSection.appendChild(bodyContent.removeChild(node));
	});
	
	if(currentSection) {
		content.appendChild(currentSection);
	}
	
	return content;
}

ARKArticle.prototype.parseLocalizations = function(fragment) {
	return {};
}

ARKArticle.prototype.parseTableOfContents = function(fragment) {
	return {};
}

ARKArticle.prototype.parseGeoLocation = function(fragment) {
	var coordinates = fragment.querySelector("#coordinates");
	
	if(coordinates) {
		var geoNode = fragment.querySelector(".geo");
		
		if(geoNode) {
			this.coordinates = geoNode.innerText;
			coordinates.parentElement.removeChild(coordinates);
		}
	}
	
	return null;
}

ARKArticle.prototype.restructureArticle = function(fragment) {
	this.restructureHeadlines(fragment);
	this.restructureQuotes(fragment);
	this.restructureQuoteBoxes(fragment);
	this.restructureTables(fragment);
	this.restructureImages(fragment);
	this.restructureGalleries(fragment);
	
	// remove all collected nodes marked as obsolete
	this.obsoleteElements.foreach(function(index, node) {
		if(node.parentNode) {
			node.parentNode.removeChild(node);
		}
		
		delete node;
	});
	this.obsoleteElements = [];
	
	this.restructureLinks(fragment);
	this.restructureImageSourceLinks(fragment);
}

ARKArticle.prototype.restructureHeadlines = function(fragment) {
	fragment.querySelectorAll(".mw-headline").foreach(function(index, node) {
		var parentElement = node.parentElement;
			
		var nodeID = node.getAttribute("id");
		node.removeAttribute("id");
		parentElement.setAttribute("id", nodeID);
			
		parentElement.innerHTML = node.innerHTML;
	});
}

ARKArticle.prototype.restructureTables = function(fragment) {
	var context = this;

	fragment.querySelectorAll("table").foreach(function(index, node) {
		var parent = node.parentElement;
		var shouldUnwrap = false;

		var parentStyle = parent ?
			parent.style :
			null;
		
		if(parentStyle && parentStyle.getPropertyCSSValue("float")) {
			var floatStyle = parentStyle.getPropertyCSSValue("float");
			
			if(floatStyle == "left") {
				node.addClassName("align-left");
			} else if(floatStyle == "right") {
				node.addClassName("align-right");
			}
			
			if(parent.firstElementChild == parent.lastElementChild) { // only child?
				shouldUnwrap = true;
			}
		}
		
		if(parent && parent.tagName.toLowerCase() == "center") {
			node.addClassName("align-center");
			
			if(parent.firstElementChild == parent.lastElementChild) { // only child?
				shouldUnwrap = true;
			}
		}
		
		var nodeStyle = node.style;
			
		if(nodeStyle && nodeStyle.getPropertyCSSValue("float")) {
			if(nodeStyle.getPropertyCSSValue("float") == "left") {
				node.addClassName("align-left");
			} else if(nodeStyle.getPropertyCSSValue("float") == "right") {
				node.addClassName("align-right");
			}
		}
		
		if(shouldUnwrap) {
			parent.removeChild(node);
			parent.insertAdjacentElement("BeforeBegin", node);
			parent.parentElement.removeChild(parent);
		}
	});
}

ARKArticle.prototype.restructureImages = function(fragment) {
	var context = this;
	
	fragment.querySelectorAll("img").foreach(function(index, node) {
		var parent = node.parentElement;
		
		if(parent && parent.hasClassName("image")) {
			context.restructureThumbnailImage(node, parent);
		} else {
			context.restructureImage(node);
		}
	});
}

ARKArticle.prototype.restructureImage = function(image) {
	var imageURI = parseUri(image.src);
	
	if(this.removeImageIfNeeded(imageURI, image)) {
		return;
	}
	
	image.src = this.articleURI.protocol + "://" + imageURI.host + imageURI.path; // TODO
}

ARKArticle.prototype.restructureThumbnailImage = function(image, anchor) {
	var imageURI = parseUri(image.src);

	if(this.removeImageIfNeeded(imageURI, image)) {
		return;
	}
	
	var thumbnail = image.getAncestorOrSelfHavingClassName("thumb");
	if(!thumbnail) { return this.restructureImage(image); }
	
//	var containedInCaption = image.getAncestorOrSelfHavingClassName("thumbcaption") != null;
//	if(containedInCaption) { return this.restructureImage(image); }
	
	// make a new figure aka ak-image
	var figure = document.createElement("figure");
	var figureClassNames = [ "ak-image", "ak-loading" ];
	
	var shouldFloatWithContent = false;
	
	if(thumbnail) {
		if(thumbnail.hasClassName("tleft")) { figureClassNames.push("align-left"); shouldFloatWithContent = true; }
		if(thumbnail.hasClassName("tright")) { figureClassNames.push("align-right"); shouldFloatWithContent = true; }
		if(thumbnail.hasClassName("tcenter")) { figureClassNames.push("align-center"); }
	}
	
	if(!shouldFloatWithContent) {
		if(image.getAncestorOrSelfHavingClassName("floatleft")) { figureClassNames.push("align-left"); }
		if(image.getAncestorOrSelfHavingClassName("floatright")) { figureClassNames.push("align-right"); }
		if(image.getAncestorOrSelfHavingClassName("center")) { figureClassNames.push("align-center"); }
	}
	
	figure.className = figureClassNames.join(" ");
	
	var newPreview = document.createElement("div");
	newPreview.className = "ak-preview";
	
	// make a new image anchor
	var newAnchor = document.createElement("a");
	
	newAnchor.href = anchor.href; // TODO
	newAnchor.title = anchor.title;

	// make a new image
	var newImage = new Image();
	
	// determine the new image dimension
	var mwImageWidth = image.width;
	var mwImageHeight = image.height;
	
	var mwImageRatio = mwImageHeight / mwImageWidth;

	// add the update dimensions closure
	var context = this;

	figure.updateImageDimensions = function() {
		var newImageWidth = 0;
	
		if(this.hasClassName("align-left") || this.hasClassName("align-right")) {
			newImageWidth = ArticleKit.interfaceIdiomPhone ? 110.0 : 200.0;
		} else {
			if(this.getAncestorOrSelfHavingClassName("gallery") || this.getAncestorOrSelfHavingClassName("ak-gallery")) {
				newImageWidth = ArticleKit.interfaceIdiomPhone ? 200.0 : 292.0;
			} else if(thumbnail) {
				newImageWidth = ArticleKit.interfaceIdiomPhone ? 292.0 : 632.0;
			}
		}
		
		// newImageWidth = 320.0; // TODO
	
		var newImageHeight = Math.ceil(newImageWidth * mwImageRatio);
		
		// adjust the image file if needed
		var newImageFile = imageURI.file;
	
		if(newImageWidth > mwImageWidth) {
			newImageFile = newImageFile.replace(mwImageWidth + "px", newImageWidth * window.devicePixelRatio + "px");
		}

		var imageURLString = context.articleURI.protocol + "://" + imageURI.host + imageURI.directory + newImageFile;
		newImage.src = imageURLString;
		
		// set fixed dimensions for better rendering/layout performance
		newImage.width = newImageWidth;
		newImage.height = newImageHeight;
	}
	
	// copy the alt text if needed
	if(image.alt) {
		newImage.alt = image.alt;
	}
	
	// load and error handlers
	newImage.onload = function() {
		figure.removeClassName("ak-loading");
	}

	newImage.onerror = function() {
		if(this.width > mwImageWidth) {
			this.onerror = function() {
				figure.addClassName("ak-loading-error");
			}
			
			this.src = context.articleURI.protocol + "://" + imageURI.host + imageURI.directory + imageURI.file;
		} else {
			figure.addClassName("ak-loading-error");
		}
	}
	newImage.onabort = newImage.onerror;
	
	// find the image caption
	var newCaption = this.thumbnailCaptionForImage(image, anchor, thumbnail);
	
	// wrap all up
	newAnchor.appendChild(newImage);
	newPreview.appendChild(newAnchor);
	figure.appendChild(newPreview);
	
	if(newCaption) {
		figure.appendChild(newCaption);
	}
	
	var insertionContext = thumbnail ? thumbnail : anchor;
	insertionContext.insertAdjacentElement("BeforeBegin", figure);
	
	this.obsoleteElements.push(insertionContext);
	this.images.push(figure);
	
	// update the image dimensions now
	figure.updateImageDimensions();
}

ARKArticle.prototype.thumbnailCaptionForImage = function(image, anchor, thumbnail) {
	var thumbcaption = anchor.nextElementSibling;
	
	if(!this.isThumbnailCaption(thumbcaption)) {
		var thumbImage = image.getAncestorOrSelfHavingClassName("thumbimage");
		
		if(thumbImage) {
			thumbcaption = thumbImage.nextElementSibling;
		}
	}
	
	if(!this.isThumbnailCaption(thumbcaption)) {
		thumbcaption = null;
	}
	
	if(!thumbcaption) {
		if(anchor &&
		   anchor.parentElement &&
		   this.isThumbnailCaption(anchor.parentElement.nextElementSibling)) {
			thumbcaption = anchor.parentElement.nextElementSibling;
		}
	}
	
	if(!thumbcaption) {
		if(thumbnail &&
		   thumbnail.nextElementSibling &&
		   thumbnail.nextElementSibling.hasClassName("gallerytext")) {
			thumbcaption = thumbnail.nextElementSibling;
		}
	}
	
	if(thumbcaption) {
		var newCaption = document.createElement("figcaption");
		
		thumbcaption.childNodes.foreach(function(index, node) {
			if(node.hasClassName && node.hasClassName("magnify")) { return; }
			
			newCaption.appendChild(node.cloneNode(true));
		});
	}
	
	return newCaption;
}

ARKArticle.prototype.isThumbnailCaption = function(element) {
	if(element && element.hasClassName("thumbcaption")) {
		return true;
	}
	
	return false;
}

ARKArticle.prototype.removeImageIfNeeded = function(imageURI, image) {
	var imageFile = imageURI ? imageURI.file : null;
	
	if(imageFile) {
		if(imageFile.endsWith("Wikisource-logo.svg.png") ||
		   imageFile.endsWith("PD-Icon.svg.png")) {
			if(image.parentElement && image.parentElement.hasClassName("image")) {
				this.obsoleteElements.push(image.parentElement);
			} else {
				this.obsoleteElements.push(image);
			}
			
			return true;
		}
	}
	
	return false;
}

ARKArticle.prototype.restructureGalleries = function(fragment) {
	var context = this;
	
	fragment.querySelectorAll(".gallery").foreach(function(galleryIndex, gallery) {
		var newGallery = document.createElement("aside");
		
		newGallery.setAttribute("class", "ak-gallery");
		
		// make a new caption if needed
		var galleryCaption = gallery.querySelector(".gallerycaption");
		
		if(galleryCaption) {
			var newGalleryCaption = document.createElement("header");
			newGalleryCaption.innerHTML = galleryCaption.innerHTML;
			newGallery.appendChild(newGalleryCaption);
		}
		
		// add all gallery items
		var galleryContent = document.createElement("ul");
		
		gallery.querySelectorAll(".gallerybox .ak-image").foreach(function(imageIndex, image) {
			var newGalleryItem = document.createElement("li");
			newGalleryItem.appendChild(image);
			galleryContent.appendChild(newGalleryItem);
		});
		
		newGallery.appendChild(galleryContent);
		
		gallery.insertAdjacentElement("BeforeBegin", newGallery);
		gallery.parentElement.removeChild(gallery);
		
		// merge out of line images
		var outOfLineItems = [];
		var appendOutOfLineItems = false;
		
		var previousSibling = newGallery.previousElementSibling;
		
		while(previousSibling) {
			var tagName = previousSibling.tagName.toLowerCase();
			
			if(previousSibling.hasClassName("ak-image")) {
				outOfLineItems.push(previousSibling);
			} else if(tagName == "h2" ||
			   tagName == "h3" ||
			   tagName == "h4" ||
			   tagName == "h5" ||
			   tagName == "h6" ||
			   tagName == "h1") {
				appendOutOfLineItems = true;
				break;
			} else if(previousSibling.hasClassName("thumb")) {
			} else {
				break;
			}
			
			previousSibling = previousSibling.previousElementSibling;
		}
		
		if(appendOutOfLineItems) {
			outOfLineItems.foreach(function(imageIndex, image) {
				image.removeClassName("align-right");
				image.removeClassName("align-left");
				
				var newGalleryItem = document.createElement("li");
				
				image.parentElement.removeChild(image);
				newGalleryItem.appendChild(image);
				
				galleryContent.firstElementChild.insertAdjacentElement("BeforeBegin", newGalleryItem);
				
				image.updateImageDimensions();
			});
		}
	});
}

ARKArticle.prototype.restructureQuotes = function(fragment) {
	var context = this;
	
	fragment.querySelectorAll(".cquote, .cquote2, .rquote").foreach(function(quoteIndex, quote) {
		var newQuote = document.createElement("blockquote");
		
		newQuote.className = "ak-quote";
		
		var quoteContent = quote.querySelector("tr:first-of-type > td:nth-of-type(2)");
		
		if(quoteContent) {
			// append the actual quote text
			quoteContent.childNodes.foreach(function(index, node) {
				newQuote.appendChild(node);
			});
			
			// append the cite if needed
			var cite = quote.querySelector("cite");
		
			if(cite) {
				var footer = document.createElement("footer");
				
				cite.removeAttribute("style");
				footer.innerHTML = cite.outerHTML;
				
				newQuote.appendChild(footer);
				cite.parentNode.removeChild(cite);
			}
		
			quote.insertAdjacentElement("BeforeBegin", newQuote);
			quote.parentElement.removeChild(quote);
		}
	});
}

ARKArticle.prototype.restructureQuoteBoxes = function(fragment) {
	var context = this;
	
	fragment.querySelectorAll(".quotebox").foreach(function(quoteboxIndex, quotebox) {
		var newQuote = document.createElement("aside");
		
		newQuote.className = "ak-quote";
		
		if(quotebox.style.getPropertyCSSValue("float") == "left") {
			newQuote.addClassName("align-left");
		} else if(quotebox.style.getPropertyCSSValue("float") == "right") {
			newQuote.addClassName("align-right");
		}
		
		var children = quotebox.children;
		
		var content = children.length > 0 ? quotebox.children[0] : null;
		var cite =children.length > 1 ? quotebox.children[children.length - 1] : null;
		
		content.childNodes.foreach(function(index, node) {
			newQuote.appendChild(node.cloneNode(true));
		});
		
		if(cite && content != cite) {
			var footer = document.createElement("footer");
				
			cite.childNodes.foreach(function(index, node) {
				footer.appendChild(node.cloneNode(true));
			});
				
			newQuote.appendChild(footer);
		}
		
		quotebox.insertAdjacentElement("BeforeBegin", newQuote);
		quotebox.parentElement.removeChild(quotebox);
	});
}

ARKArticle.prototype.restructureLinks = function(fragment) {
	var context = this;
	
	fragment.querySelectorAll(".mw-content-ltr a, .mw-content-rtl a").foreach(function(index, node) {
		if(node.host.length == 0 && node.protocol == "file:") {
			var pathname = node.pathname;
			
			node.protocol = "http:";
			node.host = context.articleURI.host;
			node.pathname = pathname;
		}
		
		node.addEventListener("click", function(event) {
			event.preventDefault();
			
			if(event.target.tagName == "IMG") {
				var image = event.currentTarget.getAncestorOrSelfHavingClassName("ak-image");
				context.delegate.documentShouldShowImage(context, image);
			} else {
				context.delegate.documentShouldOpenLink(context, event.currentTarget);
			}
		}, false);
	});
}

ARKArticle.prototype.restructureImageSourceLinks = function(fragment) {
	var context = this;
	
	fragment.querySelectorAll("img").foreach(function(index, node) {
		var src = node.src;
		var imageURI = parseUri(src);
		
		if(imageURI.protocol != "http") {
			// alert(src);
			
			node.src = "http://" + imageURI.host + imageURI.path;
		}
	});
}

ARKArticle.prototype.restructureIdentifiers = function(fragment) {
}

ARKArticle.prototype.shouldPreventFloat = function(image) {
	var sibling = image.nextElementSibling;
	
	if(sibling) {
		if(sibling.tagName == "table" ||
		   sibling.tagName == "div") {
			return true;  
		}
	
		if(sibling.tagName == "figure") {
			return this.shouldPreventFloat(sibling);
		}
	}
	
	return false;
}

ARKArticle.prototype.absoluteURStringForRelateiveURLString = function(relativeURLString) {
	var absoluteURLString = this.articleURI.protocol + "://" + this.articleURI.host + relativeURLString;
	return absoluteURLString;
}

ARKArticle.prototype.articleRelativeIdentifierForIdentifier = function(identifier) {
	return identifier; //this.identifier + "-" + identifier;
}

ARKArticle.prototype.restoreContentOffsetIfNeeded = function() {
	var anchor = this.articleURI.anchor;

	if(anchor) {
		window.location.hash = this.articleRelativeIdentifierForIdentifier(anchor);
	}
}

// ARKApplication

function ARKApplication() {
	this.interfaceIdiomPad = (navigator.platform == "iPad" || navigator.platform == "iPad Simulator");
	this.interfaceIdiomPhone = (navigator.platform == "iPhone" || navigator.platform == "iPhone Simulator");
	this.interfaceIdiomDesktop = !this.interfaceIdiomPad && !this.interfaceIdiomPhone;
	
	this.supportsTouches = ("createTouch" in document);
}

ARKApplication.prototype.loadArticle = function(articleURL) {
	var context = this;
	
	// remove the current article node if needed
	this.prepareForReuse();
	
	// make a new article
	var article = new ARKArticle(articleURL);
	
	article.delegate = this;
	this.currentArticle = article;

	// do some completion and error handling
	article.completion = function(node, status) {
		node.id = "ak-article";
		document.body.appendChild(node);

		//article.restoreContentOffsetIfNeeded();
		
		document.title = article.title;
		
		var options = {
			"articleURL": articleURL,
			"title": article.title };
		context.performAction("articleDidFinishLoad", options);
	};
	
	article.failure = function(code, status) {
		alert(status); // TODO
		
		document.body.addClassName("ak-error");
	};
	
	// punch it!
	article.load();
	
	// manipulate the browser history
	if(this.interfaceIdiomPad || this.interfaceIdiomPhone) {
		window.history.pushState({ "identifier":article.identifier }, articleURL, articleURL);
	}
}

ARKApplication.prototype.documentShouldShowImage = function(article, image) {
	this.lightboxController = new ARKLightboxController(document.body);
	this.lightboxController.showImage(image);
}

ARKApplication.prototype.documentShouldOpenLink = function(article, link) {
	if(this.interfaceIdiomPhone || this.interfaceIdiomPad) {
		// window.location = link.href;
		
		var options = { "articleURL": link.href };
		this.performAction("loadArticle", options);
	} else {
		this.loadArticle(link.href);
	}
}

ARKApplication.prototype.performAction = function(action, options) {
	if(ArticleKit.interfaceIdiomDesktop) { return; }

	var actionURL = "x-articlekit-internal://" + action;
	
	if(options) {
		actionURL += "?" + encodeURIComponent(JSON.stringify(options));
	}
	
	window.location = actionURL;
}

ARKApplication.prototype.prepareForReuse = function() {
	if(this.currentArticle) {
		this.currentArticle.delegate = null;
		delete this.currentArticle;
		this.currentArticle = null;
	}
	
	var currentArticleNode = document.getElementById("ak-article");
	
	if(currentArticleNode) {
		document.body.removeChild(currentArticleNode);
	}
}

var ArticleKit = new ARKApplication();

if(ArticleKit.interfaceIdiomDesktop) {
	ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Japan");
}

/*
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Coptic_Orthodox_Church_of_Alexandria");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Lyon");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/National_Gallery_of_Art");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Art_Deco");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/The_Art_of_the_Motorcycle");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Abstract_expressionism");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Captain_America");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Carpenter_Gothic");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Black_Cat_(comics)");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/USA");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Mona_Lisa");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Leonardo_da_Vinci");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Renaissance");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Michelangelo");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/Van_Gogh");
ArticleKit.loadArticle("http://de.wikipedia.org/wiki/Post-Impressionismus");
ArticleKit.loadArticle("http://en.wikipedia.org/wiki/The_Art_of_the_Motorcycle");
*/