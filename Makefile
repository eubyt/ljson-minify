.PHONY: all test build run clean

all: test

test:
	./scripts/run-tests

build:
	sbcl --noinform --non-interactive \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd (truename "ljson.asd"))' \
		--eval '(asdf:load-system :ljson)' \
		--eval '(sb-ext:save-lisp-and-die "bin/ljson-bin" :executable t :save-runtime-options t :toplevel (quote ljson/main:cli-main) :compression t)'

run:
	./scripts/ljson $(ARGS)

clean:
	rm -rf ~/.cache/common-lisp/*ljson* bin/ljson-bin
