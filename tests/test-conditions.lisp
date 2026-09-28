(in-package #:ljson/tests/conditions)

(declaim (ftype (function () (values)) test-lexical-condition-reporting))
(defun test-lexical-condition-reporting ()
  "Verifica se a formatação do erro léxico inclui o valor ofensivo e o formato esperado.
Exemplo: (test-lexical-condition-reporting)"
  (handler-case
      (signal-lexical-violation #\? "delimitador JSON válido" 12)
    (json-lexical-error (err)
      (let ((msg (princ-to-string err)))
        (assert-true (search "#\\?" msg) "Mensagem contém o caractere inválido")
        (assert-true (search "delimitador JSON válido" msg) "Mensagem contém o formato esperado")
        (assert-equal #\? (condition-offending-value err) "Acessor retorna o valor ofensivo")
        (assert-equal 12 (condition-byte-offset err) "Acessor retorna o deslocamento de byte"))))
  (values))

(declaim (ftype (function () (values)) test-syntax-condition-reporting))
(defun test-syntax-condition-reporting ()
  "Verifica se a formatação do erro de sintaxe inclui o valor ofensivo e o formato esperado.
Exemplo: (test-syntax-condition-reporting)"
  (handler-case
      (signal-syntax-violation "}" "string de chave ou delimitador de fechamento" 44)
    (json-syntax-error (err)
      (let ((msg (princ-to-string err)))
        (assert-true (search "}" msg) "Mensagem contém o token inválido")
        (assert-true (search "string de chave" msg) "Mensagem contém o formato esperado")
        (assert-equal "}" (condition-offending-value err) "Acessor corresponde")
        (assert-equal 44 (condition-byte-offset err) "Deslocamento corresponde"))))
  (values))

(declaim (ftype (function () (values)) test-argument-and-file-conditions))
(defun test-argument-and-file-conditions ()
  "Verifica a formatação de erros de argumento e de arquivo com valor e formato.
Exemplo: (test-argument-and-file-conditions)"
  (handler-case
      (signal-argument-violation "--invalido" "opção de CLI suportada")
    (cli-argument-error (err)
      (assert-equal "--invalido" (condition-offending-value err))
      (assert-true (search "opção de CLI suportada" (princ-to-string err)))))
  (handler-case
      (signal-file-access-violation "/caminho/invalido.json" "arquivo legível")
    (file-access-error (err)
      (assert-equal "/caminho/invalido.json" (condition-offending-value err))
      (assert-true (search "arquivo legível" (princ-to-string err)))))
  (values))

(declaim (ftype (function () (values)) register-conditions-tests))
(defun register-conditions-tests ()
  "Registra os testes de condições e relatório de erros com o framework.
Exemplo: (register-conditions-tests)"
  (define-test-case "lexical-condition-reporting" :conditions
    (test-lexical-condition-reporting))
  (define-test-case "syntax-condition-reporting" :conditions
    (test-syntax-condition-reporting))
  (define-test-case "argument-and-file-conditions" :conditions
    (test-argument-and-file-conditions))
  (values))
