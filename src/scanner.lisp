(in-package #:ljson/scanner)

(defstruct (cursor-state
            (:constructor make-cursor-state ()))
  (offset 0 :type fixnum))

(declaim (ftype (function (character) boolean) whitespace-char-p))
(defun whitespace-char-p (character-value)
  "Verifica se CHARACTER-VALUE é espaço em branco RFC 8259 (espaço, tab, newline, retorno).
Exemplo: (whitespace-char-p #\\Space) => T"
  (check-type character-value character)
  (not (null (member character-value '(#\Space #\Tab #\Newline #\Return)))))

(declaim (ftype (function (character) boolean) structural-char-p))
(defun structural-char-p (character-value)
  "Verifica se CHARACTER-VALUE é um dos delimitadores estruturais JSON.
Exemplo: (structural-char-p #\\{) => T"
  (check-type character-value character)
  (not (null (member character-value '(#\{ #\} #\[ #\] #\: #\,)))))

(declaim (ftype (function (character) token-family) structural-char-to-family))
(defun structural-char-to-family (character-value)
  "Converte um caractere delimitador estrutural na palavra-chave da família do token.
Exemplo: (structural-char-to-family #\\:) => :colon"
  (check-type character-value character)
  (case character-value
    (#\{ :left-brace)
    (#\} :right-brace)
    (#\[ :left-bracket)
    (#\] :right-bracket)
    (#\: :colon)
    (#\, :comma)
    (otherwise (signal-lexical-violation character-value "um dos delimitadores { } [ ] : ," 0))))

(declaim (ftype (function (character) boolean) hex-digit-char-p))
(defun hex-digit-char-p (character-value)
  "Determina se CHARACTER-VALUE é um dígito hexadecimal válido.
Exemplo: (hex-digit-char-p #\\F) => T"
  (check-type character-value character)
  (not (null (digit-char-p character-value 16))))

(declaim (ftype (function (stream cursor-state) (or character null)) cursor-read-char))
(defun cursor-read-char (input-stream cursor)
  "Lê um caractere de INPUT-STREAM e incrementa o deslocamento do CURSOR.
Exemplo: (cursor-read-char s cursor) => #\\a"
  (let ((ch (read-char input-stream nil nil)))
    (when ch
      (incf (cursor-state-offset cursor)))
    ch))

(declaim (ftype (function (stream) (or character null)) cursor-peek-char))
(defun cursor-peek-char (input-stream)
  "Observa o próximo caractere sem avançar a posição do fluxo.
Exemplo: (cursor-peek-char s) => #\\{\""
  (peek-char nil input-stream nil nil))

(declaim (ftype (function (stream cursor-state) (values)) skip-whitespace-characters))
(defun skip-whitespace-characters (input-stream cursor)
  "Avança sobre caracteres de espaço em branco contíguos no fluxo de entrada.
Exemplo: (skip-whitespace-characters s cursor)"
  (loop for next-char = (cursor-peek-char input-stream)
        while (and next-char (whitespace-char-p next-char))
        do (cursor-read-char input-stream cursor))
  (values))

(declaim (ftype (function (stream cursor-state stream) (values)) read-unicode-escape-sequence))
(defun read-unicode-escape-sequence (input-stream cursor buffer)
  "Lê 4 dígitos hexadecimais para sequência \\u e os adiciona ao BUFFER.
Exemplo: (read-unicode-escape-sequence s cursor buf)"
  (dotimes (i 4 (values))
    (let ((ch (cursor-read-char input-stream cursor)))
      (unless (and ch (hex-digit-char-p ch))
        (signal-lexical-violation (or ch "Fim de arquivo (EOF)")
                                  "4 dígitos hexadecimais após \\u"
                                  (cursor-state-offset cursor)))
      (write-char ch buffer))))

(declaim (ftype (function (stream cursor-state stream) (values)) read-escape-sequence-body))
(defun read-escape-sequence-body (input-stream cursor buffer)
  "Lê o caractere imediatamente após uma barra invertida dentro de uma string.
Exemplo: (read-escape-sequence-body s cursor buf)"
  (let ((ch (cursor-read-char input-stream cursor)))
    (unless ch
      (signal-lexical-violation "Fim de arquivo (EOF)" "caractere de escape válido após \\" (cursor-state-offset cursor)))
    (write-char ch buffer)
    (when (char= ch #\u)
      (read-unicode-escape-sequence input-stream cursor buffer))
    (unless (member ch '(#\" #\\ #\/ #\b #\f #\n #\r #\t #\u))
      (signal-lexical-violation ch "caractere de escape JSON válido (\", \\, /, b, f, n, r, t, u)" (cursor-state-offset cursor)))
    (values)))

(declaim (ftype (function (stream cursor-state) json-lex-token) scan-string-literal-token))
(defun scan-string-literal-token (input-stream cursor)
  "Analisa um token literal de string entre aspas incluindo sequências de escape.
Exemplo: (scan-string-literal-token s cursor)"
  (let ((start-offset (cursor-state-offset cursor))
        (buf (make-string-output-stream)))
    (write-char (cursor-read-char input-stream cursor) buf)
    (loop for ch = (cursor-read-char input-stream cursor) do
      (unless ch
        (signal-lexical-violation "Fim de arquivo (EOF)" "aspas de fechamento para string" start-offset))
      (write-char ch buf)
      (when (char= ch #\")
        (return (make-json-lex-token :string-literal (get-output-stream-string buf) start-offset)))
      (when (char= ch #\\)
        (read-escape-sequence-body input-stream cursor buf)))))

(declaim (ftype (function (character) boolean) number-constituent-char-p))
(defun number-constituent-char-p (character-value)
  "Retorna verdadeiro se CHARACTER-VALUE puder compor um número JSON.
Exemplo: (number-constituent-char-p #\\5) => T"
  (check-type character-value character)
  (not (null (find character-value "0123456789+-.eE"))))

(declaim (ftype (function (stream cursor-state) json-lex-token) scan-number-literal-token))
(defun scan-number-literal-token (input-stream cursor)
  "Analisa um token literal numérico JSON a partir do fluxo de entrada.
Exemplo: (scan-number-literal-token s cursor) => #<json-lex-token ...>"
  (let ((start-offset (cursor-state-offset cursor))
        (buf (make-string-output-stream)))
    (loop for next-char = (cursor-peek-char input-stream)
          while (and next-char (number-constituent-char-p next-char))
          do (write-char (cursor-read-char input-stream cursor) buf))
    (let ((lexeme (get-output-stream-string buf)))
      (when (zerop (length lexeme))
        (signal-lexical-violation "vazio" "número JSON válido" start-offset))
      (make-json-lex-token :numeric-literal lexeme start-offset))))

(declaim (ftype (function (character) boolean) keyword-constituent-char-p))
(defun keyword-constituent-char-p (character-value)
  "Verifica se CHARACTER-VALUE é uma letra minúscula para palavras-chave literais.
Exemplo: (keyword-constituent-char-p #\\t) => T"
  (check-type character-value character)
  (and (char>= character-value #\a) (char<= character-value #\z)))

(declaim (ftype (function (string fixnum) json-lex-token) build-keyword-token))
(defun build-keyword-token (lexeme start-offset)
  "Mapeia a string do lexema da palavra-chave para um token booleano ou nulo.
Exemplo: (build-keyword-token \"true\" 0) => #<json-lex-token ...>"
  (check-type lexeme string)
  (check-type start-offset fixnum)
  (cond
    ((string= lexeme "true") (make-json-lex-token :boolean-literal lexeme start-offset))
    ((string= lexeme "false") (make-json-lex-token :boolean-literal lexeme start-offset))
    ((string= lexeme "null") (make-json-lex-token :null-literal lexeme start-offset))
    (t (signal-lexical-violation lexeme "um dos literais: true, false, null" start-offset))))

(declaim (ftype (function (stream cursor-state) json-lex-token) scan-keyword-token))
(defun scan-keyword-token (input-stream cursor)
  "Analisa uma palavra-chave literal (true, false, null) a partir do fluxo.
Exemplo: (scan-keyword-token s cursor) => #<json-lex-token ...>"
  (let ((start-offset (cursor-state-offset cursor))
        (buf (make-string-output-stream)))
    (loop for next-char = (cursor-peek-char input-stream)
          while (and next-char (keyword-constituent-char-p next-char))
          do (write-char (cursor-read-char input-stream cursor) buf))
    (build-keyword-token (get-output-stream-string buf) start-offset)))

(declaim (ftype (function (stream cursor-state) json-lex-token) scan-single-token))
(defun scan-single-token (input-stream cursor)
  "Analisa o próximo token léxico disponível a partir do fluxo de entrada.
Exemplo: (scan-single-token s cursor) => #<json-lex-token ...>"
  (skip-whitespace-characters input-stream cursor)
  (let ((peek (cursor-peek-char input-stream))
        (offset (cursor-state-offset cursor)))
    (cond
      ((null peek) (make-json-lex-token :eof-marker "" offset))
      ((char= peek #\") (scan-string-literal-token input-stream cursor))
      ((structural-char-p peek)
       (cursor-read-char input-stream cursor)
       (make-json-lex-token (structural-char-to-family peek) (string peek) offset))
      ((or (digit-char-p peek) (char= peek #\-)) (scan-number-literal-token input-stream cursor))
      ((keyword-constituent-char-p peek) (scan-keyword-token input-stream cursor))
      (t (signal-lexical-violation peek "caractere inicial de JSON válido" offset)))))

(declaim (ftype (function (stream) list) tokenize-json-stream))
(defun tokenize-json-stream (input-stream)
  "Converte todo o fluxo de entrada em uma lista de tokens léxicos JSON.
Exemplo: (tokenize-json-stream s) => (#<json-lex-token ...> ...)"
  (let ((cursor (make-cursor-state))
        (tokens '()))
    (loop
      (let ((tok (scan-single-token input-stream cursor)))
        (when (eq (token-family-of tok) :eof-marker)
          (return (nreverse tokens)))
        (push tok tokens)))))

(declaim (ftype (function (string) list) tokenize-json-string))
(defun tokenize-json-string (source-text)
  "Converte uma string JSON em uma sequência de tokens léxicos.
Exemplo: (tokenize-json-string \"{\\\"chave\\\": 123}\")"
  (check-type source-text string)
  (with-input-from-string (stream source-text)
    (tokenize-json-stream stream)))
