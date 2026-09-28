(in-package #:ljson/conditions)

(define-condition json-lexical-error (error)
  ((offending-value
    :initarg :offending-value
    :reader condition-offending-value)
   (expected-shape
    :initarg :expected-shape
    :reader condition-expected-shape)
   (byte-offset
    :initarg :byte-offset
    :reader condition-byte-offset))
  (:report (lambda (condition stream)
             ;; Formato exigido pelo guia: inclui o valor inválido e o formato esperado
             (format stream
                     "Erro léxico: valor inválido ~S no deslocamento ~D, formato esperado: ~A"
                     (condition-offending-value condition)
                     (condition-byte-offset condition)
                     (condition-expected-shape condition)))))

(define-condition json-syntax-error (error)
  ((offending-value
    :initarg :offending-value
    :reader condition-offending-value)
   (expected-shape
    :initarg :expected-shape
    :reader condition-expected-shape)
   (byte-offset
    :initarg :byte-offset
    :reader condition-byte-offset))
  (:report (lambda (condition stream)
             ;; Formato exigido pelo guia: inclui o valor inválido e o formato esperado
             (format stream
                     "Erro de sintaxe: valor inválido ~S no deslocamento ~D, formato esperado: ~A"
                     (condition-offending-value condition)
                     (condition-byte-offset condition)
                     (condition-expected-shape condition)))))

(define-condition cli-argument-error (error)
  ((offending-value
    :initarg :offending-value
    :reader condition-offending-value)
   (expected-shape
    :initarg :expected-shape
    :reader condition-expected-shape))
  (:report (lambda (condition stream)
             ;; Mensagem clara para o usuário quando uma flag ou valor é inválido
             (format stream
                     "Erro nos argumentos da CLI: valor inválido ~S, formato esperado: ~A"
                     (condition-offending-value condition)
                     (condition-expected-shape condition)))))

(define-condition file-access-error (error)
  ((offending-value
    :initarg :offending-value
    :reader condition-offending-value)
   (expected-shape
    :initarg :expected-shape
    :reader condition-expected-shape))
  (:report (lambda (condition stream)
             ;; Informa ao usuário quando a leitura ou escrita do arquivo falha
             (format stream
                     "Erro de acesso ao arquivo: valor inválido ~S, formato esperado: ~A"
                     (condition-offending-value condition)
                     (condition-expected-shape condition)))))

(declaim (ftype (function (t string fixnum) nil) signal-lexical-violation))
(defun signal-lexical-violation (offending-char expected-shape byte-offset)
  "Sinaliza uma violação léxica quando um caractere inesperado é encontrado.
Exemplo: (signal-lexical-violation #\\x \"dígito ou aspas válidas\" 42)"
  (check-type expected-shape string)
  (check-type byte-offset fixnum)
  (error 'json-lexical-error
         :offending-value offending-char
         :expected-shape expected-shape
         :byte-offset byte-offset))

(declaim (ftype (function (t string fixnum) nil) signal-syntax-violation))
(defun signal-syntax-violation (offending-token expected-shape byte-offset)
  "Sinaliza uma violação de sintaxe quando um token inesperado é encontrado.
Exemplo: (signal-syntax-violation \":\" \"token de valor após dois-pontos\" 10)"
  (check-type expected-shape string)
  (check-type byte-offset fixnum)
  (error 'json-syntax-error
         :offending-value offending-token
         :expected-shape expected-shape
         :byte-offset byte-offset))

(declaim (ftype (function (t string) nil) signal-argument-violation))
(defun signal-argument-violation (offending-arg expected-shape)
  "Sinaliza uma violação de argumentos da CLI para opções inválidas.
Exemplo: (signal-argument-violation \"--desconhecido\" \"um entre: minify, unminify, -i, -o\")"
  (check-type expected-shape string)
  (error 'cli-argument-error
         :offending-value offending-arg
         :expected-shape expected-shape))

(declaim (ftype (function (t string) nil) signal-file-access-violation))
(defun signal-file-access-violation (offending-path expected-shape)
  "Sinaliza uma violação de acesso a arquivo quando a operação de E/S falha.
Exemplo: (signal-file-access-violation \"/caminho/invalido\" \"arquivo regular legível\")"
  (check-type expected-shape string)
  (error 'file-access-error
         :offending-value offending-path
         :expected-shape expected-shape))
