.PHONY: all
all: find_tax docs/find_tax.js

find_tax: find_tax.nim
	nim c find_tax.nim

docs/find_tax.js: find_tax.nim
	nim js find_tax.nim
	mv find_tax.js docs/

.PHONY: clean
clean:
	rm docs/find_tax.js find_tax
