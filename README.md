# Introdução
Este plugin permite o planejamento e navegação de arquivos de forma independente da forma com que o Vim/Neovim organiza os arquivos.

Seu uso é feito baseando-se na manipulação da meta-informação contida em todo projeto de software, seja ele grande ou pequeno. Meta-informação é toda informação que descreve outra informação, sendo esta última o projeto em si. 

Considere o exemplo onde se quer mapear o seguinte projeto C, hipoteticamente localizado em `~/Projetos/libc`:

```console
$tree ~/Projetos/libc
.
├── bin
│   ├── install.sh
│   └── uninstall.sh
├── doc
│   ├── module-01.txt
│   └── module-02.txt
├── Makefile
├── readme.txt
├── src
│   ├── common.h
│   ├── main.c
│   ├── module-01.c
│   ├── module-01.h
│   ├── module-02.c
│   └── module-02.h
└── test
    ├── module-01.c
    ├── module-01.h
    ├── module-02.c
    └── module-02.h
```

Tanto o Vim quanto o Neovim (e editores de texto em geral) organizam os arquivos sendo abertos em uma lista circular, geralmente apresentados em abas separadas cujo o nome de cada aba faz alguma referência ao arquivo em questão. Algo como:

```text
|file-01.txt|file-02.txt|file-03.txt|...|last-file.txt|
```

o problema dessa abordagem quando estamos lidando com um projeto grande, é que fica difícil de mapear todos eles ao mesmo tempo pelos seguintes motivos:

1) Categorias diferentes: código fonte, scripts, documentação, etc
2) Hieraquias diferentes: pastas e sub-pastas
3) Curta memória humana : Não conseguimos lembrar muitas  posições na lista
4) Consome a largura da tela

Em outras palavras, ao organizar os arquivos desta forma, apenas 1 (um) grau de liberdade está sendo usado ao apresentá-los na tela.

Portanto, a proposta do NVPM é a de aumentar o número de graus de liberdade.

# Como usar o NVPM

O uso do NVPM consiste das seguintes etapas:

1) Criar um ou mais arquivos de projetos
2) Carregar um arquivo de projeto
3) Acionar um comando do NVPM

### Arquivos descritor projetos
Cada projeto pode ter um ou mais arquivos de projetos. Estes, por sua vez ficam localizados, por padrão, no diretório `.nvpm/proj/`. Um arquivo de projeto pode ter qualquer nome e qualquer extensão. Se por exemplo, o caminho de um de seus projetos for `~/Projetos/libc`, então o diretório `~/Projetos/libc/.nvpm/proj` deverá ser criado. Em outras palavras, cada projeto deverá ter o diretório `.nvpm/proj/` a partir de sua raíz.

Considerando o projeto em C descrito na introdução, poderíamos criar um arquivo de projeto de nome `libc-code`, que por sua vez deve estar localizado em `~/Projetos/libc/.nvpm/proj/libc-code`.

### Sintaxe dos arquivos de projetos
A síntaxe para escrever os arquivos de projeto é bastante simples, contando com 4 (quatro) palavras reservadas, sendo elas: "workspace", "tab", "buff" e "term"

* Palavra "workspace" : 

  workspace \<nome-do-workspace\>

* Palavra "tab" : 

  tab \<nome-da-aba\>

* Palavra "buff" : 

  buff \<nome-do-buffer\> : caminho/até/o/arquivo

* Palavra "term" : 

  term \<nome-do-terminal\> : \<commando-a-ser-executado\>

Algumas ressalvas:

1) cada instrução é dada em uma única linha
2) cada instrução pode ter espaços antes, depois e entre palavras
3) os nomes das coisas podem ter quaisquer caracteres
4) se quiseres criar um terminal sem comandos, crie-o da seguinte forma: "term \<nome-do-terminal\> :". Perceba que deve conter o ":"
5) NVPM ainda não conta com checadores de erros. Se você errar a síntaxe, provavelmente terás que fechar e reabrir o editor. Porém garanto que nenhuma operação de deleção ou sobreescrita de arquivos são aplicadas.

A seguir temos um possível exemplo para o conteúdo do arquivo `~/Projetos/libc/.nvpm/proj/libc-code`.

