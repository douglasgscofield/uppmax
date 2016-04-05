# Default rule for converting .md to .html with pandoc expects Github-flavoured
# markdown, among other things this means it respects hard line breaks!

PANDOC = pandoc

GUIDES = Module-Dependencies.html

%.html: %.md
	$(PANDOC) -f markdown_github -t html -o $@ $<

all: $(GUIDES)

clean:
	rm -vf $(GUIDES)

