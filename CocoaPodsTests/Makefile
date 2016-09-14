test: install repo_update
	@set -e; \
	for test in *_test.rb; do \
		bundle exec ./$$test; \
	done

repo_update:
	@bundle exec pod repo update

install:
	@bundle install --path gems

.PHONY: test install
