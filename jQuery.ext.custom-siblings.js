(function() {

  /*
   * custom siblings - last change: 2008-11-29
   * copyright 2009 Alex Brem <ab@alexbrem.net>
   * license: http://www.opensource.org/licenses/mit-license.php
   */

  jQuery.extend({
    siblingsWhile: function(elem, dir, fn, args) {
      var matched = [];

      for (var n = elem[dir]; n && n != document; n = n[dir]) {
        if (n.nodeType == 1) {
          if (!fn.call(n, elem, args)) break;
          matched.push(n);
        }
      }

      return matched;
    }
  });

  jQuery.fn.extend({
    nextAllWhile: function(selector) {
      var ret = jQuery.map(this, function(elem, i) {
        return jQuery.siblingsWhile(elem, 'nextSibling', (jQuery.isFunction(selector) ? selector : function(elem) {
          return $(this).is(selector) })
        );
      });
      return this.pushStack(jQuery.unique(ret));
    },
    prevAllWhile: function(selector) {
      var ret = jQuery.map(this, function(elem, i) {
        return jQuery.siblingsWhile(elem, 'previousSibling', (jQuery.isFunction(selector) ? selector : function(elem) {
          return $(this).is(selector) })
        );
      });
      return this.pushStack(jQuery.unique(ret));
    }
  });

})();