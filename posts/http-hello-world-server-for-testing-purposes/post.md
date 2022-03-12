# HTTP Hello World server for testing purposes

Post created at 2022-03-12 09:53

I needed a http server, small, minimalistic, just for proxy testing.

There are many options to do this, but I wanted to create my own solution.

A basic golang project, with only native components, generating a docker image with 10MB. Just K.I.S.S. !

The repository for this project is in [github.com/guionardo/http_helloworld](https://github.com/guionardo/http_helloworld)

All what we need to do to use this tool is run a docker command: 

```bash
docker run --rm -p 8080:8080 guionardo/http_helloworld:latest
```

