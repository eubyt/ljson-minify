(in-package #:ljson/tests/framework)

(defparameter *registered-test-suite* '())

(defstruct (test-case-entry
            (:constructor make-test-case-entry (name category runner-thunk)))
  (name "" :type string)
  (category :general :type symbol)
  (runner-thunk (lambda () nil) :type function))

(declaim (ftype (function (string symbol function) (values)) register-test-case))
(defun register-test-case (name category runner-thunk)
  "Adiciona um caso de teste ao registro global da suíte.
Exemplo: (register-test-case \"teste-1\" :token #'minha-fn)"
  (check-type name string)
  (check-type category symbol)
  (check-type runner-thunk function)
  (setf *registered-test-suite*
        (append *registered-test-suite*
                (list (make-test-case-entry name category runner-thunk))))
  (values))

(declaim (ftype (function () (values)) clear-registered-tests))
(defun clear-registered-tests ()
  "Limpa todos os casos de teste registrados da suíte.
Exemplo: (clear-registered-tests)"
  (setf *registered-test-suite* '())
  (values))

(defmacro define-test-case (name category &body body)
  "Define e registra um caso de teste unitário nomeado.
Exemplo: (define-test-case \"token-check\" :token (assert-true t))"
  `(register-test-case
    ,name
    ,category
    (lambda () ,@body)))

(declaim (ftype (function (t t &optional string) (values)) assert-equal))
(defun assert-equal (expected actual &optional (label ""))
  "Garante que os valores EXPECTED e ACTUAL correspondam via EQUAL.
Exemplo: (assert-equal 42 (+ 40 2) \"Teste soma\")"
  (unless (equal expected actual)
    (error "Falha na asserção [~A]: esperado ~S mas obteve ~S" label expected actual))
  (values))

(declaim (ftype (function (t &optional string) (values)) assert-true))
(defun assert-true (value &optional (label ""))
  "Garante que VALUE não seja NIL.
Exemplo: (assert-true (> 5 2) \"Cinco é maior\")"
  (unless value
    (error "Falha na asserção [~A]: esperado valor verdadeiro mas obteve NIL" label))
  (values))

(declaim (ftype (function (t &optional string) (values)) assert-false))
(defun assert-false (value &optional (label ""))
  "Garante que VALUE seja NIL.
Exemplo: (assert-false (< 5 2) \"Cinco não é menor\")"
  (when value
    (error "Falha na asserção [~A]: esperado NIL mas obteve ~S" label value))
  (values))

(declaim (ftype (function (symbol function &optional string) (values)) assert-signals-condition))
(defun assert-signals-condition (expected-type body-thunk &optional (label ""))
  "Garante que a execução de BODY-THUNK sinalize uma condição EXPECTED-TYPE.
Exemplo: (assert-signals-condition 'error (lambda () (/ 1 0)))"
  (let ((signaled nil))
    (handler-case
        (funcall body-thunk)
      (condition (c)
        (when (typep c expected-type)
          (setf signaled t))))
    (unless signaled
      (error "Falha na asserção [~A]: condição esperada do tipo ~S não foi sinalizada"
             label expected-type)))
  (values))

(declaim (ftype (function (test-case-entry) (or null string)) run-single-test-safe))
(defun run-single-test-safe (test-entry)
  "Executa um teste unitário de forma segura, retornando string de erro se falhar.
Exemplo: (run-single-test-safe entrada)"
  (handler-case
      (progn
        (funcall (test-case-entry-runner-thunk test-entry))
        (write-char #\.)
        (force-output)
        nil)
    (error (e)
      (write-char #\F)
      (force-output)
      (format nil "~A [~A]: ~A"
              (test-case-entry-name test-entry)
              (test-case-entry-category test-entry)
              e))))

(declaim (ftype (function (fixnum fixnum list) boolean) print-test-summary))
(defun print-test-summary (total passed failed-messages)
  "Exibe o resumo da execução dos testes e retorna o resultado booleano.
Exemplo: (print-test-summary 10 10 nil)"
  (format t "~%~%=== RESUMO DOS TESTES ===~%")
  (format t "Total: ~D | Aprovados: ~D | Falhas: ~D~%" total passed (length failed-messages))
  (when failed-messages
    (format t "~%Falhas:~%")
    (dolist (msg failed-messages)
      (format t "  - ~A~%" msg)))
  (zerop (length failed-messages)))

(declaim (ftype (function () boolean) execute-all-registered-tests))
(defun execute-all-registered-tests ()
  "Executa todos os testes registrados isoladamente e relata resultados.
Exemplo: (execute-all-registered-tests)"
  (format t "Executando ~D testes: " (length *registered-test-suite*))
  (force-output)
  (let ((passed-count 0)
        (failed-list '()))
    (dolist (test-entry *registered-test-suite*)
      (let ((err (run-single-test-safe test-entry)))
        (if err
            (push err failed-list)
            (incf passed-count))))
    (print-test-summary (length *registered-test-suite*) passed-count (nreverse failed-list))))
