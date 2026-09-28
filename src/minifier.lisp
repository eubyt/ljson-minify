(in-package #:ljson/minifier)

(declaim (ftype (function (json-lex-token stream) (values)) write-token-lexeme))
(defun write-token-lexeme (token output-stream)
  "Escreve o lexema original de TOKEN diretamente em OUTPUT-STREAM sem espaçamento.
Exemplo: (write-token-lexeme (make-json-lex-token :colon \":\" 0) s)"
  (check-type token json-lex-token)
  (write-string (token-lexeme-of token) output-stream)
  (values))

(declaim (ftype (function (list) (values)) validate-token-sequence-nonempty))
(defun validate-token-sequence-nonempty (tokens)
  "Garante que a lista TOKENS não esteja vazia, sinalizando erro caso ausente.
Exemplo: (validate-token-sequence-nonempty tokens)"
  (when (null tokens)
    ;; A seção 2 da RFC 8259 exige ao menos um valor de texto JSON
    (signal-syntax-violation "Fim de arquivo (EOF)" "ao menos um valor JSON válido" 0))
  (values))

(declaim (ftype (function (list stream) (values)) emit-minified-tokens))
(defun emit-minified-tokens (tokens output-stream)
  "Itera sobre TOKENS e emite cada lexema sequencialmente em OUTPUT-STREAM.
Exemplo: (emit-minified-tokens tokens s)"
  (validate-token-sequence-nonempty tokens)
  (dolist (tok tokens (values))
    (write-token-lexeme tok output-stream)))

(declaim (ftype (function (list) string) minify-token-sequence))
(defun minify-token-sequence (tokens)
  "Serializa uma lista de tokens léxicos em uma string JSON minificada.
Exemplo: (minify-token-sequence tokens) => \"{\\\"a\\\":1}\""
  (validate-token-sequence-nonempty tokens)
  (with-output-to-string (stream)
    (emit-minified-tokens tokens stream)))

(declaim (ftype (function (string) string) minify-json-string))
(defun minify-json-string (source-text)
  "Converte SOURCE-TEXT em tokens e produz uma representação JSON minificada.
Exemplo: (minify-json-string \"[ 1 , 2 , 3 ]\") => \"[1,2,3]\""
  (check-type source-text string)
  (let ((tokens (tokenize-json-string source-text)))
    (minify-token-sequence tokens)))
