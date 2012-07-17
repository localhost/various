various
=======

Various stuff I hacked together. May be of use or obsolete by now. Who knows.

6502_64tass.lang
----------------

A gedit / gtksourceview 2 language specification file for 6502 assembly, more specific the [64tass](http://singularcrew.hu/64tass/) assembler. Needs to be copied to `/usr/share/gtksourceview-2.0/language-specs`.

cymd2comd.rb
------------

A Cyrus Maildir to Courier Maildir converter.

jQuery.ext.custom-siblings.js
-----------------------------

Extends jQuery, provides `prevAllWhile` and `nextAllWhile`. I needed this for a project, but can't exactly remember why. ^^

Use it like this:

```javascript
$(this).nextAllWhile('dd').each(function(n) { $(this).show() });
```

spell-correct.io, spell-correct.go
----------------------------------

My conversion of [Peter Norvig's Spelling Corrector](http://www.norvig.com/spell-correct.html) to the [Io language](http://iolanguage.com/) and to [Go](http://golang.org/).

quine.go
--------

A 134 bytes quine in Go.
