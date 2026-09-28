(defpackage #:ljson/conditions
  (:use #:cl)
  (:export #:json-lexical-error
           #:json-syntax-error
           #:cli-argument-error
           #:file-access-error
           #:condition-offending-value
           #:condition-expected-shape
           #:condition-byte-offset
           #:signal-lexical-violation
           #:signal-syntax-violation
           #:signal-argument-violation
           #:signal-file-access-violation))

(defpackage #:ljson/token
  (:use #:cl #:ljson/conditions)
  (:export #:token-family
           #:json-lex-token
           #:make-json-lex-token
           #:token-family-of
           #:token-lexeme-of
           #:token-offset-of
           #:structural-token-p
           #:literal-token-p
           #:token-matches-p))

(defpackage #:ljson/scanner
  (:use #:cl #:ljson/conditions #:ljson/token)
  (:export #:tokenize-json-stream
           #:tokenize-json-string))

(defpackage #:ljson/minifier
  (:use #:cl #:ljson/conditions #:ljson/token #:ljson/scanner)
  (:export #:minify-token-sequence
           #:minify-json-string))

(defpackage #:ljson/unminifier
  (:use #:cl #:ljson/conditions #:ljson/token #:ljson/scanner)
  (:export #:unminify-token-sequence
           #:unminify-json-string))

(defpackage #:ljson/io-adapter
  (:use #:cl #:ljson/conditions)
  (:export #:abstract-filesystem
           #:read-file-content
           #:write-file-content
           #:file-exists-p
           #:system-filesystem
           #:make-system-filesystem
           #:in-memory-filesystem
           #:make-in-memory-filesystem
           #:seed-file-content
           #:retrieve-file-content
           #:abstract-stream-io
           #:read-entire-stream
           #:write-output-string
           #:standard-stream-io
           #:make-standard-stream-io
           #:mock-stream-io
           #:make-mock-stream-io
           #:fetch-emitted-output
           #:input-stream-interactive-p))

(defpackage #:ljson/logger
  (:use #:cl)
  (:export #:json-log-sink
           #:make-json-log-sink
           #:emit-structured-log))

(defpackage #:ljson/cli
  (:use #:cl #:ljson/conditions #:ljson/token #:ljson/minifier
        #:ljson/unminifier #:ljson/io-adapter #:ljson/logger)
  (:export #:cli-invocation-config
           #:make-cli-invocation-config
           #:config-action-mode
           #:config-input-filepath
           #:config-output-filepath
           #:config-indent-width
           #:config-verbosity-enabled
           #:config-help-requested
           #:parse-cli-arguments
           #:execute-cli-action))

(defpackage #:ljson/main
  (:use #:cl #:ljson/cli #:ljson/io-adapter #:ljson/logger)
  (:export #:run-cli-application
           #:cli-main))
