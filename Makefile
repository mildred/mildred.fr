add-index-link-to-blog-posts:
	sed -i -f add_index_to_blog_posts.sed html/Blog/*/*/*/*/index.html

xref:
	find html -name "*.html" | xargs -n 1 htmlxref
