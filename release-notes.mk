.PHONY: release-notes

release-notes:
	curr_ver=$(VERSION); \
	last_tag=$$(git tag -l '[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -n 2 |tail -1); \
	diffs="release-$$curr_ver.diffs"; \
	diff_list="release-$$curr_ver.lst"; \
	diff_tarball="release-$$curr_ver.tar.gz"; \
	echo "Comparing $$last_tag to current $$curr_ver..."; \
	git diff --no-ext-diff "$$last_tag" "$$curr_ver" > "$$diffs"; \
	git diff --name-only --diff-filter=AMR "$$last_tag" "$${curr_ver}" > "$$diff_list"; \
	tar -cf - --transform "s|^|release-$$curr_ver/|" -T "$$diff_list" | gzip > "$$diff_tarball"; \
	ls -alrt release-$${curr_ver}*.*
