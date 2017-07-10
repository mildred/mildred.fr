check?=1
check_out?=1

all: ## Command to run the build
ifeq ($(check),1)
	$(MAKE) check
endif
	$(MAKE) xref
	$(MAKE) out

add-index-link-to-blog-posts: ## Convert legacy files
	sed -i -f add_index_to_blog_posts.sed html/Blog/*/*/*/*/index.html

xref: ## Run htmlxref
	find html -name "*.html" | xargs -n 1 htmlxref

updatetime:
	find html -name "*.html" | xargs -n 1 sh -c 'html-updatetime-git "$$0"; echo "$$0"'

convertoldtimes:
	find html/Blog -name index.html | sed -e 'p; y:/:-: ; s:^html-Blog-:src/Blog/: ; s/-index.html$$/.page/g' | xargs -n 2 sh -c 'h=$$(git log -1 --format=format:%H --all -- "$$1"); [ -z "$$h" ] && exit 0; : echo "$0 $$h:$$1"; ctime=$$(git cat-file blob "$$h:$$1" | grep created_at | cut -d: -f2- | xargs); oldctime="$$ctime"; ctime="$${ctime/ +/+}"; ctime="$${ctime/ -/-}"; ctime="$${ctime/ /T}"; (set -x; html-updatetime-git --ctime="$$ctime" "$$0") >"$$0+"; mv "$$0+" "$$0"'

convertoldtags:
	find html/Blog/20* -name index.html | xargs -n 1 my-tagger

autoimports: html/_footer.html html/_header.html ## Run htmlautoimports
	find html -name "*.html" -type f | $(foreach h,$+,fgrep -v $(h) |) xargs -n 1 htmlautoimports $+

out: ## Build output
	find html -type f -print0 | sed -z 's/^html\//out\//' | xargs -0 -n 1 $(MAKE) -B --no-print-directory
ifeq ($(check_out),1)
	$(MAKE) check-out
endif

html:
	$(MAKE) updatetime
	$(MAKE) xref
	$(MAKE) check

check:
	find html -type f -name "*.html" -print0 | xargs -0 -n 1 html-check >/dev/null

check-out:
	find out -type f -name "*.html" -print0 | xargs -0 -n 1 html-check >/dev/null

out/%.html: html/%.html
	@mkdir -p '$(@D)'
	( cd '$(<D)'; html-includetag | html-expandurl | html-template | html-markdown | html-expandurl ) <'$<' >'$@'

out/%: html/%
	@mkdir -p '$(@D)'
	cp -f '$<' '$@'

diff: ## Show differences
	diff -urNbB html out

install: ## Install required tools to make this work
	go get -u github.com/mildred/htmltools/...
	go install github.com/mildred/htmltools/...

help: ## This help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36mmake %-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help out diff install autoimports xref add-index-links-to-blog-posts all html updatetime check check-out
