(in-package #:ljson/tests/unminifier)

(declaim (ftype (function () (values)) test-unminifier-basic-object))
(defun test-unminifier-basic-object ()
  "Verifica a formatação padrão com 2 espaços de um objeto plano.
Exemplo: (test-unminifier-basic-object)"
  (let* ((input "{\"id\":101,\"valido\":true}")
         (expected (format nil "{~%  \"id\": 101,~%  \"valido\": true~%}"))
         (actual (unminify-json-string input 2)))
    (assert-equal expected actual "Objeto básico formatado com 2 espaços"))
  (values))

(declaim (ftype (function () (values)) test-unminifier-nested-structures))
(defun test-unminifier-nested-structures ()
  "Verifica a indentação recursiva através de objetos e arrays aninhados.
Exemplo: (test-unminifier-nested-structures)"
  (let* ((input "{\"lista\":[1,{\"aninhado\":false}]}")
         (expected (format nil "{~%  \"lista\": [~%    1,~%    {~%      \"aninhado\": false~%    }~%  ]~%}"))
         (actual (unminify-json-string input 2)))
    (assert-equal expected actual "Containers aninhados indentados corretamente"))
  (values))

(declaim (ftype (function () (values)) test-unminifier-custom-indent-width))
(defun test-unminifier-custom-indent-width ()
  "Verifica a formatação com passo de indentação customizado de 4 espaços.
Exemplo: (test-unminifier-custom-indent-width)"
  (let* ((input "{\"chave\":\"valor\"}")
         (expected (format nil "{~%    \"chave\": \"valor\"~%}"))
         (actual (unminify-json-string input 4)))
    (assert-equal expected actual "Indentação customizada de 4 espaços aplicada"))
  (values))

(declaim (ftype (function () (values)) test-unminifier-empty-containers))
(defun test-unminifier-empty-containers ()
  "Verifica que objetos e arrays vazios permanecem compactos {} e [].
Exemplo: (test-unminifier-empty-containers)"
  (let* ((input "{\"obj_vazio\":{},\"arr_vazio\":[]}")
         (expected (format nil "{~%  \"obj_vazio\": {},~%  \"arr_vazio\": []~%}"))
         (actual (unminify-json-string input 2)))
    (assert-equal expected actual "Containers vazios formatados compactamente"))
  (values))

(declaim (ftype (function () (values)) test-unminifier-mismatched-brackets-error))
(defun test-unminifier-mismatched-brackets-error ()
  "Verifica que fechamento incorreto de chaves ou colchetes sinaliza erro.
Exemplo: (test-unminifier-mismatched-brackets-error)"
  (assert-signals-condition
   'json-syntax-error
   (lambda () (unminify-json-string "{\"chave\": 1 ]"))
   "Incompatibilidade entre chave e colchete sinaliza erro de sintaxe")
  (assert-signals-condition
   'json-syntax-error
   (lambda () (unminify-json-string "{\"aberto\": 1"))
   "Estrutura não fechada sinaliza erro de sintaxe")
  (values))

(declaim (ftype (function () (values)) register-unminifier-tests))
(defun register-unminifier-tests ()
  "Registra todos os testes unitários do unminifier no framework de teste.
Exemplo: (register-unminifier-tests)"
  (define-test-case "unminifier-basic-object" :unminifier
    (test-unminifier-basic-object))
  (define-test-case "unminifier-nested-structures" :unminifier
    (test-unminifier-nested-structures))
  (define-test-case "unminifier-custom-indent-width" :unminifier
    (test-unminifier-custom-indent-width))
  (define-test-case "unminifier-empty-containers" :unminifier
    (test-unminifier-empty-containers))
  (define-test-case "unminifier-mismatched-brackets-error" :unminifier
    (test-unminifier-mismatched-brackets-error))
  (values))
