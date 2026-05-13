.PHONY: install mock test-mock test-local test-html clean

install:
	npm install

mock:
	npm run mock:iot

test-mock:
	npm run test:mock

test-local:
	npm run test:local

test-html:
	npm run test:html

clean:
	rm -f reports/*.xml reports/*.html
