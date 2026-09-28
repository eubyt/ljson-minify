(in-package #:ljson/tests/logger)

(declaim (ftype (function () (values)) test-logger-emission-when-enabled))
(defun test-logger-emission-when-enabled ()
  "Verifica se a linha de log JSON é emitida quando a verbosidade está ativa.
Exemplo: (test-logger-emission-when-enabled)"
  (let* ((sink-stream (make-string-output-stream))
         (sink (make-json-log-sink :destination-stream sink-stream :verbosity-enabled-p t)))
    (emit-structured-log sink "INFO" "scanner" "Análise concluída com sucesso")
    (let ((output (get-output-stream-string sink-stream)))
      (assert-true (search "\"level\":\"INFO\"" output) "Log possui nível INFO")
      (assert-true (search "\"component\":\"scanner\"" output) "Log possui componente scanner")
      (assert-true (search "\"message\":\"Análise concluída com sucesso\"" output) "Log possui mensagem")
      (assert-true (search "\"timestamp\":" output) "Log possui timestamp")))
  (values))

(declaim (ftype (function () (values)) test-logger-suppressed-when-disabled))
(defun test-logger-suppressed-when-disabled ()
  "Verifica se nenhuma saída de log é gerada quando a verbosidade está inativa.
Exemplo: (test-logger-suppressed-when-disabled)"
  (let* ((sink-stream (make-string-output-stream))
         (sink (make-json-log-sink :destination-stream sink-stream :verbosity-enabled-p nil)))
    (emit-structured-log sink "DEBUG" "minifier" "Não deve ser registrado")
    (let ((output (get-output-stream-string sink-stream)))
      (assert-equal "" output "Silencioso quando verbosidade é nil")))
  (values))

(declaim (ftype (function () (values)) register-logger-tests))
(defun register-logger-tests ()
  "Registra todos os testes do logger estruturado no framework de teste.
Exemplo: (register-logger-tests)"
  (define-test-case "logger-emission-when-enabled" :logger
    (test-logger-emission-when-enabled))
  (define-test-case "logger-suppressed-when-disabled" :logger
    (test-logger-suppressed-when-disabled))
  (values))
