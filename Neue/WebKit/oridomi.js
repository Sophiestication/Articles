// Generated by CoffeeScript 1.4.0
(function() {
  //'use strict';

  var $, OriDomi, css, defaults, devMode, extendObj, instances, key, noOp, oriDomiSupport, prefixList, root, testEl, testProp, value, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  root = this;

  instances = [];

  $ = root.$ || false;

  devMode = false;

  oriDomiSupport = true;

  testEl = document.createElement('div');

  prefixList = ['Webkit', 'Moz', 'O', 'ms', 'Khtml'];

  css = {
    transform: 'transform',
    origin: 'transformOrigin',
    transformStyle: 'transformStyle',
    transitionProp: 'transitionProperty',
    transitionDuration: 'transitionDuration',
    transitionEasing: 'transitionTimingFunction',
    perspective: 'perspective',
    backface: 'backfaceVisibility'
  };

  testProp = function(prop) {
	var capProp, prefix, _i, _len;
    capProp = prop.charAt(0).toUpperCase() + prop.slice(1);
    for (_i = 0, _len = prefixList.length; _i < _len; _i++) {
      prefix = prefixList[_i];
      if (testEl.style[prefix + capProp] != null) {
        return prefix + capProp;
      }
    }
    if (testEl.style[prop] != null) {
      return prop;
    }
    return false;
  };

  /*for (key in css) {
    value = css[key];
    css[key] = testProp(value);
    if (!css[key]) {
      if (devMode) {
        console.warn('oriDomi: Browser does not support oriDomi');
      }
      oriDomiSupport = false;
      break;
    }
  }*/

  css.gradientProp = (function() {
    var hyphenated, prefix, _i, _len;
    for (_i = 0, _len = prefixList.length; _i < _len; _i++) {
      prefix = prefixList[_i];
      hyphenated = "-" + (prefix.toLowerCase()) + "-linear-gradient";
      testEl.style.backgroundImage = "" + hyphenated + "(left, #000, #fff)";
      if (testEl.style.backgroundImage.indexOf('gradient') !== -1) {
        return hyphenated;
      }
    }
    return 'linear-gradient';
  })();

  _ref = (function() {
    var grabValue, plainGrab, prefix, _i, _len;
    for (_i = 0, _len = prefixList.length; _i < _len; _i++) {
      prefix = prefixList[_i];
      plainGrab = 'grab';
      testEl.style.cursor = (grabValue = "-" + (prefix.toLowerCase()) + "-" + plainGrab);
      if (testEl.style.cursor === grabValue) {
        return [grabValue, "-" + (prefix.toLowerCase()) + "-grabbing"];
      }
    }
    testEl.style.cursor = plainGrab;
    if (testEl.style.cursor === plainGrab) {
      return [plainGrab, 'grabbing'];
    } else {
      return ['move', 'move'];
    }
  })(), css.grab = _ref[0], css.grabbing = _ref[1];

  css.transformProp = (function() {
    var prefix;
    prefix = css.transform.match(/(\w+)Transform/i);
    if (prefix) {
      return "-" + (prefix[1].toLowerCase()) + "-transform";
    } else {
      return 'transform';
    }
  })();

  css.transitionEnd = (function() {
    switch (css.transitionProp) {
      case 'transitionProperty':
        return 'transitionEnd';
      case 'WebkitTransitionProperty':
        return 'webkitTransitionEnd';
      case 'MozTransitionProperty':
        return 'transitionend';
      case 'OTransitionProperty':
        return 'oTransitionEnd';
      case 'MSTransitionProperty':
        return 'msTransitionEnd';
    }
  })();

  extendObj = function(target, source) {
    var prop;
    if (source !== Object(source)) {
      if (devMode) {
        console.warn('oriDomi: Must pass an object to extend with');
      }
      return target;
    }
    if (target !== Object(target)) {
      target = {};
    }
    for (prop in source) {
      if (!(target[prop] != null)) {
        target[prop] = source[prop];
      }
    }
    return target;
  };

  noOp = function() {};

  defaults = {
    vPanels: 3,
    hPanels: 3,
    perspective: 1000,
    shading: 'hard',
    speed: 700,
    oriDomiClass: 'oridomi',
    shadingIntensity: 1,
    easingMethod: '',
    showOnStart: false,
    forceAntialiasing: false,
    touchEnabled: true,
    touchSensitivity: .25,
    touchStartCallback: noOp,
    touchMoveCallback: noOp,
    touchEndCallback: noOp
  };

  OriDomi = (function() {

    function OriDomi(el, options) {
      var anchor, bleed, bottomShader, content, contentHolder, eString, eventPair, eventPairs, hMask, hPanel, i, leftShader, metric, mouseLeaveSupport, panel, rightShader, shader, stage, topShader, vMask, vPanel, xMetrics, xOffset, yMetrics, yOffset, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _len5, _len6, _len7, _len8, _m, _n, _o, _p, _q, _r, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9, _s;
      this.el = el;
      this._onMouseOut = __bind(this._onMouseOut, this);

      this._onTouchLeave = __bind(this._onTouchLeave, this);

      this._onTouchEnd = __bind(this._onTouchEnd, this);

      this._onTouchMove = __bind(this._onTouchMove, this);

      this._onTouchStart = __bind(this._onTouchStart, this);

      if (devMode) {
        console.time('oridomiConstruction');
      }
      if (!oriDomiSupport) {
        return this.el;
      }
      if (!(this instanceof OriDomi)) {
        return new oriDomi(this.el, this.settings);
      }
      this.settings = extendObj(options, defaults);
      if (!this.el || this.el.nodeType !== 1) {
        if (devMode) {
          console.warn('oriDomi: First argument must be a DOM element');
        }
        return;
      }
      this.cleanEl = this.el.cloneNode(true);
      this.cleanEl.style.margin = '0';
      this.cleanEl.style.position = 'absolute';
      this.cleanEl.style[css.transform] = 'translate3d(-9999px, 0, 0)';
      _ref1 = this.settings, this.shading = _ref1.shading, this.shadingIntensity = _ref1.shadingIntensity, this.vPanels = _ref1.vPanels, this.hPanels = _ref1.hPanels;
      this._elStyle = root.getComputedStyle(this.el);
      this.displayStyle = this._elStyle.display;
      if (this.displayStyle === 'none') {
        this.displayStyle = 'block';
      }
      xMetrics = ['width', 'paddingLeft', 'paddingRight', 'borderLeftWidth', 'borderRightWidth'];
      yMetrics = ['height', 'paddingTop', 'paddingBottom', 'borderTopWidth', 'borderBottomWidth'];
      this.width = 0;
      this.height = 0;
      for (_i = 0, _len = xMetrics.length; _i < _len; _i++) {
        metric = xMetrics[_i];
        this.width += this._getMetric(metric);
      }
      for (_j = 0, _len1 = yMetrics.length; _j < _len1; _j++) {
        metric = yMetrics[_j];
        this.height += this._getMetric(metric);
      }
      this.panelWidth = this.width / this.vPanels;
      this.panelHeight = this.height / this.hPanels;
      this.lastAngle = 0;
      this.isFoldedUp = false;
      this.isFrozen = false;
      this.anchors = ['left', 'right', 'top', 'bottom'];
      this.lastAnchor = this.anchors[0];
      this.panels = {};
      this.stages = {};
      stage = document.createElement('div');
      stage.style.width = this.width + 'px';
      stage.style.height = this.height + 'px';
      stage.style.display = 'none';
      stage.style.position = 'absolute';
      stage.style.padding = '0';
      stage.style.margin = '0';
      stage.style[css.perspective] = this.settings.perspective + 'px';
      stage.style[css.transformStyle] = 'preserve-3d';
      _ref2 = this.anchors;
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        anchor = _ref2[_k];
        this.panels[anchor] = [];
        this.stages[anchor] = stage.cloneNode(false);
        this.stages[anchor].className = 'oridomi-stage-' + anchor;
      }
      if (this.shading) {
        this.shaders = {};
        _ref3 = this.anchors;
        for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
          anchor = _ref3[_l];
          this.shaders[anchor] = {};
          if (anchor === 'left' || anchor === 'right') {
            this.shaders[anchor].left = [];
            this.shaders[anchor].right = [];
          } else {
            this.shaders[anchor].top = [];
            this.shaders[anchor].bottom = [];
          }
        }
        shader = document.createElement('div');
        shader.style[css.transitionProp] = 'opacity';
        shader.style[css.transitionDuration] = this.settings.speed + 'ms';
        shader.style[css.transitionEasing] = this.settings.easingMethod;
        shader.style.position = 'absolute';
        shader.style.width = '100%';
        shader.style.height = '100%';
        shader.style.opacity = '0';
        shader.style.top = '0';
        shader.style.left = '0';
        shader.style.pointerEvents = 'none';
      }
      contentHolder = this.el.cloneNode(true);
      contentHolder.classList.add('oridomi-content');
      contentHolder.style.margin = '0';
      contentHolder.style.position = 'relative';
      contentHolder.style.float = 'none';
      hMask = document.createElement('div');
      hMask.className = 'oridomi-mask-h';
      hMask.style.position = 'absolute';
      hMask.style.overflow = 'hidden';
      hMask.style.width = '100%';
      hMask.style.height = '100%';
      hMask.style[css.transform] = 'translate3d(0, 0, 0)';
      hMask.appendChild(contentHolder);
      if (this.shading) {
        topShader = shader.cloneNode(false);
        topShader.className = 'oridomi-shader-top';
        topShader.style.background = this._getShaderGradient('top');
        bottomShader = shader.cloneNode(false);
        bottomShader.className = 'oridomi-shader-bottom';
        bottomShader.style.background = this._getShaderGradient('bottom');
        hMask.appendChild(topShader);
        hMask.appendChild(bottomShader);
      }
      bleed = 1.5;
      hPanel = document.createElement('div');
      hPanel.className = 'oridomi-panel-h';
      hPanel.style.width = '100%';
      hPanel.style.height = this.panelHeight + bleed + 'px';
      hPanel.style.padding = '0';
      hPanel.style.position = 'relative';
      hPanel.style[css.transitionProp] = css.transformProp;
      hPanel.style[css.transitionDuration] = this.settings.speed + 'ms';
      hPanel.style[css.transitionEasing] = this.settings.easingMethod;
      hPanel.style[css.origin] = 'top';
      hPanel.style[css.transformStyle] = 'preserve-3d';
      hPanel.style[css.backface] = 'hidden';
      if (this.settings.forceAntialiasing) {
        hPanel.style.outline = '1px solid transparent';
      }
      hPanel.appendChild(hMask);
      _ref4 = ['top', 'bottom'];
      for (_m = 0, _len4 = _ref4.length; _m < _len4; _m++) {
        anchor = _ref4[_m];
        for (i = _n = 0, _ref5 = this.hPanels; 0 <= _ref5 ? _n < _ref5 : _n > _ref5; i = 0 <= _ref5 ? ++_n : --_n) {
          panel = hPanel.cloneNode(true);
          content = panel.getElementsByClassName('oridomi-content')[0];
          if (anchor === 'top') {
            yOffset = -(i * this.panelHeight);
            if (i === 0) {
              panel.style.top = '0';
            } else {
              panel.style.top = this.panelHeight + 'px';
            }
          } else {
            panel.style[css.origin] = 'bottom';
            yOffset = -((this.hPanels * this.panelHeight) - (this.panelHeight * (i + 1)));
            if (i === 0) {
              panel.style.top = this.panelHeight * (this.vPanels - 1) - bleed + 'px';
            } else {
              panel.style.top = -this.panelHeight + 'px';
            }
          }
          content.style.top = yOffset + 'px';
          if (this.shading) {
            this.shaders[anchor].top[i] = panel.getElementsByClassName('oridomi-shader-top')[0];
            this.shaders[anchor].bottom[i] = panel.getElementsByClassName('oridomi-shader-bottom')[0];
          }
          this.panels[anchor][i] = panel;
          if (i !== 0) {
            this.panels[anchor][i - 1].appendChild(panel);
          }
        }
        this.stages[anchor].appendChild(this.panels[anchor][0]);
      }
      vMask = hMask.cloneNode(true);
      vMask.className = 'oridomi-mask-v';
      if (this.shading) {
        leftShader = vMask.getElementsByClassName('oridomi-shader-top')[0];
        leftShader.className = 'oridomi-shader-left';
        leftShader.style.background = this._getShaderGradient('left');
        rightShader = vMask.getElementsByClassName('oridomi-shader-bottom')[0];
        rightShader.className = 'oridomi-shader-right';
        rightShader.style.background = this._getShaderGradient('right');
      }
      vPanel = hPanel.cloneNode(false);
      vPanel.className = 'oridomi-panel-v';
      vPanel.style.width = this.panelWidth + bleed + 'px';
      vPanel.style.height = '100%';
      vPanel.style[css.origin] = 'left';
      vPanel.appendChild(vMask);
      _ref6 = ['left', 'right'];
      for (_o = 0, _len5 = _ref6.length; _o < _len5; _o++) {
        anchor = _ref6[_o];
        for (i = _p = 0, _ref7 = this.vPanels; 0 <= _ref7 ? _p < _ref7 : _p > _ref7; i = 0 <= _ref7 ? ++_p : --_p) {
          panel = vPanel.cloneNode(true);
          content = panel.getElementsByClassName('oridomi-content')[0];
          if (anchor === 'left') {
            xOffset = -(i * this.panelWidth);
            if (i === 0) {
              panel.style.left = '0';
            } else {
              panel.style.left = this.panelWidth + 'px';
            }
          } else {
            panel.style[css.origin] = 'right';
            xOffset = -((this.vPanels * this.panelWidth) - (this.panelWidth * (i + 1)));
            if (i === 0) {
              panel.style.left = this.panelWidth * (this.vPanels - 1) - 1 + 'px';
            } else {
              panel.style.left = -this.panelWidth + 'px';
            }
          }
          content.style.left = xOffset + 'px';
          if (this.shading) {
            this.shaders[anchor].left[i] = panel.getElementsByClassName('oridomi-shader-left')[0];
            this.shaders[anchor].right[i] = panel.getElementsByClassName('oridomi-shader-right')[0];
          }
          this.panels[anchor][i] = panel;
          if (i !== 0) {
            this.panels[anchor][i - 1].appendChild(panel);
          }
        }
        this.stages[anchor].appendChild(this.panels[anchor][0]);
      }
      this.el.classList.add(this.settings.oriDomiClass);
      this.el.style.padding = '0';
      this.el.style.width = this.width + 'px';
      this.el.style.height = this.height + 'px';
      this.el.style.backgroundColor = 'transparent';
      this.el.style.backgroundImage = 'none';
      this.el.style.border = 'none';
      this.el.style.outline = 'none';
      this.stages.left.style.display = 'block';
      this.stageEl = document.createElement('div');
      eventPairs = [['TouchStart', 'MouseDown'], ['TouchEnd', 'MouseUp'], ['TouchMove', 'MouseMove'], ['TouchLeave', 'MouseLeave']];
      mouseLeaveSupport = 'onmouseleave' in window;
      for (_q = 0, _len6 = eventPairs.length; _q < _len6; _q++) {
        eventPair = eventPairs[_q];
        for (_r = 0, _len7 = eventPair.length; _r < _len7; _r++) {
          eString = eventPair[_r];
          if (!(eString === 'TouchLeave' && !mouseLeaveSupport)) {
            this.stageEl.addEventListener(eString.toLowerCase(), this['_on' + eventPair[0]], false);
          } else {
            this.stageEl.addEventListener('mouseout', this['_onMouseOut'], false);
            break;
          }
        }
      }
      if (this.settings.touchEnabled) {
        this.enableTouch();
      }
      _ref8 = this.anchors;
      for (_s = 0, _len8 = _ref8.length; _s < _len8; _s++) {
        anchor = _ref8[_s];
        this.stageEl.appendChild(this.stages[anchor]);
      }
      if (this.settings.showOnStart) {
        this.el.style.display = 'block';
        this.el.style.visibility = 'visible';
      }
      this.el.innerHTML = '';
      this.el.appendChild(this.cleanEl);
      this.el.appendChild(this.stageEl);
      _ref9 = [0, 0], this._xLast = _ref9[0], this._yLast = _ref9[1];
      this.lastOp = {
        method: 'accordion',
        options: {}
      };
      if ($) {
        this.$el = $(this.el);
      }
      instances.push(this);
      this._callback(this.settings);
      if (devMode) {
        console.timeEnd('oridomiConstruction');
      }
    }

    OriDomi.prototype._callback = function(options) {
      var onTransitionEnd,
        _this = this;
      if (typeof options.callback === 'function') {
        onTransitionEnd = function(e) {
          e.currentTarget.removeEventListener(css.transitionEnd, onTransitionEnd, false);
          return options.callback();
        };
        if (this.lastAngle === 0) {
          return options.callback();
        } else {
          return this.panels[this.lastAnchor][0].addEventListener(css.transitionEnd, onTransitionEnd, false);
        }
      }
    };

    OriDomi.prototype._getMetric = function(metric) {
      return parseInt(this._elStyle[metric], 10);
    };

    OriDomi.prototype._transform = function(angle, fracture) {
      var axes, _ref1;
      switch (this.lastAnchor) {
        case 'left':
          axes = [0, 1, 0, angle];
          break;
        case 'right':
          axes = [0, 1, 0, -angle];
          break;
        case 'top':
          axes = [1, 0, 0, -angle];
          break;
        case 'bottom':
          axes = [1, 0, 0, angle];
      }
      if (fracture) {
        _ref1 = [1, 1, 1], axes[0] = _ref1[0], axes[1] = _ref1[1], axes[2] = _ref1[2];
      }
      return "rotate3d(" + axes[0] + ", " + axes[1] + ", " + axes[2] + ", " + axes[3] + "deg)";
    };

    OriDomi.prototype._normalizeAngle = function(angle) {
      angle = parseFloat(angle, 10);
      if (isNaN(angle)) {
        return 0;
      } else if (angle > 89) {
        return 89;
      } else if (angle < -89) {
        return -89;
      } else {
        return angle;
      }
    };

    OriDomi.prototype._normalizeArgs = function(method, args) {
      var anchor, angle, options,
        _this = this;
      if (this.isFrozen) {
        this.unfreeze();
      }
      angle = this._normalizeAngle(args[0]);
      anchor = this._getLonghandAnchor(args[1] || this.lastAnchor);
      options = extendObj(args[2], this._methodDefaults[method]);
      this.lastOp = {
        method: method,
        options: options,
        negative: angle < 0
      };
      if (anchor !== this.lastAnchor || (method === 'foldUp' && this.lastAngle !== 0) || this.isFoldedUp) {
        this.reset(function() {
          _this._showStage(anchor);
          if (_this._touchEnabled) {
            _this._setCursor();
          }
          return setTimeout(function() {
            if (method === 'foldUp') {
              args.shift();
            }
            return _this[method].apply(_this, args);
          }, 0);
        });
        return false;
      } else {
        this.lastAngle = angle;
        return [angle, anchor, options];
      }
    };

    OriDomi.prototype._setShader = function(i, anchor, angle) {
      var a, abs, b, opacity;
      abs = Math.abs(angle);
      opacity = abs / 90 * this.shadingIntensity;
      if (this.shading === 'hard') {
        opacity *= .15;
        if (this.lastAngle < 0) {
          angle = abs;
        } else {
          angle = -abs;
        }
      } else {
        opacity *= .4;
      }
      switch (anchor) {
        case 'left':
        case 'top':
          if (angle < 0) {
            a = opacity;
            b = 0;
          } else {
            a = 0;
            b = opacity;
          }
          break;
        case 'right':
        case 'bottom':
          if (angle < 0) {
            a = 0;
            b = opacity;
          } else {
            a = opacity;
            b = 0;
          }
      }
      if (anchor === 'left' || anchor === 'right') {
        this.shaders[anchor].left[i].style.opacity = a;
        return this.shaders[anchor].right[i].style.opacity = b;
      } else {
        this.shaders[anchor].top[i].style.opacity = a;
        return this.shaders[anchor].bottom[i].style.opacity = b;
      }
    };

    OriDomi.prototype._getShaderGradient = function(anchor) {
      return "" + css.gradientProp + "(" + anchor + ", rgba(0, 0, 0, .5) 0%, rgba(255, 255, 255, .35) 100%)";
    };

    OriDomi.prototype._showStage = function(anchor) {
      if (anchor !== this.lastAnchor) {
        this.stages[anchor].style.display = 'block';
        this.stages[this.lastAnchor].style.display = 'none';
        return this.lastAnchor = anchor;
      }
    };

    OriDomi.prototype._getPanelType = function(anchor) {
      if (anchor === 'left' || anchor === 'right') {
        return this.vPanels;
      } else {
        return this.hPanels;
      }
    };

    OriDomi.prototype._getLonghandAnchor = function(shorthand) {
      switch (shorthand) {
        case 'left':
        case 'l':
        case '4':
        case 4:
          return 'left';
        case 'right':
        case 'r':
        case '2':
        case 2:
          return 'right';
        case 'top':
        case 't':
        case '1':
        case 1:
          return 'top';
        case 'bottom':
        case 'b':
        case '3':
        case 3:
          return 'bottom';
        default:
          return 'left';
      }
    };

    OriDomi.prototype._setTweening = function(speed) {
      var i, panel, shaderPair, _i, _len, _ref1;
      if (typeof speed === 'boolean') {
        speed = speed ? this.settings.speed + 'ms' : '0ms';
      }
      if (this.lastAnchor === 'left' || this.lastAnchor === 'right') {
        shaderPair = ['left', 'right'];
      } else {
        shaderPair = ['top', 'bottom'];
      }
      _ref1 = this.panels[this.lastAnchor];
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        panel = _ref1[i];
        panel.style[css.transitionDuration] = speed;
        if (this.shading) {
          this.shaders[this.lastAnchor][shaderPair[0]][i].style[css.transitionDuration] = speed;
          this.shaders[this.lastAnchor][shaderPair[1]][i].style[css.transitionDuration] = speed;
        }
      }
      return null;
    };

    OriDomi.prototype._setCursor = function() {
      if (this._touchEnabled) {
        return this.stageEl.style.cursor = css.grab;
      } else {
        return this.stageEl.style.cursor = 'default';
      }
    };

    OriDomi.prototype._methodDefaults = {
      accordion: {
        sticky: false,
        stairs: false,
        fracture: false,
        twist: false
      },
      curl: {
        twist: false
      },
      ramp: {},
      foldUp: {}
    };

    OriDomi.prototype._onTouchStart = function(e) {
      if (!this._touchEnabled) {
        return;
      }
      e.preventDefault();
      this._touchStarted = true;
      this.stageEl.style.cursor = css.grabbing;
      this._setTweening(false);
      this._touchAxis = this.lastAnchor === 'left' || this.lastAnchor === 'right' ? 'x' : 'y';
      this["_" + this._touchAxis + "Last"] = this.lastAngle;
      if (e.type === 'mousedown') {
        this["_" + this._touchAxis + "1"] = e["page" + (this._touchAxis.toUpperCase())];
      } else {
        this["_" + this._touchAxis + "1"] = e.targetTouches[0]["page" + (this._touchAxis.toUpperCase())];
      }
      return this.settings.touchStartCallback(this["_" + this._touchAxis + "1"]);
    };

    OriDomi.prototype._onTouchMove = function(e) {
      var current, delta, distance;
      if (!(this._touchEnabled && this._touchStarted)) {
        return;
      }
      e.preventDefault();
      if (e.type === 'mousemove') {
        current = e["page" + (this._touchAxis.toUpperCase())];
      } else {
        current = e.targetTouches[0]["page" + (this._touchAxis.toUpperCase())];
      }
      distance = (current - this["_" + this._touchAxis + "1"]) * this.settings.touchSensitivity;
      if (this.lastOp.negative) {
        if (this.lastAnchor === 'right' || this.lastAnchor === 'bottom') {
          delta = this["_" + this._touchAxis + "Last"] - distance;
        } else {
          delta = this["_" + this._touchAxis + "Last"] + distance;
        }
        if (delta > 0) {
          delta = 0;
        }
      } else {
        if (this.lastAnchor === 'right' || this.lastAnchor === 'bottom') {
          delta = this["_" + this._touchAxis + "Last"] + distance;
        } else {
          delta = this["_" + this._touchAxis + "Last"] - distance;
        }
        if (delta < 0) {
          delta = 0;
        }
      }
      this[this.lastOp.method](delta, this.lastAnchor, this.lastOp.options);
      return this.settings.touchMoveCallback(delta);
    };

    OriDomi.prototype._onTouchEnd = function() {
      if (!this._touchEnabled) {
        return;
      }
      this._touchStarted = false;
      this.stageEl.style.cursor = css.grab;
      this._setTweening(true);
      return this.settings.touchEndCallback(this["_" + this._touchAxis + "Last"]);
    };

    OriDomi.prototype._onTouchLeave = function() {
      if (!(this._touchEnabled && this._touchStarted)) {
        return;
      }
      return this._onTouchEnd();
    };

    OriDomi.prototype._onMouseOut = function(e) {
      if (!(this._touchEnabled && this._touchStarted)) {
        return;
      }
      if (e.toElement && !this.el.contains(e.toElement)) {
        return this._onTouchEnd();
      }
    };

    OriDomi.prototype.reset = function(callback) {
      var i, panel, _i, _len, _ref1;
      if (this.isFoldedUp) {
        return this.unfold(callback);
      }
      _ref1 = this.panels[this.lastAnchor];
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        panel = _ref1[i];
        panel.style[css.transform] = this._transform(0);
        if (this.shading) {
          this._setShader(i, this.lastAnchor, 0);
        }
      }
      return this._callback({
        callback: callback
      });
    };

    OriDomi.prototype.freeze = function(callback) {
      var _this = this;
      if (this.isFrozen) {
        return typeof callback === "function" ? callback() : void 0;
      } else {
        return this.reset(function() {
          _this.isFrozen = true;
          _this.stageEl.style[css.transform] = 'translate3d(-9999px, 0, 0)';
          _this.cleanEl.style[css.transform] = 'translate3d(0, 0, 0)';
          return typeof callback === "function" ? callback() : void 0;
        });
      }
    };

    OriDomi.prototype.unfreeze = function() {
      if (this.isFrozen) {
        this.isFrozen = false;
        this.cleanEl.style[css.transform] = 'translate3d(-9999px, 0, 0)';
        this.stageEl.style[css.transform] = 'translate3d(0, 0, 0)';
        return this.lastAngle = 0;
      }
    };

    OriDomi.prototype.destroy = function(callback) {
      var _this = this;
      return this.freeze(function() {
        var changedKeys, _i, _len;
        _this.stageEl.removeEventListener('touchstart', _this._onTouchStart, false);
        _this.stageEl.removeEventListener('mousedown', _this._onTouchStart, false);
        _this.stageEl.removeEventListener('touchend', _this._onTouchEnd, false);
        _this.stageEl.removeEventListener('mouseup', _this._onTouchEnd, false);
        if ($) {
          $.data(_this.el, 'oriDomi', null);
        }
        _this.el.innerHTML = _this.cleanEl.innerHTML;
        changedKeys = ['padding', 'width', 'height', 'backgroundColor', 'backgroundImage', 'border', 'outline'];
        for (_i = 0, _len = changedKeys.length; _i < _len; _i++) {
          key = changedKeys[_i];
          _this.el.style[key] = _this._elStyle[key];
        }
        instances[instances.indexOf(_this)] = null;
        return typeof callback === "function" ? callback() : void 0;
      });
    };

    OriDomi.prototype.enableTouch = function() {
      this._touchEnabled = true;
      return this._setCursor();
    };

    OriDomi.prototype.disableTouch = function() {
      this._touchEnabled = false;
      return this._setCursor();
    };

    OriDomi.prototype.accordion = function(angle, anchor, options) {
      var deg, i, normalized, panel, _i, _len, _ref1;
      normalized = this._normalizeArgs('accordion', arguments);
      if (!normalized) {
        return;
      }
      angle = normalized[0], anchor = normalized[1], options = normalized[2];
      _ref1 = this.panels[anchor];
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        panel = _ref1[i];
        if (i % 2 !== 0 && !options.twist) {
          deg = -angle;
        } else {
          deg = angle;
        }
        if (options.sticky) {
          if (i === 0) {
            deg = 0;
          } else if (i > 1 || options.stairs) {
            deg *= 2;
          }
        } else {
          if (i !== 0) {
            deg *= 2;
          }
        }
        if (options.stairs) {
          deg = -deg;
        }
        panel.style[css.transform] = this._transform(deg, options.fracture);
        if (this.shading && !(i === 0 && options.sticky) && Math.abs(deg) !== 180) {
          this._setShader(i, anchor, deg);
        }
      }
      return this._callback(options);
    };

    OriDomi.prototype.curl = function(angle, anchor, options) {
      var i, normalized, panel, _i, _len, _ref1;
      normalized = this._normalizeArgs('curl', arguments);
      if (!normalized) {
        return;
      }
      angle = normalized[0], anchor = normalized[1], options = normalized[2];
      angle /= this._getPanelType(anchor);
      _ref1 = this.panels[anchor];
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        panel = _ref1[i];
        panel.style[css.transform] = this._transform(angle);
        if (this.shading) {
          this._setShader(i, anchor, 0);
        }
      }
      return this._callback(options);
    };

    OriDomi.prototype.ramp = function(angle, anchor, options) {
      var i, normalized, panel, _i, _len, _ref1;
      normalized = this._normalizeArgs('ramp', arguments);
      if (!normalized) {
        return;
      }
      angle = normalized[0], anchor = normalized[1], options = normalized[2];
      this.panels[anchor][1].style[css.transform] = this._transform(angle);
      _ref1 = this.panels[anchor];
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        panel = _ref1[i];
        if (i > 1) {
          this.panels[anchor][i].style[css.transform] = this._transform(0);
        }
        if (this.shading) {
          this._setShader(i, anchor, 0);
        }
      }
      return this._callback(options);
    };

    OriDomi.prototype.foldUp = function(anchor, callback) {
      var angle, i, nextPanel, normalized, onTransitionEnd,
        _this = this;
      if (!anchor) {
        anchor = 'left';
      } else if (typeof anchor === 'function') {
        callback = anchor;
      }
      normalized = this._normalizeArgs('foldUp', [0, anchor, {}]);
      if (!normalized) {
        return;
      }
      anchor = normalized[1];
      this.isFoldedUp = true;
      i = this.panels[anchor].length - 1;
      angle = 100;
      nextPanel = function() {
        _this.panels[anchor][i].addEventListener(css.transitionEnd, onTransitionEnd, false);
        _this.panels[anchor][i].style[css.transform] = _this._transform(angle);
        if (_this.shading) {
          return _this._setShader(i, anchor, angle);
        }
      };
      onTransitionEnd = function(e) {
        _this.panels[anchor][i].removeEventListener(css.transitionEnd, onTransitionEnd, false);
        _this.panels[anchor][i].style.display = 'none';
        if (--i === 0) {
          return typeof callback === "function" ? callback() : void 0;
        } else {
          return setTimeout(nextPanel, 0);
        }
      };
      return nextPanel();
    };

    OriDomi.prototype.unfold = function(callback) {
      var angle, i, nextPanel, onTransitionEnd,
        _this = this;
      if (!this.isFoldedUp) {
        if (typeof callback === "function") {
          callback();
        }
      }
      this.isFoldedUp = false;
      i = 1;
      angle = 0;
      nextPanel = function() {
        _this.panels[_this.lastAnchor][i].style.display = 'block';
        return setTimeout(function() {
          _this.panels[_this.lastAnchor][i].addEventListener(css.transitionEnd, onTransitionEnd, false);
          _this.panels[_this.lastAnchor][i].style[css.transform] = _this._transform(angle);
          if (_this.shading) {
            return _this._setShader(i, _this.lastAnchor, angle);
          }
        }, 0);
      };
      onTransitionEnd = function(e) {
        _this.panels[_this.lastAnchor][i].removeEventListener(css.transitionEnd, onTransitionEnd, false);
        if (++i === _this.panels[_this.lastAnchor].length) {
          return typeof callback === "function" ? callback() : void 0;
        } else {
          return setTimeout(nextPanel, 0);
        }
      };
      return nextPanel();
    };

    OriDomi.prototype.collapse = function(anchor, options) {
      if (options == null) {
        options = {};
      }
      options.sticky = false;
      return this.accordion(-89, anchor, options);
    };

    OriDomi.prototype.collapseAlt = function(anchor, options) {
      if (options == null) {
        options = {};
      }
      options.sticky = false;
      return this.accordion(89, anchor, options);
    };

    OriDomi.prototype.reveal = function(angle, anchor, options) {
      if (options == null) {
        options = {};
      }
      options.sticky = true;
      return this.accordion(angle, anchor, options);
    };

    OriDomi.prototype.stairs = function(angle, anchor, options) {
      if (options == null) {
        options = {};
      }
      options.stairs = true;
      options.sticky = true;
      return this.accordion(angle, anchor, options);
    };

    OriDomi.prototype.fracture = function(angle, anchor, options) {
      if (options == null) {
        options = {};
      }
      options.fracture = true;
      return this.accordion(angle, anchor, options);
    };

    OriDomi.prototype.twist = function(angle, anchor, options) {
      if (options == null) {
        options = {};
      }
      options.fracture = true;
      options.twist = true;
      return this.accordion(angle / 10, anchor, options);
    };

    OriDomi.VERSION = '0.2.2';

    OriDomi.isSupported = oriDomiSupport;

    OriDomi.devMode = function() {
      return devMode = true;
    };

    return OriDomi;

  })();

  root.OriDomi = OriDomi;

  if ($) {
    $.fn.oriDomi = function(options) {
      var args, el, instance, _i, _j, _len, _len1;
      if (!oriDomiSupport) {
        return this;
      }
      if (typeof options === 'string') {
        if (typeof OriDomi.prototype[options] !== 'function') {
          if (devMode) {
            console.warn("oriDomi: No such method '" + options + "'");
          }
          return;
        }
        for (_i = 0, _len = this.length; _i < _len; _i++) {
          el = this[_i];
          instance = $.data(el, 'oriDomi');
          if (instance == null) {
            if (devMode) {
              console.warn("oriDomi: Can't call " + options + ", oriDomi hasn't been initialized on this element");
            }
            return;
          }
          args = Array.prototype.slice.call(arguments);
          args.shift();
          instance[options].apply(instance, args);
        }
        return this;
      } else {
        for (_j = 0, _len1 = this.length; _j < _len1; _j++) {
          el = this[_j];
          instance = $.data(el, 'oriDomi');
          if (instance) {
            return instance;
          } else {
            $.data(el, 'oriDomi', new OriDomi(el, options));
          }
        }
        return this;
      }
    };
  }

}).call(this);
