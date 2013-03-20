# Generate static HTML for github pages.
#
# Requires haxe (http://haxe.org) to build html
#
# Requires lessc (http://lesscss.org/) to compile css file
#

all: html css

html:
	haxe -cp src -x Site

css:
	lessc src/style.less > style.css
