all: test

test:
	@./node_modules/.bin/mocha --reporter spec --compilers coffee:coffee-script test/helper.coffee

.PHONY: all test
