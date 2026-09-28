(in-package #:ljson/cli)

(deftype cli-action-mode ()
  '(member :minify :unminify))

(defstruct (cli-invocation-config
            (:constructor %make-cli-invocation-config)
            (:conc-name config-))
  (action-mode :minify :type cli-action-mode)
  (input-filepath nil :type (or string null))
  (output-filepath nil :type (or string null))
  (indent-width 2 :type fixnum)
  (verbosity-enabled nil :type boolean)
  (help-requested nil :type boolean))

(declaim (ftype (function (&key (:action-mode cli-action-mode)
                                (:input-filepath (or string null))
                                (:output-filepath (or string null))
                                (:indent-width fixnum)
                                (:verbosity-enabled boolean)
                                (:help-requested boolean))
                          cli-invocation-config)
                make-cli-invocation-config))
(defun make-cli-invocation-config (&key (action-mode :minify) input-filepath output-filepath
                                     (indent-width 2) verbosity-enabled help-requested)
  "Fábrica que cria registro de configuração de invocação da CLI.
Exemplo: (make-cli-invocation-config :action-mode :unminify)"
  (%make-cli-invocation-config :action-mode action-mode
                               :input-filepath input-filepath
                               :output-filepath output-filepath
                               :indent-width indent-width
                               :verbosity-enabled verbosity-enabled
                               :help-requested help-requested))

(declaim (ftype (function () string) render-cli-usage-text))
(defun render-cli-usage-text ()
  "Produz o manual de ajuda em texto puro da CLI para o usuário.
Exemplo: (render-cli-usage-text)"
  (format nil "~
Uso: ljson [minify|unminify] [opções] [arquivo]

Comandos:
  minify            Minifica a entrada JSON (padrão)
  unminify          Formata e indenta a entrada JSON

Opções:
  -i, --input PATH  Lê JSON a partir do caminho do arquivo (padrão: stdin)
  -o, --output PATH Escreve a saída no caminho do arquivo (padrão: stdout)
  -s, --spaces NUM  Espaços de indentação para o unminify (padrão: 2)
  -v, --verbose     Emite eventos de depuração em JSON estruturado no stderr
  -h, --help        Exibe este guia de ajuda
"))

(declaim (ftype (function (string) fixnum) parse-indent-number))
(defun parse-indent-number (raw-arg)
  "Analisa e valida largura de indentação positiva entre 0 e 16.
Exemplo: (parse-indent-number \"4\") => 4"
  (let ((parsed (parse-integer raw-arg :junk-allowed t)))
    (unless (and parsed (>= parsed 0) (<= parsed 16))
      (signal-argument-violation raw-arg "número inteiro entre 0 e 16 para indentação"))
    parsed))

(declaim (ftype (function (string cli-invocation-config) boolean) apply-subcommand-arg))
(defun apply-subcommand-arg (arg config)
  "Verifica se ARG é um subcomando conhecido e atualiza CONFIG.
Exemplo: (apply-subcommand-arg \"unminify\" cfg) => T"
  (cond
    ((or (string= arg "minify") (string= arg "-m"))
     (setf (config-action-mode config) :minify) t)
    ((or (string= arg "unminify") (string= arg "-u"))
     (setf (config-action-mode config) :unminify) t)
    (t nil)))

(declaim (ftype (function (string cli-invocation-config) boolean) apply-boolean-flag))
(defun apply-boolean-flag (arg config)
  "Verifica se ARG é uma flag booleana como --help ou --verbose.
Exemplo: (apply-boolean-flag \"--help\" cfg) => T"
  (cond
    ((or (string= arg "-h") (string= arg "--help"))
     (setf (config-help-requested config) t) t)
    ((or (string= arg "-v") (string= arg "--verbose"))
     (setf (config-verbosity-enabled config) t) t)
    (t nil)))

(declaim (ftype (function (string string cli-invocation-config) (values)) apply-flag-with-value))
(defun apply-flag-with-value (flag value config)
  "Atribui valor parametrizado ao campo correspondente de CONFIG.
Exemplo: (apply-flag-with-value \"-s\" \"4\" cfg)"
  (cond
    ((or (string= flag "-i") (string= flag "--input"))
     (setf (config-input-filepath config) value))
    ((or (string= flag "-o") (string= flag "--output"))
     (setf (config-output-filepath config) value))
    ((or (string= flag "-s") (string= flag "--spaces"))
     (setf (config-indent-width config) (parse-indent-number value)))
    (t (signal-argument-violation flag "uma das opções: -i, --input, -o, --output, -s, --spaces")))
  (values))

(declaim (ftype (function (list cli-invocation-config) list) parse-single-step))
(defun parse-single-step (remaining config)
  "Processa o argumento atual da cabeça e retorna o restante da lista.
Exemplo: (parse-single-step '(\"-v\") cfg)"
  (let ((head (first remaining)))
    (cond
      ((apply-boolean-flag head config) (cdr remaining))
      ((apply-subcommand-arg head config) (cdr remaining))
      ((member head '("-i" "--input" "-o" "--output" "-s" "--spaces") :test #'string=)
       (unless (second remaining)
         (signal-argument-violation head "argumento com valor após a opção"))
       (apply-flag-with-value head (second remaining) config)
       (cddr remaining))
      ((char= (char head 0) #\-) (signal-argument-violation head "opção de CLI reconhecida"))
      ((null (config-input-filepath config))
       (setf (config-input-filepath config) head)
       (cdr remaining))
      (t (signal-argument-violation head "argumento único de arquivo de entrada")))))

(declaim (ftype (function (list) cli-invocation-config) parse-cli-arguments))
(defun parse-cli-arguments (arg-list)
  "Analisa uma lista de argumentos da CLI em uma configuração validada.
Exemplo: (parse-cli-arguments '(\"minify\" \"-i\" \"arquivo.json\"))"
  (let ((config (make-cli-invocation-config))
        (remaining arg-list))
    (loop while remaining do
      (setf remaining (parse-single-step remaining config)))
    config))

(declaim (ftype (function (cli-invocation-config abstract-filesystem abstract-stream-io json-log-sink) string)
                read-source-payload))
(defun read-source-payload (config filesystem stream-io logger)
  "Lê o conteúdo JSON de entrada de arquivo ou fluxo conforme CONFIG.
Exemplo: (read-source-payload cfg fs io log)"
  (let ((path (config-input-filepath config)))
    (if path
        (progn
          (emit-structured-log logger "INFO" "cli" (format nil "Lendo arquivo: ~A" path))
          (read-file-content filesystem path))
        (progn
          (emit-structured-log logger "INFO" "cli" "Lendo fluxo de entrada padrão (stdin)")
          (read-entire-stream stream-io)))))

(declaim (ftype (function (cli-invocation-config string abstract-filesystem abstract-stream-io json-log-sink) (values))
                write-target-payload))
(defun write-target-payload (config result-text filesystem stream-io logger)
  "Emite o RESULT-TEXT processado para arquivo ou fluxo padrão de saída.
Exemplo: (write-target-payload cfg \"{}\" fs io log)"
  (let ((path (config-output-filepath config)))
    (if path
        (progn
          (emit-structured-log logger "INFO" "cli" (format nil "Escrevendo arquivo: ~A" path))
          (write-file-content filesystem path result-text))
        (progn
          (emit-structured-log logger "INFO" "cli" "Escrevendo no fluxo de saída padrão (stdout)")
          (write-output-string stream-io result-text)
          (write-output-string stream-io (string #\Newline)))))
  (values))

(declaim (ftype (function (cli-invocation-config string json-log-sink) string) transform-json-payload))
(defun transform-json-payload (config payload-text logger)
  "Transforma PAYLOAD-TEXT usando minifier ou unminifier conforme o modo.
Exemplo: (transform-json-payload cfg \"{}\" log)"
  (case (config-action-mode config)
    (:minify
     (emit-structured-log logger "DEBUG" "minifier" "Executando transformação de minificação")
     (minify-json-string payload-text))
    (:unminify
     (let ((spaces (config-indent-width config)))
       (emit-structured-log logger "DEBUG" "unminifier" (format nil "Desminificando com ~D espaços" spaces))
       (unminify-json-string payload-text spaces)))))

(declaim (ftype (function (cli-invocation-config abstract-filesystem abstract-stream-io json-log-sink) fixnum)
                execute-cli-action))
(defun execute-cli-action (config filesystem stream-io logger)
  "Executa a operação JSON solicitada com dependências de E/S e log injetadas.
Exemplo: (execute-cli-action cfg fs io log) => 0"
  (when (or (config-help-requested config)
            (and (null (config-input-filepath config))
                 (input-stream-interactive-p stream-io)))
    (write-output-string stream-io (render-cli-usage-text))
    (return-from execute-cli-action 0))
  (let* ((input-raw (read-source-payload config filesystem stream-io logger))
         (transformed (transform-json-payload config input-raw logger)))
    (write-target-payload config transformed filesystem stream-io logger)
    0))
