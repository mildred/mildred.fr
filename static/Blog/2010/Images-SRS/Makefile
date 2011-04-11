
JPG_FILES  = $(foreach i,$(wildcard src/*.JPG),$(notdir $(i)))
JPEG_FILES = $(JPG_FILES:.JPG=.jpeg)
THUMBNAILS = $(foreach i,$(JPG_FILES),thumb_$(i:.JPG=.png))

all: $(THUMBNAILS) $(JPEG_FILES) album.txt

album.txt: $(THUMBNAILS) $(JPEG_FILES)
	./album.sh >"$@"

%.jpeg: src/%.JPG
	convert $< -auto-orient $@

thumb_%.png: %.jpeg
	convert $< -auto-orient -thumbnail "120x120^" -background black -polaroid 3 $@
