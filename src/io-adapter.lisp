(in-package #:ljson/io-adapter)

(defclass abstract-filesystem ()
  ()
  (:documentation "Protocolo que define operações no sistema de arquivos para injeção de dependência."))

(defgeneric read-file-content (filesystem path)
  (:documentation "Lê todo o conteúdo textual do arquivo localizado em PATH."))

(defgeneric write-file-content (filesystem path content)
  (:documentation "Escreve a string CONTENT no arquivo localizado em PATH."))

(defgeneric file-exists-p (filesystem path)
  (:documentation "Determina se um arquivo existe no PATH informado."))

(defclass system-filesystem (abstract-filesystem)
  ()
  (:documentation "Gateway do sistema de arquivos real usando operações de arquivos padrão do SO."))

(declaim (ftype (function () system-filesystem) make-system-filesystem))
(defun make-system-filesystem ()
  "Constrói uma instância de SYSTEM-FILESYSTEM operando em disco real.
Exemplo: (make-system-filesystem)"
  (make-instance 'system-filesystem))

(defmethod file-exists-p ((filesystem system-filesystem) path)
  "Verifica se PATH existe no sistema de arquivos do sistema operacional.
Exemplo: (file-exists-p (make-system-filesystem) \"/caminho/arquivo.json\")"
  (check-type path string)
  (not (null (probe-file (pathname path)))))

(defmethod read-file-content ((filesystem system-filesystem) path)
  "Lê conteúdo de PATH do disco real, sinalizando erro caso inexistente.
Exemplo: (read-file-content (make-system-filesystem) \"input.json\")"
  (check-type path string)
  (unless (file-exists-p filesystem path)
    (signal-file-access-violation path "arquivo legível existente no sistema de arquivos"))
  (with-open-file (stream path :direction :input :element-type 'character)
    (let ((buffer (make-string (file-length stream))))
      (read-sequence buffer stream)
      buffer)))

(defmethod write-file-content ((filesystem system-filesystem) path content)
  "Escreve string CONTENT no PATH do sistema de arquivos do sistema operacional.
Exemplo: (write-file-content (make-system-filesystem) \"out.json\" \"{}\")"
  (check-type path string)
  (check-type content string)
  (with-open-file (stream path :direction :output :if-exists :supersede
                               :if-does-not-exist :create)
    (write-string content stream)
    (values)))

(defclass in-memory-filesystem (abstract-filesystem)
  ((storage-table
    :initform (make-hash-table :test 'equal)
    :reader filesystem-storage-table))
  (:documentation "Sistema de arquivos simulado em memória para testes unitários isolados e determinísticos."))

(declaim (ftype (function () in-memory-filesystem) make-in-memory-filesystem))
(defun make-in-memory-filesystem ()
  "Instancia um IN-MEMORY-FILESYSTEM isolado para testes rápidos sem E/S.
Exemplo: (make-in-memory-filesystem)"
  (make-instance 'in-memory-filesystem))

(defmethod file-exists-p ((filesystem in-memory-filesystem) path)
  "Verifica se PATH foi previamente semeado ou escrito na memória.
Exemplo: (file-exists-p fake-fs \"teste.json\")"
  (check-type path string)
  (nth-value 1 (gethash path (filesystem-storage-table filesystem))))

(defmethod read-file-content ((filesystem in-memory-filesystem) path)
  "Lê conteúdo da tabela do sistema de arquivos simulado em memória.
Exemplo: (read-file-content fake-fs \"teste.json\")"
  (check-type path string)
  (multiple-value-bind (val exists)
      (gethash path (filesystem-storage-table filesystem))
    (unless exists
      (signal-file-access-violation path "caminho de arquivo semeado no sistema de arquivos simulado"))
    val))

(defmethod write-file-content ((filesystem in-memory-filesystem) path content)
  "Armazena a string CONTENT na memória sob a chave PATH.
Exemplo: (write-file-content fake-fs \"out.json\" \"{}\")"
  (check-type path string)
  (check-type content string)
  (setf (gethash path (filesystem-storage-table filesystem)) content)
  (values))

(declaim (ftype (function (in-memory-filesystem string string) (values)) seed-file-content))
(defun seed-file-content (filesystem path content)
  "Pré-popula o sistema de arquivos em memória com dados de teste.
Exemplo: (seed-file-content fake-fs \"exemplo.json\" \"{\\\"a\\\":1}\")"
  (write-file-content filesystem path content))

(declaim (ftype (function (in-memory-filesystem string) (or string null)) retrieve-file-content))
(defun retrieve-file-content (filesystem path)
  "Recupera conteúdo armazenado diretamente da memória.
Exemplo: (retrieve-file-content fake-fs \"out.json\")"
  (gethash path (filesystem-storage-table filesystem)))

(defclass abstract-stream-io ()
  ()
  (:documentation "Protocolo que define operações de E/S de fluxo padrão para CLI."))

(defgeneric read-entire-stream (stream-io)
  (:documentation "Lê todo o conteúdo do fluxo de entrada."))

(defgeneric write-output-string (stream-io content)
  (:documentation "Escreve a string CONTENT no fluxo de saída."))

(defgeneric input-stream-interactive-p (stream-io)
  (:documentation "Determina se a entrada de fluxo é um terminal interativo."))

(defclass standard-stream-io (abstract-stream-io)
  ((in-stream :initarg :in-stream :reader standard-in-stream)
   (out-stream :initarg :out-stream :reader standard-out-stream))
  (:documentation "Adaptador concreto que encapsula *standard-input* e *standard-output*."))

(declaim (ftype (function (&optional stream stream) standard-stream-io) make-standard-stream-io))
(defun make-standard-stream-io (&optional (in-stream *standard-input*) (out-stream *standard-output*))
  "Cria adaptador de E/S padrão encapsulando os fluxos do console do sistema.
Exemplo: (make-standard-stream-io)"
  (make-instance 'standard-stream-io :in-stream in-stream :out-stream out-stream))

(defmethod input-stream-interactive-p ((stream-io standard-stream-io))
  "Determina se o fluxo de entrada padrão é interativo (terminal tty).
Exemplo: (input-stream-interactive-p (make-standard-stream-io))"
  (interactive-stream-p (standard-in-stream stream-io)))

(defmethod read-entire-stream ((stream-io standard-stream-io))
  "Lê todo o texto disponível do fluxo de entrada padrão até o EOF.
Exemplo: (read-entire-stream (make-standard-stream-io))"
  (with-output-to-string (sink)
    (loop for ch = (read-char (standard-in-stream stream-io) nil nil)
          while ch do (write-char ch sink))))

(defmethod write-output-string ((stream-io standard-stream-io) content)
  "Emite o texto CONTENT para o fluxo de saída padrão.
Exemplo: (write-output-string (make-standard-stream-io) \"saida\\n\")"
  (check-type content string)
  (write-string content (standard-out-stream stream-io))
  (force-output (standard-out-stream stream-io))
  (values))

(defclass mock-stream-io (abstract-stream-io)
  ((input-source
    :initarg :input-source
    :accessor mock-input-source)
   (output-sink
    :initform (make-string-output-stream)
    :reader mock-output-sink)
   (interactive-p
    :initarg :interactive-p
    :initform nil
    :accessor mock-interactive-p))
  (:documentation "Classe de fluxo simulada nomeada para testes sem tocar na E/S do terminal."))

(declaim (ftype (function (&optional string boolean) mock-stream-io) make-mock-stream-io))
(defun make-mock-stream-io (&optional (initial-input "") (interactive-p nil))
  "Constrói um objeto simulado de E/S pré-carregado com INITIAL-INPUT e flag interativa.
Exemplo: (make-mock-stream-io \"{\\\"x\\\": 1}\")"
  (check-type initial-input string)
  (check-type interactive-p boolean)
  (make-instance 'mock-stream-io
                 :input-source (make-string-input-stream initial-input)
                 :interactive-p interactive-p))

(defmethod input-stream-interactive-p ((stream-io mock-stream-io))
  "Retorna a flag de interatividade simulada configurada para o mock.
Exemplo: (input-stream-interactive-p fake-io)"
  (mock-interactive-p stream-io))

(defmethod read-entire-stream ((stream-io mock-stream-io))
  "Lê todo o texto remanescente do fluxo de entrada simulado.
Exemplo: (read-entire-stream fake-io)"
  (with-output-to-string (sink)
    (loop for ch = (read-char (mock-input-source stream-io) nil nil)
          while ch do (write-char ch sink))))

(defmethod write-output-string ((stream-io mock-stream-io) content)
  "Captura a string CONTENT no coletor de saída em memória.
Exemplo: (write-output-string fake-io \"json-minificado\")"
  (check-type content string)
  (write-string content (mock-output-sink stream-io))
  (values))

(declaim (ftype (function (mock-stream-io) string) fetch-emitted-output))
(defun fetch-emitted-output (stream-io)
  "Extrai todo o texto escrito até o momento no coletor de saída simulado.
Exemplo: (fetch-emitted-output fake-io) => \"{\\\"a\\\":1}\""
  (check-type stream-io mock-stream-io)
  (get-output-stream-string (mock-output-sink stream-io)))
