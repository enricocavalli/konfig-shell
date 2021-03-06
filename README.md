# Konfig

Konfig è uno script sviluppato per dare la possibilità ad utenze non
privilegiate di poter modificare la configurazione di specifici servizi (es.
nagios, bind, etc.) e di poter applicare le modifiche tramite l'esecuzione di
script invocati tramite sudo.

Tutte le modifiche delle configurazioni saranno salvate in un repository GIT,
in modo da poter ritornare a configurazioni stabili e funzionanti in caso di
problemi.


## Guida pratica

I passi che verranno comunemente eseguiti da chi deve applicare configurazioni
sono

- clono un repository di configurazioni da gestire
- modifico i file di configurazione
- salvo la configurazione
- faccio ripartire il servizio

Come comandi shell la prima volta:

    konfig.sh list
    konfig.sh clone nagios3

    [ ... ]
    konfig.sh save "Ho fatto la modifica XYZ"
    konfig.sh reload|restart

Comandi shell per le volte successive:

    konfig.sh refresh
    konfig.sh save "messaggio esplicativo"
    konfig.sh reload|restart
 

## Passi a cura dell'utente root

L'utente root deve inizializzare una tantum il sistema, creando un gruppo
`konfig` e una directory che conterrà i repository cui gli utenti autorizzati
avranno accesso. L'inizializzazione viene fatta tramite lo script


    $ konfig-init.sh


Per inserire una directory di configurazione nel sistema di gestione root
eseguirà

    konfig-repo.sh /etc/directory


Ovviamente il sistema è generalizzabile con più gruppi. Questo script oltre a
creare il repository in `/etc/directory` e clonarlo sotto
`/usr/local/konfigrepo`, imposta correttamente i permessi e crea gli script da
eseguire tramite sudo sotto `/etc/konfig/directory/`.

Questi script sono numerati `00_*.sh`, dove il numero serve a dare un ordine
all'esecuzione e tipicamente avremo:

- 00_pull.sh importa le ultime modifiche dal repository condiviso
- 01_check_syntax.sh fa un eventuale controllo di sintassi

Sono presenti anche gli script `reload.sh` e `restart.sh` dall'ovvio
significato.

Se uno script termina con errore l'esecuzione ovviamente si ferma.

L'utente root avrà cura di inserire in `/etc/sudoers` una riga del tipo

	%konfig   ALL=(ALL) NOPASSWD: /etc/konfig/*/*.sh


## Workflow utente

L'installazione ed inizializzazione verrà eseguita dall'utente root. Con
questa procedura verranno creati tanti repository GIT, quanti sono i servizi
da gestire, in `/usr/local/konfigrepo/`  in base alle proprie esigenze.

L'utenza non privilegiata dovrà lavorare nella propria home (o comunque in un
posto dove ha i permessi di scrittura) per poter clonare il repository e così
lavorare sulla configurazione.


Ad esempio:

    $ ssh utente@server-con-konfig-configurato
    $ konfig.sh list
    bind nagios3

    $ konfig.sh clone nagios3

A questo punto l'utente si ritrova nella sua HOME una directory in tutto e per
tutto uguale alla configurazione originale del servizio e potrà operare su
questi file per poi salvare e pushare la configurazione sul repository
centrale.

Il restart si preoccupa dell'aggiornamento sotto /etc/ con un `git pull` e del
restart vero e proprio del servizio.


### Modifica di una configurazione

Quanto segue si intende eseguito all'interno di un repository gestito tramite
`konfig.sh`.

Per salvare delle modifiche eseguire semplicemente 

    konfig.sh save 'Eventuale commento significativo'

Il comando esegue un commit nel repository utente e un push sul repository
condiviso (non prima di aver scaricato le ultime modifiche dal repository
centrale).

E' naturalmente possibile, anzi raccomandabile, fare un refresh dal repository
centrale prima di iniziare a lavorare sulle configurazioni:

    konfig.sh refresh


### Restart del servizio

Eseguire `konfig.sh restart`


### Log delle configurazioni effettuate

E' sempre possibile vedere la storia delle modifiche effettuate sul
repository: è indicato chi ha fatto quale modifica. Trattandosi di repository
git sono comunque disponibili tutti i comandi git.

    $ konfig.sh log


### Annullare una configurazione non corretta

Posto che è comunque possibile, in caso di errori, continuare l'editing e fare
un nuovo save, è in realtà possibile effettuare un `revert` all'ultima
configurazione stabile. I comandi sono:

    $ konfig.sh revert
    $ konfig.sh restart

### Impostazioni del git client

E' consigliabile configurare sul proprio client git

    git config --global push.default simple