```text
workspace Code

  tab Main
    buff Main     : src/main.c
    buff Common   : src/common.c
    buff Makefile : Makefile
    term Terminal : bash

  tab Module-01
    buff  Source : src/module-01.c
    buff  Header : src/module-01.h
    buff TSource : test/module-01.c
    buff THeader : test/module-01.h

  tab Module-02
    buff  Source : src/module-02.c
    buff  Header : src/module-02.h
    buff TSource : test/module-02.c
    buff THeader : test/module-02.h

workspace Meta

  tab Scripts
    buff   Install : bin/install.sh
    buff UnInstall : bin/uninstall.sh

  tab Documentations
    buff README    : README.md
    buff Module-01 : doc/module-01.txt
    buff Module-02 : doc/module-02.txt
```

que produzirá os resultado 

![libc-code-(Workspace Code)](.img/my-proj-1.png)

![libc-code-(Workspace Meta)](.img/my-proj-2.png)

Desta forma, o usuário será apresentado com as informações escritas no arquivos de projetos, porém em vez de eles serem apresentados de forma linear, o usuário terá a visão deles em 3 (três) graus de liberdade, por cada arquivo de projeto escrito, de forma que os arquivos ficarão dispostos em forma de árvore, onde cada galho representa uma hierarquia.

[comment]: imagem-da-árvore

### Desativador de subestruturas
Para desativar uma subestrutura, podemos usar o operador "\*" (asterísco) na frente da palavra reservada. O efeito disso é que a estrutura após "\*", bem como as subestruturas daquela hierarquia não serão considerados ao carregar o arquivo de projeto. Pense nesta ação como uma forma de podar a árvore momentâneamente. No nosso exemplo:

```text
workspace Code

  tab Main
    buff Main     : src/main.c
    buff Common   : src/common.c
*   buff Makefile : Makefile
*   term Terminal : bash

  tab Module-01
    buff  Source : src/module-01.c
    buff  Header : src/module-01.h
    buff TSource : test/module-01.c
    buff THeader : test/module-01.h

* tab Module-02
    buff  Source : src/module-02.c
    buff  Header : src/module-02.h
    buff TSource : test/module-02.c
    buff THeader : test/module-02.h

* workspace Meta

  tab Scripts
    buff   Install : bin/install.sh
    buff UnInstall : bin/uninstall.sh

  tab Documentations
    buff README    : README.md
    buff Module-01 : doc/module-01.txt
    buff Module-02 : doc/module-02.txt
```

que por sua vez produzirá o seguinte:

![My Project](.img/my-proj-3.png)

No caso, as estruturas de nome:

1) Makefile  (buff)
2) Terminal  (term)
3) Module-01 (tab)
4) Meta (workspace)

foram desconectadas, ou podadas, ou ainda não carregadas.

# Comandos 
As funcionalidades do NVPM são acessadas pelos seguintes comandos: 

```text
:NVPMLoadProject
:NVPMSaveDefault
:NVPMEditProjects
:NVPMTerminal
:NVPMNext
:NVPMPrev
```

Ou seja, em modo normal entre no modo de comando do Vim/Neovim aperdando **":"** e entre com um dos comandos acima.

## Comando _:NVPMLoadProject_

### Argumentos: 
_Apenas 1 (um) e obrigatório. Completável com tab, que lista os arquivos dentro de `/path/to/project/.nvpm/proj/`_

### Síntaxe: 
`:NVPMLoadProject <nome-do-arquivo-de-projeto>`

### Ação : 
_Carrega um arquivo descritor de projeto localizado em `/path/to/project/.nvpm/proj/<nome-do-arquivo-de-projeto>`_

[comment]: --------

## Comando _:NVPMSaveDefaultProject_

### Argumentos: 
_Apenas 1 (um) e opcional. Completável com tab, que lista os arquivos dentro de `/path/to/project/.nvpm/proj/`._

_Se nenhum nome de arquivo de projeto for escolhido, NVPM salvará o projeto carregado no momento._

### Síntaxe: 
`:NVPMSaveDefaultProject <nome-do-arquivo-de-projeto>`

### Ação : 
_Salva um arquivo descritor de projeto localizado em `/path/to/project/.nvpm/proj/<nome-do-arquivo-de-projeto>` como projeto padrão a ser carregado ao iniciar o Vim/Neovim de dentro do diretório `/path/to/proj/`_

[comment]: --------

## Comando _:NVPMEditProjects_
OBS: Funciona apenas no Neovim por enquanto.

