all:
	$(MAKE) check
	$(MAKE) xref
	$(MAKE) out

add-index-link-to-blog-posts:
	sed -i -f add_index_to_blog_posts.sed html/Blog/*/*/*/*/index.html

xref:
	find html -name "*.html" | xargs -n 1 htmlxref

updatetime:
	find html -name "*.html" | xargs -n 1 sh -c 'html-updatetime-git "$$0" >"$$0+"; mv "$$0+" "$$0"'

autoimports: html/footer.html html/header.html
	find html -name "*.html" -type f | $(foreach h,$+,fgrep -v $(h) |) xargs -n 1 htmlautoimports $+

out:
	find html -type f -print0 | sed -z 's/^html\//out\//' | xargs -0 -n 1 $(MAKE) -B --no-print-directory
	$(MAKE) check-out

check:
	find html -type f -name "*.html" -print0 | xargs -0 -n 1 html-check >/dev/null

check-out:
	find out -type f -name "*.html" -print0 | xargs -0 -n 1 html-check >/dev/null

out/%.html: html/%.html
	@mkdir -p '$(@D)'
	( cd '$(<D)'; html-includetag | html-expandurl ) <'$<' >'$@'

out/%: html/%
	@mkdir -p '$(@D)'
	cp -f '$<' '$@'

diff:
	diff -urNbB html out

.PHONY: out
