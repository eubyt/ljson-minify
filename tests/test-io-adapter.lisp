(in-package #:ljson/tests/io-adapter)

(declaim (ftype (function () (values)) test-in-memory-filesystem-lifecycle))
(defun test-in-memory-filesystem-lifecycle ()
  "Verifica escrita, semeadura, existência e leitura no sistema em memória.
Exemplo: (test-in-memory-filesystem-lifecycle)"
  (let ((fake-fs (make-in-memory-filesystem)))
    (assert-false (file-exists-p fake-fs "data.json") "Arquivo não existe inicialmente")
    (seed-file-content fake-fs "data.json" "{\"status\": \"semeado\"}")
    (assert-true (file-exists-p fake-fs "data.json") "Arquivo existe após semeadura")
    (assert-equal "{\"status\": \"semeado\"}" (read-file-content fake-fs "data.json"))
    (write-file-content fake-fs "out.json" "{\"status\": \"escrito\"}")
    (assert-equal "{\"status\": \"escrito\"}" (retrieve-file-content fake-fs "out.json")))
  (values))

(declaim (ftype (function () (values)) test-in-memory-filesystem-missing-file-error))
(defun test-in-memory-filesystem-missing-file-error ()
  "Verifica que ler caminho inexistente na memória sinaliza file-access-error.
Exemplo: (test-in-memory-filesystem-missing-file-error)"
  (let ((fake-fs (make-in-memory-filesystem)))
    (assert-signals-condition
     'file-access-error
     (lambda () (read-file-content fake-fs "ausente.json"))
     "Ler arquivo simulado inexistente sinaliza file-access-error"))
  (values))

(declaim (ftype (function () (values)) test-mock-stream-io-read-and-write))
(defun test-mock-stream-io-read-and-write ()
  "Verifica leitura e escrita com o adaptador simulado de fluxo nomeado.
Exemplo: (test-mock-stream-io-read-and-write)"
  (let ((fake-io (make-mock-stream-io "{\"entrada\": 1}")))
    (assert-equal "{\"entrada\": 1}" (read-entire-stream fake-io) "Leitura corresponde à entrada")
    (write-output-string fake-io (format nil "linha 1~%"))
    (write-output-string fake-io (format nil "linha 2~%"))
    (assert-equal (format nil "linha 1~%linha 2~%") (fetch-emitted-output fake-io)))
  (values))

(declaim (ftype (function () (values)) test-mock-stream-io-interactive-flag))
(defun test-mock-stream-io-interactive-flag ()
  "Verifica o predicado input-stream-interactive-p para mock-stream-io.
Exemplo: (test-mock-stream-io-interactive-flag)"
  (let ((non-interactive (make-mock-stream-io "data" nil))
        (interactive (make-mock-stream-io "data" t)))
    (assert-false (input-stream-interactive-p non-interactive) "Padrão do mock não é interativo")
    (assert-true (input-stream-interactive-p interactive) "Mock com flag interativa ativa retorna T"))
  (values))

(declaim (ftype (function () (values)) register-io-adapter-tests))
(defun register-io-adapter-tests ()
  "Registra os testes do adaptador de E/S e fakes no framework de teste.
Exemplo: (register-io-adapter-tests)"
  (define-test-case "in-memory-filesystem-lifecycle" :io-adapter
    (test-in-memory-filesystem-lifecycle))
  (define-test-case "in-memory-filesystem-missing-file-error" :io-adapter
    (test-in-memory-filesystem-missing-file-error))
  (define-test-case "mock-stream-io-read-and-write" :io-adapter
    (test-mock-stream-io-read-and-write))
  (define-test-case "mock-stream-io-interactive-flag" :io-adapter
    (test-mock-stream-io-interactive-flag))
  (values))
