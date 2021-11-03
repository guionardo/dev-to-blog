# Automatizando publicações de artigos no dev.to com github actions

Recentemente decidi começar a escrever sobre problemas que encontro diariamente no desenvolvimento e as soluções encontradas. 

Entre as opções de plataformas de publicação, uma que eu gosto bastante é a [dev.to](https://dev.to/about) por alguns motivos: 

* É uma comunidade de desenvolvedores
* É construída com base em software open source ([Forem](https://forem.com))
* Não custa nada para quem escreve e nem para quem lê.

Eu já tinha alguns assuntos para começar a tratar aqui, mas resolvi organizar as postagens em uma plataforma centralizada, onde eu poderia de qualquer lugar, escrever, pensar, unir material e manter os dados em um local que eu sempre tenha acesso. Como nem tudo são flores no mundo open-source, não posso confiar que meus posts no dev.to ficarão lá para sempre.

Então, parti da ideia de criar um repositório no github para guardar meus artigos.

E já que os artigos ficariam no github, porque não automatizar a tarefa de publicação usando o github actions?

Ok, primeira coisa a ser verificada. O dev.to tem alguma API? 
- Tem! [DEV API](https://developers.forem.com/api)

Vamos precisar de três operações dessa API.

1. [Criar artigo](https://developers.forem.com/api#operation/createArticle)
2. [Editar artigo](https://developers.forem.com/api#operation/updateArticle)
3. [Obter dados de um artigo pelo seu ID](https://developers.forem.com/api#operation/getArticleById)


Então, precisamos ter um usuário registrado na plataforma. Como você é um desenvolvedor safo, não vou me preocupar com estas [instruções](https://dev.to/enter?state=new-user), ok?

Após logar no dev.to, acesse as [configurações da conta](https://dev.to/settings/account) e crie uma API key. Guarde essa chave para usarmos em seguida.

No próximo post, vamos configurar o repositório que usarmos para guardar os artigos e que automatizará a formatação e publicação.