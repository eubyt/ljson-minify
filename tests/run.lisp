(in-package #:ljson/tests/run)

(declaim (ftype (function () (values)) register-all-suites))
(defun register-all-suites ()
  "Preenche o registro global do framework de testes com todas as suítes.
Exemplo: (register-all-suites)"
  (ljson/tests/token:register-token-tests)
  (ljson/tests/conditions:register-conditions-tests)
  (ljson/tests/scanner:register-scanner-tests)
  (ljson/tests/minifier:register-minifier-tests)
  (ljson/tests/unminifier:register-unminifier-tests)
  (ljson/tests/io-adapter:register-io-adapter-tests)
  (ljson/tests/logger:register-logger-tests)
  (ljson/tests/cli:register-cli-tests)
  (values))

(declaim (ftype (function () boolean) run-all-project-tests))
(defun run-all-project-tests ()
  "Executa toda a suíte de testes e retorna verdadeiro se todos passarem.
Exemplo: (run-all-project-tests) => T"
  (clear-registered-tests)
  (register-all-suites)
  (execute-all-registered-tests))

(declaim (ftype (function () nil) test-runner-main))
(defun test-runner-main ()
  "Ponto de entrada de linha de comando para o executor de testes saindo com 0 ou 1.
Exemplo: (test-runner-main)"
  (let ((all-passed (run-all-project-tests)))
    (sb-ext:exit :code (if all-passed 0 1))))
