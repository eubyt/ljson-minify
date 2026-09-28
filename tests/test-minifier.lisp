(in-package #:ljson/tests/minifier)

(declaim (ftype (function () (values)) test-minifier-basic-json-objects))
(defun test-minifier-basic-json-objects ()
  "Verifica se a minificação remove espaços entre chaves, valores e delimitadores.
Exemplo: (test-minifier-basic-json-objects)"
  (let* ((input "{ \"nome\" : \"Alice\" , \"idade\" : 30 , \"ativo\" : true }")
         (expected "{\"nome\":\"Alice\",\"idade\":30,\"ativo\":true}")
         (actual (minify-json-string input)))
    (assert-equal expected actual "Objeto minificado corresponde ao formato esperado"))
  (values))

(declaim (ftype (function () (values)) test-minifier-preserves-whitespace-inside-strings))
(defun test-minifier-preserves-whitespace-inside-strings ()
  "Garante que espaços em branco dentro de strings nunca sejam removidos.
Exemplo: (test-minifier-preserves-whitespace-inside-strings)"
  (let* ((input "  {  \"saudacao\"  :  \"ola   mundo \\t\\n em lisp\"  }  ")
         (expected "{\"saudacao\":\"ola   mundo \\t\\n em lisp\"}")
         (actual (minify-json-string input)))
    (assert-equal expected actual "Espaços internos da string preservados intactos"))
  (values))

(declaim (ftype (function () (values)) test-minifier-nested-structures))
(defun test-minifier-nested-structures ()
  "Verifica se arrays e objetos aninhados são minificados em string compacta.
Exemplo: (test-minifier-nested-structures)"
  (let* ((input "[ { \"itens\" : [ 1 , 2 , { \"aninhado\" : null } ] } ]")
         (expected "[{\"itens\":[1,2,{\"aninhado\":null}]}]")
         (actual (minify-json-string input)))
    (assert-equal expected actual "Estrutura aninhada minificada corretamente"))
  (values))

(declaim (ftype (function () (values)) test-minifier-empty-input-error))
(defun test-minifier-empty-input-error ()
  "Verifica que entrada vazia ou em branco sinaliza erro de sintaxe.
Exemplo: (test-minifier-empty-input-error)"
  (assert-signals-condition
   'json-syntax-error
   (lambda () (minify-json-string "    "))
   "Entrada vazia sinaliza erro de sintaxe")
  (values))

(declaim (ftype (function () (values)) register-minifier-tests))
(defun register-minifier-tests ()
  "Registra todos os testes unitários do minificador no framework de teste.
Exemplo: (register-minifier-tests)"
  (define-test-case "minifier-basic-json-objects" :minifier
    (test-minifier-basic-json-objects))
  (define-test-case "minifier-preserves-whitespace-inside-strings" :minifier
    (test-minifier-preserves-whitespace-inside-strings))
  (define-test-case "minifier-nested-structures" :minifier
    (test-minifier-nested-structures))
  (define-test-case "minifier-empty-input-error" :minifier
    (test-minifier-empty-input-error))
  (values))
