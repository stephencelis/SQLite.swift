test: install
	@set -e; \
	for test in *_test.rb; do \
		bundle exec ./$$test; \
	done

install:
	@bundle install --path gems

.PHONY: test install
