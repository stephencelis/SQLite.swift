test: install update
	@set -e; \
	for test in *_test.rb; do \
		bundle exec ./$$test; \
	done

update:
	@bundle exec pod repo update

install:
	@bundle install --path gems

.PHONY: test install
