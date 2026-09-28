(in-package #:ljson/main)

(declaim (ftype (function (condition) (values)) report-cli-error-plain-text))
(defun report-cli-error-plain-text (condition-instance)
  "Emite um relatório de erro em texto puro no erro padrão para usuários da CLI.
Exemplo: (report-cli-error-plain-text c)"
  (format *error-output* "ljson: ~A~%" condition-instance)
  (force-output *error-output*)
  (values))

(declaim (ftype (function (list) fixnum) run-cli-application))
(defun run-cli-application (raw-argument-list)
  "Conecta dependências concretas do sistema e executa o ciclo de vida da CLI.
Exemplo: (run-cli-application '(\"minify\" \"teste.json\")) => 0"
  (handler-case
      (let* ((config (parse-cli-arguments raw-argument-list))
             (logger (make-json-log-sink :verbosity-enabled-p
                                         (config-verbosity-enabled config)))
             (filesystem (make-system-filesystem))
             (stream-io (make-standard-stream-io)))
        (execute-cli-action config filesystem stream-io logger))
    (error (err)
      (report-cli-error-plain-text err)
      1)))

(declaim (ftype (function () list) extract-shell-arguments))
(defun extract-shell-arguments ()
  "Extrai argumentos de linha de comando do usuário excluindo opções do runtime.
Exemplo: (extract-shell-arguments)"
  (let ((dash-marker (member "--" sb-ext:*posix-argv* :test #'string=)))
    (if dash-marker
        (rest dash-marker)
        (rest sb-ext:*posix-argv*))))

(declaim (ftype (function () nil) cli-main))
(defun cli-main ()
  "Ponto de entrada do processo invocado por scripts e binários compilados.
Exemplo: (cli-main)"
  (let* ((raw-arguments (extract-shell-arguments))
         (exit-status (run-cli-application raw-arguments)))
    (sb-ext:exit :code exit-status)))
