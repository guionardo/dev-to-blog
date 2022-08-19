# Creating animated gifs from your terminal

Post created at 2022-08-19 08:36

I need to generate some videos to demonstrate console applications running.

![gif](dancing-duck-acegifcom-72.gif)

[source](https://acegif.com/wp-content/uploads/2022/4hv9xm/dancing-duck-acegifcom-72.gif)

Screen casting or capture is boring, and generates large files. 

Then, I found two command line tools that do the job.

First, we need to capture the console interation, and this is done using the Terminal Session Recorder [asciinema](https://asciinema.org/). Installation instructions can be found [here](https://asciinema.org/docs/installation).

I'm using Ubuntu, so the installation was easy-peasy. 

```bash
❯ sudo apt install asciinema
[sudo] senha para guionardo: 
A ler as listas de pacotes... Pronto
A construir árvore de dependências       
A ler a informação de estado... Pronto
Serão instalados os seguintes NOVOS pacotes:
  asciinema
0 pacotes actualizados, 1 pacotes novos instalados, 0 a remover e 0 não actualizados.
É necessário obter 35,0 kB de arquivos.
Após esta operação, serão utilizados 125 kB adicionais de espaço em disco.
Obter:1 http://br.archive.ubuntu.com/ubuntu focal/universe amd64 asciinema all 2.0.2-1 [35,0 kB]
Obtidos 35,0 kB em 7s (4.877 B/s)    
A seleccionar pacote anteriormente não seleccionado asciinema.
(A ler a base de dados ... 435184 ficheiros e directórios actualmente instalados.)
A preparar para desempacotar .../asciinema_2.0.2-1_all.deb ...
A descompactar asciinema (2.0.2-1) ...
A instalar asciinema (2.0.2-1) ...
A processar 'triggers' para man-db (2.9.1-1) ...
```

For our first test, we can command:

```bash
❯ asciinema rec first.cast
asciinema: recording asciicast to first.cast
asciinema: press <ctrl-d> or type "exit" when you're done
```

After that, you can run your commands normally and all your key strokes and console outputs will be recorded into the *first.cast* file.

To finish the capture press *CTRL+D* or type *exit*.  Check the [official usage documentation](https://asciinema.org/docs/usage) for more options.

Now, we need to generate the animated gif file. The tool to this job is the might [agg - asciinema gif generator](https://github.com/asciinema/agg).

It's a [rust](https://www.rust-lang.org/) application, and you can clone the repository and build it, or you can download an binary to your environment surfing to the [latest release link](https://github.com/asciinema/agg/releases/latest). Download the correct version to your system, put the executable in some directory you can reach and execute.

Check if the installation is OK.

```bash
❯ agg --version
agg 1.1.0
```

If your shell has some fancy unicode characters (like mine), you can reference a TTF font to render the gif.
I like "JetBrains Mono", and you can download it from [here](https://www.jetbrains.com/lp/mono/), or if you like another dev font, you can use.

In my case, I saved the TTF files into a folder to use in next step.

Generate a gif from the _first.cast_ file created .

```bash
❯ ./agg --font-dir ./fonts --font-family "agave Nerd Font" first.cast first.gif
31 / 31 [=================================================================] 100.00 % 47.71/s 
```

And now, we have our _first.gif_ file in current folder.

![first](first.gif)


