(in-package #:ljson/logger)

(defstruct (json-log-sink
            (:constructor %make-json-log-sink))
  (destination-stream *error-output* :type stream)
  (verbosity-enabled-p nil :type boolean))

(declaim (ftype (function (&key (:destination-stream stream) (:verbosity-enabled-p boolean)) json-log-sink)
                make-json-log-sink))
(defun make-json-log-sink (&key (destination-stream *error-output*) (verbosity-enabled-p nil))
  "Constrói um coletor de logs JSON estruturado escrevendo em DESTINATION-STREAM.
Exemplo: (make-json-log-sink :verbosity-enabled-p t)"
  (check-type destination-stream stream)
  (check-type verbosity-enabled-p boolean)
  (%make-json-log-sink :destination-stream destination-stream
                       :verbosity-enabled-p verbosity-enabled-p))

(declaim (ftype (function (character stream) (values)) write-escaped-log-char))
(defun write-escaped-log-char (ch output-stream)
  "Escapa caracteres para codificação JSON válida dentro de mensagens de log.
Exemplo: (write-escaped-log-char #\\\" s)"
  (case ch
    (#\" (write-string "\\\"" output-stream))
    (#\\ (write-string "\\\\" output-stream))
    (#\Newline (write-string "\\n" output-stream))
    (otherwise (write-char ch output-stream)))
  (values))

(declaim (ftype (function (string) string) sanitize-log-string))
(defun sanitize-log-string (raw-text)
  "Escapa caracteres especiais em RAW-TEXT para formato de string JSON seguro.
Exemplo: (sanitize-log-string \"ola \\\"mundo\\\"\")"
  (check-type raw-text string)
  (with-output-to-string (stream)
    (loop for ch across raw-text do
      (write-escaped-log-char ch stream))))

(declaim (ftype (function (string string string) string) format-structured-json-entry))
(defun format-structured-json-entry (severity component-name message-body)
  "Compõe uma linha de entrada de log JSON estruturada.
Exemplo: (format-structured-json-entry \"INFO\" \"scanner\" \"Iniciou analise\")"
  (let ((clean-component (sanitize-log-string component-name))
        (clean-message (sanitize-log-string message-body))
        (timestamp (get-universal-time)))
    (format nil "{\"timestamp\":~D,\"level\":~S,\"component\":~S,\"message\":~S}"
            timestamp severity clean-component clean-message)))

(declaim (ftype (function (json-log-sink string string string) (values)) emit-structured-log))
(defun emit-structured-log (sink severity component-name message-body)
  "Emite uma entrada de log JSON estruturada caso a verbosidade do SINK esteja ativa.
Exemplo: (emit-structured-log sink \"DEBUG\" \"scanner\" \"Processou 10 tokens\")"
  (check-type sink json-log-sink)
  (unless (json-log-sink-verbosity-enabled-p sink)
    (return-from emit-structured-log (values)))
  (let ((entry (format-structured-json-entry severity component-name message-body)))
    (write-line entry (json-log-sink-destination-stream sink))
    (force-output (json-log-sink-destination-stream sink))
    (values)))
