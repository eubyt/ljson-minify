(in-package #:ljson/token)

(deftype token-family ()
  '(member :left-brace
           :right-brace
           :left-bracket
           :right-bracket
           :colon
           :comma
           :string-literal
           :numeric-literal
           :boolean-literal
           :null-literal
           :eof-marker))

(defstruct (json-lex-token
            (:constructor %make-json-lex-token))
  (family :eof-marker :type token-family :read-only t)
  (lexeme "" :type string :read-only t)
  (byte-offset 0 :type fixnum :read-only t))

(declaim (ftype (function (token-family string fixnum) json-lex-token) make-json-lex-token))
(defun make-json-lex-token (family lexeme byte-offset)
  "Cria um novo token léxico JSON com restrições estruturais validadas.
Exemplo: (make-json-lex-token :left-brace \"{\" 0)"
  (check-type family symbol)
  (check-type lexeme string)
  (check-type byte-offset fixnum)
  ;; Construtor explícito encapsulando o gerador interno do defstruct
  (%make-json-lex-token :family family
                        :lexeme lexeme
                        :byte-offset byte-offset))

(declaim (ftype (function (json-lex-token) token-family) token-family-of))
(defun token-family-of (token)
  "Extrai a categoria da família léxica do token informado.
Exemplo: (token-family-of (make-json-lex-token :colon \":\" 2)) => :colon"
  (check-type token json-lex-token)
  (json-lex-token-family token))

(declaim (ftype (function (json-lex-token) string) token-lexeme-of))
(defun token-lexeme-of (token)
  "Obtém a string do lexema original do token informado.
Exemplo: (token-lexeme-of (make-json-lex-token :string-literal \"\\\"foo\\\"\" 0))"
  (check-type token json-lex-token)
  (json-lex-token-lexeme token))

(declaim (ftype (function (json-lex-token) fixnum) token-offset-of))
(defun token-offset-of (token)
  "Obtém o deslocamento de caractere (base zero) onde o token se inicia.
Exemplo: (token-offset-of (make-json-lex-token :comma \",\" 12)) => 12"
  (check-type token json-lex-token)
  (json-lex-token-byte-offset token))

(declaim (ftype (function (json-lex-token) boolean) structural-token-p))
(defun structural-token-p (token)
  "Verifica se TOKEN é um delimitador estrutural JSON ({ } [ ] : ,).
Exemplo: (structural-token-p (make-json-lex-token :comma \",\" 0)) => T"
  (check-type token json-lex-token)
  ;; Preserva a classificação da RFC 8259 para delimitadores estruturais
  (not (null (member (json-lex-token-family token)
                     '(:left-brace :right-brace :left-bracket :right-bracket :colon :comma)))))

(declaim (ftype (function (json-lex-token) boolean) literal-token-p))
(defun literal-token-p (token)
  "Verifica se TOKEN representa um literal primitivo JSON ou string.
Exemplo: (literal-token-p (make-json-lex-token :numeric-literal \"42\" 0)) => T"
  (check-type token json-lex-token)
  ;; Tokens não estruturais que carregam valores semânticos
  (not (null (member (json-lex-token-family token)
                     '(:string-literal :numeric-literal :boolean-literal :null-literal)))))

(declaim (ftype (function (json-lex-token token-family) boolean) token-matches-p))
(defun token-matches-p (token expected-family)
  "Testa se TOKEN pertence à categoria EXPECTED-FAMILY informada.
Exemplo: (token-matches-p (make-json-lex-token :right-brace \"}\" 5) :right-brace) => T"
  (check-type token json-lex-token)
  (check-type expected-family symbol)
  (eq (json-lex-token-family token) expected-family))
