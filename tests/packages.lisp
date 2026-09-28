(defpackage #:ljson/tests/framework
  (:use #:cl)
  (:export #:assert-equal
           #:assert-true
           #:assert-false
           #:assert-signals-condition
           #:define-test-case
           #:register-test-case
           #:clear-registered-tests
           #:execute-all-registered-tests))

(defpackage #:ljson/tests/token
  (:use #:cl #:ljson/token #:ljson/tests/framework)
  (:export #:register-token-tests))

(defpackage #:ljson/tests/conditions
  (:use #:cl #:ljson/conditions #:ljson/tests/framework)
  (:export #:register-conditions-tests))

(defpackage #:ljson/tests/scanner
  (:use #:cl #:ljson/conditions #:ljson/token #:ljson/scanner #:ljson/tests/framework)
  (:export #:register-scanner-tests))

(defpackage #:ljson/tests/minifier
  (:use #:cl #:ljson/conditions #:ljson/token #:ljson/scanner #:ljson/minifier #:ljson/tests/framework)
  (:export #:register-minifier-tests))

(defpackage #:ljson/tests/unminifier
  (:use #:cl #:ljson/conditions #:ljson/token #:ljson/scanner #:ljson/unminifier #:ljson/tests/framework)
  (:export #:register-unminifier-tests))

(defpackage #:ljson/tests/io-adapter
  (:use #:cl #:ljson/conditions #:ljson/io-adapter #:ljson/tests/framework)
  (:export #:register-io-adapter-tests))

(defpackage #:ljson/tests/logger
  (:use #:cl #:ljson/logger #:ljson/tests/framework)
  (:export #:register-logger-tests))

(defpackage #:ljson/tests/cli
  (:use #:cl #:ljson/conditions #:ljson/io-adapter #:ljson/logger #:ljson/cli #:ljson/tests/framework)
  (:export #:register-cli-tests))

(defpackage #:ljson/tests/run
  (:use #:cl #:ljson/tests/framework)
  (:export #:run-all-project-tests
           #:test-runner-main))
