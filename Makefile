add-index-link-to-blog-posts:
	sed -i -f add_index_to_blog_posts.sed html/Blog/*/*/*/*/index.html

xref:
	find html -name "*.html" | xargs -n 1 htmlxref

out:
	find html -type f -print0 | sed -z 's/^html\//out\//' | xargs -0 -n 1 $(MAKE) -B --no-print-directory

out/%.html: html/%.html
	htmltags $< $@

out/%: html/%
	@mkdir -p $(@D)
	cp $< $@

diff:
	diff -urNbB html out

.PHONY: out
