all: ## Command to run the build
	$(MAKE) xref
	$(MAKE) out

add-index-link-to-blog-posts: ## Convert legacy files
	sed -i -f add_index_to_blog_posts.sed html/Blog/*/*/*/*/index.html

xref: ## Run htmlxref
	find html -name "*.html" | xargs -n 1 htmlxref

autoimports: ## Run htmlautoimports
	find html -name "*.html" -type f | fgrep -v html/footer.html | xargs -n 1 htmlautoimports html/footer.html

out: ## Build output
	find html -type f -print0 | sed -z 's/^html\//out\//' | xargs -0 -n 1 $(MAKE) -B --no-print-directory

out/%.html: html/%.html
	htmltags '$<' '$@'

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

.PHONY: help out diff install autoimports xref add-index-links-to-blog-posts all