### Argumentos: 
_0 (zero/nenhum)_ 

### Síntaxe: 
`:NVPMEditProjects <enter>`

### Ação : 
_Abre um workspace temporário para a edição dos arquivos de projetos presentes. Também cria um terminal em outra aba que permite o usuário fazer manipulações em seu projeto, compatíveis com as mudanças a serem feitas neste modo._

_Se o arquivo de projeto que corresponde ao projeto carregado por `:NVPMLoadProject` for alterado, NVPM aplicará as devidas mudanças e recarregará o mesmo arquivo de projeto._

_Um "\* (asterísco)" será colocado na frente do nome do arquivo carregado._

[comment]: --------

## Comando _:NVPMTerminal_

### Argumentos: 
_0 (zero/nenhum)_ 

### Síntaxe: 
`:NVPMTerminal <enter>`

### Ação : 
_Abre um terminal coringa que pode ser lançado de qualquer lugar e em qualquer momento._

[comment]: --------

## Comando _:NVPMNext_

### Argumentos: 
_Apenas 1 (um) e obrigatório. Completável com tab, que lista dentre as 3 (três) possíveis estruturas iteráveis da árvore, sendo elas: "workspace", "tab" ou "buffer". Terminais também são considerados como buffers neste caso_

### Síntaxe: 
`:NVPMNext <workspace-tab-buffer>`

### Ação : 
_Avança um elemento de mesma hierarquia na árvore do NVPM._

[comment]: --------

## Comando _:NVPMPrev_

### Argumentos: 
_Apenas 1 (um) e obrigatório. Completável com tab, que lista dentre as 3 (três) possíveis estruturas iteráveis da árvore, sendo elas: "workspace", "tab" ou "buffer". Terminais também são considerados como buffers neste caso._

### Síntaxe: 
`:NVPMPrev <workspace-tab-buffer>`

### Ação : 
_Retorna um elemento de mesma hierarquia na árvore do NVPM._

# Mapeamento de teclas (Mappings)

Nenhum mapeamento de tecla é feito por padrão. Porém eu sugiro o uso das seguintes teclas:

```text
 <espaco>: próximo buffer
m<espaco>: buffer anterior

 <tab>: próxima aba
m<tab>: aba anterior

 <ctrl-n>: próximo workspace
m<ctrl-p>: workspace anterior

mt : abre terminal coringa

<F9>  : salva projeto padrão
<F10> : Carrega novo projeto
<F12> : Entra em modo de edição de projeto
```

Atualmente os meus mapeamentos são o seguinte:

```vim
  nmap  <space> :NVPMNext buffer<cr>
  nmap m<space> :NVPMPrev buffer<cr>
  nmap  <tab>   :NVPMNext tab<cr>
  nmap m<tab>   :NVPMPrev tab<cr>
  nmap <c-n>    :NVPMNext workspace<cr>
  nmap <c-b>    :NVPMPrev workspace<cr>
  nmap mt       :NVPMTerminal<cr>
  nmap <F9>     :NVPMSaveDefaultProject<space>
  nmap <F10>    :NVPMLoadProject<space>
  nmap <F12>    :NVPMEditProjects<cr>
  nmap <F8>     :NVPMDevTest<cr>
```

# Algumas observações

## set hidden
Se esta opção não estiver setada, um erro ocorrerá quando tentares passar de um buffer para outro caso o atual esteja modificado. Isso não é um bug, pois o Vim/Neovim foi construido dessa forma (ver `:help hidden`). Ao mudar de buffer você não perde as alterações feitas no buffer anterior. 

Então a opção a seguir deve estar no seu vimrc ou init.vim.

```vim
  set hidden
```

## showtabline=2
Esta opção deixa a barra de abas (tabline) sempre visível. Futuras versões vão eliminar a necessidade do usuário ter esta opção setada de forma global.

```vim
  set showtabline=2
```

## g:nvpm_load_default (zero ou outro)
Esta opção desativa a função de carregar projetos por padrão quando setada com `0 (zero)`. O seu valor padrão é `1 (um).`

```vim
  let g:nvpm_load_default = 1
```

## g:nvpm_local_dir (String)

Esta variável guarda o nome do subdiretório do NVPM dentro de cada projeto. Seu valor padrão é `'.nvpm'`
  
```vim
  let g:nvpm_local_dir = '.nvpm'
```
