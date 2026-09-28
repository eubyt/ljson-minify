(in-package #:ljson/tests/cli)

(declaim (ftype (function () (values)) test-cli-argument-parsing))
(defun test-cli-argument-parsing ()
  "Verifica a análise de subcomandos, opções e caminhos de arquivo posicionais.
Exemplo: (test-cli-argument-parsing)"
  (let ((cfg (parse-cli-arguments '("unminify" "-i" "in.json" "-o" "out.json" "-s" "4" "-v"))))
    (assert-equal :unminify (config-action-mode cfg))
    (assert-equal "in.json" (config-input-filepath cfg))
    (assert-equal "out.json" (config-output-filepath cfg))
    (assert-equal 4 (config-indent-width cfg))
    (assert-true (config-verbosity-enabled cfg))
    (assert-false (config-help-requested cfg)))
  (let ((cfg2 (parse-cli-arguments '("minify" "posicional.json"))))
    (assert-equal :minify (config-action-mode cfg2))
    (assert-equal "posicional.json" (config-input-filepath cfg2)))
  (values))

(declaim (ftype (function () (values)) test-cli-invalid-arguments))
(defun test-cli-invalid-arguments ()
  "Verifica se opções inválidas de CLI sinalizam cli-argument-error.
Exemplo: (test-cli-invalid-arguments)"
  (assert-signals-condition
   'cli-argument-error
   (lambda () (parse-cli-arguments '("--opcao-inexistente")))
   "Opção desconhecida sinaliza erro")
  (assert-signals-condition
   'cli-argument-error
   (lambda () (parse-cli-arguments '("-s" "nao-e-numero")))
   "Indentação não numérica sinaliza erro")
  (values))

(declaim (ftype (function () (values)) test-cli-execute-minify-stream))
(defun test-cli-execute-minify-stream ()
  "Executa a ação minify através de E/S simulada de fluxo.
Exemplo: (test-cli-execute-minify-stream)"
  (let* ((cfg (make-cli-invocation-config :action-mode :minify))
         (fs (make-in-memory-filesystem))
         (io (make-mock-stream-io "{ \"chave\" : [ 1 , 2 ] }"))
         (log (make-json-log-sink))
         (status (execute-cli-action cfg fs io log)))
    (assert-equal 0 status "Execução retornou 0")
    (assert-equal (format nil "{\"chave\":[1,2]}~%") (fetch-emitted-output io)))
  (values))

(declaim (ftype (function () (values)) test-cli-execute-unminify-filesystem))
(defun test-cli-execute-unminify-filesystem ()
  "Executa a ação unminify através de sistema de arquivos em memória simulado.
Exemplo: (test-cli-execute-unminify-filesystem)"
  (let* ((cfg (make-cli-invocation-config :action-mode :unminify
                                         :input-filepath "input.json"
                                         :output-filepath "pretty.json"
                                         :indent-width 2))
         (fs (make-in-memory-filesystem))
         (io (make-mock-stream-io))
         (log (make-json-log-sink)))
    (seed-file-content fs "input.json" "{\"a\":1}")
    (assert-equal 0 (execute-cli-action cfg fs io log))
    (assert-equal (format nil "{~%  \"a\": 1~%}") (retrieve-file-content fs "pretty.json")))
  (values))

(declaim (ftype (function () (values)) test-cli-execute-help-flag))
(defun test-cli-execute-help-flag ()
  "Verifica se a opção --help emite o guia em texto puro e retorna 0.
Exemplo: (test-cli-execute-help-flag)"
  (let* ((cfg (make-cli-invocation-config :help-requested t))
         (fs (make-in-memory-filesystem))
         (io (make-mock-stream-io))
         (log (make-json-log-sink)))
    (assert-equal 0 (execute-cli-action cfg fs io log))
    (let ((out (fetch-emitted-output io)))
      (assert-true (search "Uso: ljson" out) "Manual de uso em texto puro emitido")))
  (values))

(declaim (ftype (function () (values)) test-cli-execute-interactive-stream-shows-help))
(defun test-cli-execute-interactive-stream-shows-help ()
  "Verifica se a CLI emite o guia de uso e sai limpa ao rodar em terminal interativo sem arquivo de entrada.
Exemplo: (test-cli-execute-interactive-stream-shows-help)"
  (let* ((cfg (make-cli-invocation-config :action-mode :minify))
         (fs (make-in-memory-filesystem))
         (io (make-mock-stream-io "" t))
         (log (make-json-log-sink))
         (status (execute-cli-action cfg fs io log)))
    (assert-equal 0 status "Execução interativa retorna 0")
    (let ((out (fetch-emitted-output io)))
      (assert-true (search "Uso: ljson" out) "Exibe manual de uso ao invés de travar esperando stdin")))
  (values))

(declaim (ftype (function () (values)) register-cli-tests))
(defun register-cli-tests ()
  "Registra todos os testes unitários da CLI no framework de teste.
Exemplo: (register-cli-tests)"
  (define-test-case "cli-argument-parsing" :cli
    (test-cli-argument-parsing))
  (define-test-case "cli-invalid-arguments" :cli
    (test-cli-invalid-arguments))
  (define-test-case "cli-execute-minify-stream" :cli
    (test-cli-execute-minify-stream))
  (define-test-case "cli-execute-unminify-filesystem" :cli
    (test-cli-execute-unminify-filesystem))
  (define-test-case "cli-execute-help-flag" :cli
    (test-cli-execute-help-flag))
  (define-test-case "cli-execute-interactive-stream-shows-help" :cli
    (test-cli-execute-interactive-stream-shows-help))
  (values))
