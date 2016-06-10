all:
	$(MAKE) check
	$(MAKE) xref
	$(MAKE) out

add-index-link-to-blog-posts:
	sed -i -f add_index_to_blog_posts.sed html/Blog/*/*/*/*/index.html

xref:
	find html -name "*.html" | xargs -n 1 htmlxref

updatetime:
	find html -name "*.html" | xargs -n 1 sh -c 'html-updatetime-git "$$0" >"$$0+"; mv "$$0+" "$$0"; echo "$$0"'

convertoldtimes:
	find html/Blog -name index.html | sed -e 'p; y:/:-: ; s:^html-Blog-:src/Blog/: ; s/-index.html$$/.page/g' | xargs -n 2 sh -c 'h=$$(git log -1 --format=format:%H --all -- "$$1"); [ -z "$$h" ] && exit 0; : echo "$0 $$h:$$1"; ctime=$$(git cat-file blob "$$h:$$1" | grep created_at | cut -d: -f2- | xargs); oldctime="$$ctime"; ctime="$${ctime/ +/+}"; ctime="$${ctime/ -/-}"; ctime="$${ctime/ /T}"; (set -x; html-updatetime-git --ctime="$$ctime" "$$0") >"$$0+"; mv "$$0+" "$$0"'

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
