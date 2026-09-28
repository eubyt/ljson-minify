(in-package #:ljson/tests/token)

(declaim (ftype (function () (values)) test-token-creation-and-accessors))
(defun test-token-creation-and-accessors ()
  "Testa o construtor do token e as funções de acesso.
Exemplo: (test-token-creation-and-accessors)"
  (let ((tok (make-json-lex-token :left-brace "{" 15)))
    (assert-equal :left-brace (token-family-of tok) "Família do token corresponde")
    (assert-equal "{" (token-lexeme-of tok) "Lexema do token corresponde")
    (assert-equal 15 (token-offset-of tok) "Deslocamento de byte do token corresponde"))
  (values))

(declaim (ftype (function () (values)) test-token-predicates))
(defun test-token-predicates ()
  "Verifica os predicados de classificação estrutural e literal de tokens.
Exemplo: (test-token-predicates)"
  (let ((delim (make-json-lex-token :colon ":" 0))
        (str (make-json-lex-token :string-literal "\"foo\"" 2))
        (num (make-json-lex-token :numeric-literal "42" 8)))
    (assert-true (structural-token-p delim) "Dois-pontos é estrutural")
    (assert-false (structural-token-p str) "String não é estrutural")
    (assert-true (literal-token-p str) "String é literal")
    (assert-true (literal-token-p num) "Número é literal")
    (assert-false (literal-token-p delim) "Dois-pontos não é literal")
    (assert-true (token-matches-p delim :colon) "Corresponde à família de dois-pontos")
    (assert-false (token-matches-p delim :comma) "Não corresponde à família de vírgula"))
  (values))

(declaim (ftype (function () (values)) register-token-tests))
(defun register-token-tests ()
  "Registra todos os testes unitários de token no framework de teste.
Exemplo: (register-token-tests)"
  (define-test-case "token-creation-and-accessors" :token
    (test-token-creation-and-accessors))
  (define-test-case "token-predicates" :token
    (test-token-predicates))
  (values))
