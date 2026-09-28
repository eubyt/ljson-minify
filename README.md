# ljson-minify

Ferramenta CLI para minificação (**minify**) e formatação / indentação (**unminify** / pretty-print) de JSON escrita em Common Lisp (SBCL).

## Visão Geral

O `ljson` fornece operações de minificação e formatação JSON em estrita conformidade com a especificação RFC 8259. Foi desenvolvido com zero dependências externas de terceiros, tipagem explícita estática e dinâmica, adaptadores de E/S desacoplados com classes simuladas (_named fake classes_) para testes determinísticos, e emissão de logs estruturados em JSON para observabilidade e depuração.

## Requisitos e Ambiente

- **Common Lisp**: SBCL 2.6.8
- **Sistema de Módulos**: ASDF 3.3+ (embutido nativamente no SBCL)
- **Make** / **Bash**

## Início Rápido

### 1. Utilização da CLI

A ferramenta pode ser executada através do `make run`

```bash
# Exibir o manual de ajuda
make run
# ou: make run ARGS="--help" (ou ./scripts/ljson --help)

# Minificar JSON a partir da entrada padrão (stdin)
echo '{ "nome": "Lisp", "tags": [ "json", "cli" ] }' | make run

# Minificar um arquivo e gravar o resultado em outro arquivo
make run ARGS="minify -i entrada.json -o saida.min.json"

# Se nenhum subcomando for passado, 'minify' é o padrão
make run ARGS="entrada.json"

# Desminificar / Formatar (unminify) com indentação padrão de 2 espaços
cat saida.min.json | make run ARGS="unminify"

# Desminificar com indentação customizada (4 espaços)
make run ARGS="unminify -s 4 -i saida.min.json"

# Executar com logs estruturados em JSON direcionados ao stderr
make run ARGS="minify --verbose -i entrada.json"
```

### 2. Execução dos Testes

A suíte de testes unitários e de integração pode ser executada com um único comando:

```bash
make test
# ou
./scripts/run-tests
```

### 3. Compilar em Binário Nativo (Standalone)

Para gerar um binário executável autônomo de máquina (que roda instantaneamente sem carregar o runtime do SBCL):

```bash
make build
```

O executável compilado será gerado em `bin/ljson-bin` e pode ser usado diretamente:

```bash
./bin/ljson-bin minify -i entrada.json
```
