(in-package #:ljson/tests/scanner)

(declaim (ftype (function () (values)) test-scanner-structural-chars))
(defun test-scanner-structural-chars ()
  "Verifica a análise de espaços em branco e caracteres delimitadores estruturais.
Exemplo: (test-scanner-structural-chars)"
  (let ((tokens (tokenize-json-string " { } [ ] : , ")))
    (assert-equal 6 (length tokens) "Analisou 6 tokens estruturais")
    (assert-equal :left-brace (token-family-of (first tokens)))
    (assert-equal :right-brace (token-family-of (second tokens)))
    (assert-equal :left-bracket (token-family-of (third tokens)))
    (assert-equal :right-bracket (token-family-of (fourth tokens)))
    (assert-equal :colon (token-family-of (fifth tokens)))
    (assert-equal :comma (token-family-of (sixth tokens))))
  (values))

(declaim (ftype (function () (values)) test-scanner-string-literals))
(defun test-scanner-string-literals ()
  "Verifica a análise de strings com códigos de escape e sequências unicode.
Exemplo: (test-scanner-string-literals)"
  (let* ((source "\"hello \\\"world\\\" \\n \\u0041\"")
         (tokens (tokenize-json-string source)))
    (assert-equal 1 (length tokens) "Token único de string produzido")
    (assert-equal :string-literal (token-family-of (first tokens)))
    (assert-equal source (token-lexeme-of (first tokens)) "Escapes preservados exatamente"))
  (values))

(declaim (ftype (function () (values)) test-scanner-unterminated-string))
(defun test-scanner-unterminated-string ()
  "Verifica que um literal de string não fechado sinaliza json-lexical-error.
Exemplo: (test-scanner-unterminated-string)"
  (assert-signals-condition
   'json-lexical-error
   (lambda () (tokenize-json-string "\"string sem aspas de fechamento"))
   "Erro de string não terminada")
  (values))

(declaim (ftype (function () (values)) test-scanner-numeric-literals))
(defun test-scanner-numeric-literals ()
  "Verifica a análise de números inteiros, negativos, ponto flutuante e notação científica.
Exemplo: (test-scanner-numeric-literals)"
  (let ((tokens (tokenize-json-string "0 -42 3.14159 1e+10 -2.5E-3")))
    (assert-equal 5 (length tokens) "Analisou 5 tokens numéricos")
    (dolist (tok tokens)
      (assert-equal :numeric-literal (token-family-of tok) "Token é numérico"))
    (assert-equal "0" (token-lexeme-of (first tokens)))
    (assert-equal "-42" (token-lexeme-of (second tokens)))
    (assert-equal "3.14159" (token-lexeme-of (third tokens)))
    (assert-equal "1e+10" (token-lexeme-of (fourth tokens)))
    (assert-equal "-2.5E-3" (token-lexeme-of (fifth tokens))))
  (values))

(declaim (ftype (function () (values)) test-scanner-keyword-literals))
(defun test-scanner-keyword-literals ()
  "Verifica a análise de palavras-chave true, false, null e rejeição de inválidas.
Exemplo: (test-scanner-keyword-literals)"
  (let ((tokens (tokenize-json-string "true false null")))
    (assert-equal 3 (length tokens) "Analisou 3 tokens de palavra-chave")
    (assert-equal :boolean-literal (token-family-of (first tokens)))
    (assert-equal :boolean-literal (token-family-of (second tokens)))
    (assert-equal :null-literal (token-family-of (third tokens))))
  (assert-signals-condition
   'json-lexical-error
   (lambda () (tokenize-json-string "undefined"))
   "Palavra-chave inválida dispara erro léxico")
  (values))

(declaim (ftype (function () (values)) register-scanner-tests))
(defun register-scanner-tests ()
  "Registra todos os testes unitários do scanner no framework de teste.
Exemplo: (register-scanner-tests)"
  (define-test-case "scanner-structural-chars" :scanner
    (test-scanner-structural-chars))
  (define-test-case "scanner-string-literals" :scanner
    (test-scanner-string-literals))
  (define-test-case "scanner-unterminated-string" :scanner
    (test-scanner-unterminated-string))
  (define-test-case "scanner-numeric-literals" :scanner
    (test-scanner-numeric-literals))
  (define-test-case "scanner-keyword-literals" :scanner
    (test-scanner-keyword-literals))
  (values))
