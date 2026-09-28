(asdf:defsystem #:ljson
  :description "Minificador e formatador (unminify) de JSON rápido e sem dependências para CLI em Common Lisp"
  :version "0.1.0"
  :pathname "src"
  :serial t
  :components ((:file "packages")
               (:file "conditions")
               (:file "token")
               (:file "scanner")
               (:file "minifier")
               (:file "unminifier")
               (:file "io-adapter")
               (:file "logger")
               (:file "cli")
               (:file "main"))
  :in-order-to ((asdf:test-op (asdf:test-op #:ljson/tests))))

(asdf:defsystem #:ljson/tests
  :description "Suíte de testes para ljson"
  :depends-on (#:ljson)
  :pathname "tests"
  :serial t
  :components ((:file "packages")
               (:file "test-framework")
               (:file "test-token")
               (:file "test-conditions")
               (:file "test-scanner")
               (:file "test-minifier")
               (:file "test-unminifier")
               (:file "test-io-adapter")
               (:file "test-logger")
               (:file "test-cli")
               (:file "run"))
  :perform (asdf:test-op (op c)
             (uiop:symbol-call :ljson/tests/run :run-all-project-tests)))
