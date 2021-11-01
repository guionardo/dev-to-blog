# B2BG File Provider Promax

General function is to get files from configured folders and send to HTTP receivers by PUT requests.

Setup is done by a configuration file located in {GEO}/etc/promax/B2BG_FILE_PROVIDER_PROMAX.cfg

GEO is defined by caller script B2B2A_01_01A.sh

## Process

![Process](docs/Process.png)

## Components

### HeartBeat ([source](src/heartbeat_sender.py))

Sends heartbeat metrics every 10 minutes (b2bg.heartbeat)

### FileFetcherService ([source](src/file_fetcher_service.py))

Read files from folders and create sparse lists by folder.

### FileSenderService ([source](src/file_sender_service.py))

Enqueue files to sending and manages SenderWorkers threads.

### DataDogSender ([source](src/dd_sender.py))

Publishes metrics to DataDog.

### SenderWorker ([source](src/sender_worker.py))

Consumes files from queue create by FileSenderService and sends to receivers.

### Receiver

Web API that exposes a PUT endpoint to receive files.

## Resouces

* Configuration: Example [here](docs/b2b-file-provider-promax.cfg)
* Circuit Breaker: Individual setup for b2b and odin dispatchers. (setup into "scheduling" section of configuration file)


## Arquitetura de Deploy

Nos ambientes ProMax, o script localizado em /amb/eventbin/2A2A_96_01A.sh é encarregado de executar o b2b-file-provider-promax e o b2b-file-receiver-promax. 

O 2A2A_96_01A.sh recebe um argumento que indica a GEO a ser processada.

### Arquivos importantes

* Scripts python: /{geo}/promax/b2b/bin/b2bg-file-provider-promax
* Script shell: /{geo}/promax/b2b/bin/b2bg-file-provider-promax/B2B2A_01_01A.sh
* Logs: /{geo}/promax/int/b2bg-file-provider-promax/log
* Arquivo STOP: /{geo}/promax/int/b2bg-file_provider-promax/B2BG-FILE-PROVIDER-PROMAX.STOP
* Arquivo Controle: /{geo}/promax/bin/b2b/b2bg-file_provider-promax/B2BG-FILE-PROVIDER-PROMAX.CTRL