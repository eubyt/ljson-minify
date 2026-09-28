(in-package #:ljson/unminifier)

(defstruct (indent-context
            (:constructor %make-indent-context))
  (level 0 :type fixnum)
  (space-step 2 :type fixnum)
  (scope-stack '() :type list))

(declaim (ftype (function (&optional fixnum) indent-context) make-indent-context))
(defun make-indent-context (&optional (space-step 2))
  "Constrói um contexto de formatação com largura de indentação SPACE-STEP.
Exemplo: (make-indent-context 4)"
  (check-type space-step fixnum)
  (%make-indent-context :space-step space-step))

(declaim (ftype (function (stream indent-context) (values)) write-indentation-spaces))
(defun write-indentation-spaces (output-stream context)
  "Emite espaços de indentação conforme o nível atual de aninhamento.
Exemplo: (write-indentation-spaces s ctx)"
  (let ((total-spaces (* (indent-context-level context)
                         (indent-context-space-step context))))
    (dotimes (i total-spaces (values))
      (write-char #\Space output-stream))))

(declaim (ftype (function (token-family indent-context) (values)) push-scope-delimiter))
(defun push-scope-delimiter (family context)
  "Empilha o delimitador de fechamento esperado correspondente ao FAMILY de abertura.
Exemplo: (push-scope-delimiter :left-brace ctx)"
  (let ((expected (if (eq family :left-brace) :right-brace :right-bracket)))
    (push expected (indent-context-scope-stack context))
    (incf (indent-context-level context)))
  (values))

(declaim (ftype (function (token-family indent-context fixnum) (values)) pop-scope-delimiter))
(defun pop-scope-delimiter (family context offset)
  "Desempilha e valida o delimitador de fechamento esperado da pilha do contexto.
Exemplo: (pop-scope-delimiter :right-brace ctx 10)"
  (let ((expected (pop (indent-context-scope-stack context))))
    (unless (eq family expected)
      (signal-syntax-violation (princ-to-string family)
                               (format nil "delimitador de fechamento ~A" (or expected "de escopo"))
                               offset))
    (decf (indent-context-level context)))
  (values))

(declaim (ftype (function (token-family (or token-family null)) boolean) empty-container-pair-p))
(defun empty-container-pair-p (current-family next-family)
  "Verifica se CURRENT-FAMILY e NEXT-FAMILY formam um container vazio {} ou [].
Exemplo: (empty-container-pair-p :left-brace :right-brace) => T"
  (or (and (eq current-family :left-brace) (eq next-family :right-brace))
      (and (eq current-family :left-bracket) (eq next-family :right-bracket))))

(declaim (ftype (function (json-lex-token (or json-lex-token null) stream indent-context) boolean)
                format-open-container))
(defun format-open-container (curr-token next-token stream context)
  "Formata abertura de chaves/colchetes, tratando containers vazios de forma compacta.
Exemplo: (format-open-container tok next s ctx) => NIL"
  (let ((curr-fam (token-family-of curr-token))
        (next-fam (and next-token (token-family-of next-token))))
    (when (empty-container-pair-p curr-fam next-fam)
      (write-string (if (eq curr-fam :left-brace) "{}" "[]") stream)
      (return-from format-open-container t))
    (push-scope-delimiter curr-fam context)
    (write-char (if (eq curr-fam :left-brace) #\{ #\[) stream)
    (terpri stream)
    (write-indentation-spaces stream context)
    nil))

(declaim (ftype (function (json-lex-token stream indent-context) (values)) format-close-container))
(defun format-close-container (curr-token stream context)
  "Formata fechamento de chaves/colchetes, ajustando a profundidade de indentação.
Exemplo: (format-close-container tok s ctx)"
  (let ((curr-fam (token-family-of curr-token)))
    (pop-scope-delimiter curr-fam context (token-offset-of curr-token))
    (terpri stream)
    (write-indentation-spaces stream context)
    (write-char (if (eq curr-fam :right-brace) #\} #\]) stream)
    (values)))

(declaim (ftype (function (indent-context) (values)) verify-all-scopes-closed))
(defun verify-all-scopes-closed (context)
  "Assegura que todas as chaves e colchetes abertos foram fechados corretamente.
Exemplo: (verify-all-scopes-closed ctx)"
  (let ((remaining (indent-context-scope-stack context)))
    (when remaining
      (signal-syntax-violation "Fim de arquivo (EOF)" (format nil "delimitador de fechamento ~A" (first remaining)) 0)))
  (values))

(declaim (ftype (function (json-lex-token (or json-lex-token null) stream indent-context) boolean)
                format-structural-separator))
(defun format-structural-separator (curr-token next-token stream context)
  "Formata delimitadores de vírgula ou dois-pontos com o devido espaçamento.
Exemplo: (format-structural-separator tok next s ctx)"
  (declare (ignore next-token))
  (let ((fam (token-family-of curr-token)))
    (cond
      ((eq fam :colon)
       (write-string ": " stream)
       nil)
      ((eq fam :comma)
       (write-char #\, stream)
       (terpri stream)
       (write-indentation-spaces stream context)
       nil)
      (t nil))))

(declaim (ftype (function (json-lex-token (or json-lex-token null) stream indent-context) fixnum)
                dispatch-token-formatting))
(defun dispatch-token-formatting (curr next stream context)
  "Formata o token CURR, retornando a quantidade de tokens consumidos (1 ou 2).
Exemplo: (dispatch-token-formatting curr next s ctx) => 1"
  (let ((fam (token-family-of curr)))
    (cond
      ((member fam '(:left-brace :left-bracket))
       (if (format-open-container curr next stream context) 2 1))
      ((member fam '(:right-brace :right-bracket))
       (format-close-container curr stream context) 1)
      ((member fam '(:colon :comma))
       (format-structural-separator curr next stream context) 1)
      (t
       (write-string (token-lexeme-of curr) stream) 1))))

(declaim (ftype (function (list stream &optional fixnum) (values)) format-token-sequence))
(defun format-token-sequence (tokens stream &optional (space-step 2))
  "Itera sobre a lista TOKENS emitindo JSON formatado no fluxo de saída.
Exemplo: (format-token-sequence tokens s 2)"
  (let ((context (make-indent-context space-step))
        (remaining-tokens tokens))
    (loop while remaining-tokens do
      (let* ((curr (first remaining-tokens))
             (next (second remaining-tokens))
             (consumed (dispatch-token-formatting curr next stream context)))
        (setf remaining-tokens (nthcdr consumed remaining-tokens))))
    (verify-all-scopes-closed context)
    (values)))

(declaim (ftype (function (list &optional fixnum) string) unminify-token-sequence))
(defun unminify-token-sequence (tokens &optional (space-step 2))
  "Formata uma lista de tokens JSON em uma string com indentação legível.
Exemplo: (unminify-token-sequence tokens 2)"
  (when (null tokens)
    (signal-syntax-violation "Fim de arquivo (EOF)" "ao menos um valor JSON válido" 0))
  (with-output-to-string (stream)
    (format-token-sequence tokens stream space-step)))

(declaim (ftype (function (string &optional fixnum) string) unminify-json-string))
(defun unminify-json-string (source-text &optional (space-step 2))
  "Converte SOURCE-TEXT em tokens e o desminifica com a largura de indentação desejada.
Exemplo: (unminify-json-string \"{\\\"k\\\":1}\" 2) => \"{\\n  \\\"k\\\": 1\\n}\""
  (check-type source-text string)
  (let ((tokens (tokenize-json-string source-text)))
    (unminify-token-sequence tokens space-step)))
