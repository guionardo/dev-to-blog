# Segredos

O gerenciamento de senhas pode ser complicado quando temos vários serviços (e-mail, redes sociais, github, API´s, certificados digitais, orkut :-) , etc).

A regra é usar senhas complexas, *pass phrases*, cuidando pra não incluir dados pessoais, como aniversário, apelidos, nomes de conhecidos, etc que possam ser "adivinhados" por engenharia social.

E quando você cria sua senha super exclusiva e segura, encontra sistemas que expiram as senhas periodicamente e impedem que a reutilize.

Então, em nosso socorro, existem ferramentas para criar, gerenciar senhas, como o [KeepassXC](https://keepassxc.org/). Além de armazenar usuários e senhas, a ferramenta permite documentar e adicionar arquivos, como exemplos de requests/responses de API, arquivos de chaves, certificados digitais, etc. O KeepassXC armazena todas essas informações em um arquivo local criptografado (database .kdbx).

Existem outros, mas esse é um que eu gosto de usar e me atende muito bem. KeepassXC é open-source, roda em Windows, Linux, e Mac. É facilmente instalado. Siga o link acima e sucesso!

![Alt Text](https://dev-to-uploads.s3.amazonaws.com/i/y3aym8qsc2dgny6d1ejg.png)

Ok, já resolvi o meu problema com muitas informações de autenticação e esbarrei em outro: Quando eu uso em mais de uma máquina, preciso me preocupar com a distribuição e sincronização do meu database por todas as minhas máquinas.

[Dropbox](https://dropbox.com), [Google Drive](https://drive.google.com), [OneDrive](https://onedrive.live.com) poderiam ser uma opção, mas eu gostaria de algo mais hipster. Brincadeira. Se estamos falando em segurança de informação, dá pra confiar nos grandes players? Talvez.

Aí, encontrei o [Keybase](https://keybase.io), que, entre outras coisas, permite um sistema de [arquivos](https://keybase.io/docs/kbfs) em nuvem e [criptografado](https://keybase.io/docs/crypto/kbfs).

![Alt Text](https://dev-to-uploads.s3.amazonaws.com/i/hkvk3yrg6o68vru1qjxe.png)

Então, vamos por mãos à obra.

## Instalação

Acesse o site do [Keybase](https://keybase.io/download), escolha seu ambiente (macOS, Windows ou Linux), faça o download e instale normalmente. Siga as instruções de instalação e depois crie seu usuário com uma senha segura ;-)

Depois do keybase devidamente instalado, acesse as opções de arquivo:

![Alt Text](https://dev-to-uploads.s3.amazonaws.com/i/5uvyne0b0yz3r29wfvxl.png)

E clique em "Yes, enable" para instalar o Dokan Library, que permitirá montar o sistema de arquivos em uma unidade do sistema (K: geralmente, no Windows, e /keybase no Linux e no macOS)

![Alt Text](https://dev-to-uploads.s3.amazonaws.com/i/xcbs6tn0avqqg1zwbw4n.png)

## TODO: Continuar