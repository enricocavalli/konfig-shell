# Konfig

Konfig è uno script sviluppato per dare la possibilità ad utenze non
privilegiate di poter modificare la configurazione di specifici servizi (es.
nagios, bind, etc.) e di poter applicare le modifiche tramite l'esecuzione di
script invocati tramite sudo.

Tutte le modifiche delle configurazioni saranno salvate in un repository GIT,
in modo da poter ritornare a configurazioni stabili e funzionanti in caso di
problemi.


## Passi a cura dell'utente root

L'utente root deve inizializzare una tantum il sistema, creando un gruppo
`konfig` e una directory che conterrà i repository cui gli utenti autorizzati
avranno accesso. L'inizializzazione viene fatta tramite lo script

<pre>
konfig-init.sh
</pre>

Per inserire una directory di configurazione nel sistema di gestione root
eseguirà

<pre>
konfig-repo.sh /etc/directory
</pre>

Ovviamente il sistema è generalizzabile con più gruppi. Questo script oltre a
creare il repository in `/etc/directory` e clonarlo sotto
`/usr/local/konfigrepo`, imposta correttamente i permessi e crea gli script da
eseguire tramite sudo sotto `/etc/konfig/directory/`.

Questi script sono numerati `00_xxx.sh`, `01_yyy.sh`, e così via, dove il
numero serve a dare un ordine all'esecuzione e tipicamente avremo:

- lo script 00 importa le ultime modifiche dal repository condiviso
- lo script 01 fa un eventuale controllo di sintassi
- lo script 02 esegue il restart del servizio.

Se uno script termina con errore l'esecuzione ovviamente si ferma.

L'utente root avrà cura di inserire in `/etc/sudoers` una riga del tipo

<pre>
%konfig   ALL=(ALL) NOPASSWD: /etc/konfig/*/[0-9]*_*
</pre>


## Workflow utente

L'installazione ed inizializzazione verrà eseguita dall'utente root. Con
questa procedura verranno creati tanti repository GIT, quanti sono i servizi
da gestire, in `/usr/local/konfigrepo/`  in base alle proprie esigenze.

L'utenza non privilegiata dovrà lavorare nella propria home (o comunque in un
posto dove ha i permessi di scrittura) per poter clonare il repository e così
lavorare sulla configurazione.


Ad esempio:
<pre>

$ ssh utente@server-con-konfig-configurato
$ konfig.sh list
bind nagios3

$ konfig.sh clone nagios3
</pre>

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

<pre>
konfig.sh save 'Eventuale commento significativo'
</pre>

Il comando esegue un commit nel repository utente e un push sul repository
condiviso (non prima di aver scaricato le ultime modifiche dal repository
centrale).

E' naturalmente possibile, anzi raccomandabile, fare un refresh dal repository
centrale prima di iniziare a lavorare sulle configurazioni:

<pre>
konfig.sh refresh
</pre>


### Restart del servizio

Eseguire `konfig.sh restart`


### Log delle configurazioni effettuate

E' sempre possibile vedere la storia delle modifiche effettuate sul
repository: è indicato chi ha fatto quale modifica. Trattandosi di repository
git sono comunque disponibili tutti i comandi git.

<pre>
$ konfig.sh log
</pre>


### Annullare una configurazione non corretta

Posto che è comunque possibile, in caso di errori, continuare l'editing e fare
un nuovo save, è in realtà possibile effettuare un `revert` all'ultima
configurazione stabile. I comandi sono:

<pre>
$ konfig.sh revert
$ konfig.sh restart
</pre>
