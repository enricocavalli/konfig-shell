#!/bin/bash

REPOS_PATH=${REPOS_PATH:-"/usr/local/konfigrepo"}

help="

Usage:  konfig.sh [save|log|revert|restart|refresh|list|clone] ['descrizione commit']

  save  'descrizione commit' :  Salva i file di configurazione ed aggiorna il versioning
  log :     Mostra la lista dei commit effettuati
  revert:    Esegue il rollback all'ultima configurazione salvata
  restart:   Riavvia il servizio
  refresh:   Sincronizza le configurazioni del server centrale, viene eseguito automaticamente
             ad ogni operazione, ma è consogliabile lanciarlo prima di iniziare la modifica
             delle configurazioni
  list: mostra i servizi gestibili tramite konfig.sh
  clone: clona uno dei repository gestiti

"

go_to_gitroot()
{
  #while [[ $(pwd) != '/' && ! -d ".git" ]]; do 
  #	cd ..
  #done
  cd "$(git rev-parse --show-toplevel)"
}

init_git_config()
{
	username=$(git config --global --get user.name)
	useremail=$(git config --global --get user.email)
	if [ -z "$username" -o -z "$useremail" ]; then
		echo "Setup global git user.name and user.email"
		git config --global user.name "$USER"
		git config --global user.email "$USER@$HOSTNAME"
	fi
}

log()
{
	git log --pretty=format:"%h - %an, %ar : %s"
}

list()
{
	ls $REPOS_PATH
}

clone()
{
	git clone "$REPOS_PATH/$@"
}

refresh()
{
	git pull
}

refresh_and_rebase()
{
	git pull --rebase
}

# Verifica dove si trovano gli script di riavvio del servizio
# aprendo il file di configurazione Konfigfile nella root del
# repo.
get_restart_scripts()
{
	go_to_gitroot
	if [ ! -f "Konfigfile" ]; then
		echo "A file named \"Konfigfile\" must be present"
		exit 1
	fi
	. Konfigfile && echo $service
}

exec_script()
{
	sudo $1
	ret=$?
	if [ "$ret" != 0 ];
		then
		echo "Errore nell'esecuzione di: $1 !"
		exit 1
	fi
}

restart_services()
{
	#esiste il file per il controllo della sintassi?
	restart_scripts_dir=$(get_restart_scripts)
	if [ -z "$restart_scripts_dir" ]; then
		echo "Unable to find configuration to restart service"
		exit
	fi
	bin="$restart_scripts_dir/konfig_restart_service.sh"
	syntax="$restart_scripts_dir/konfig_check_syntax_service.sh"

	[ -x "$syntax" ] && echo "CONTROLLO SINTASSI" && exec_script "$syntax"
	[ -x "$bin" ] && echo "RILANCIO SERVIZIO" && exec_script "$bin"
}

save()
{

	msg="$@" # metto tra virgolette così gli argomenti vengono preservati anche se non ci sono virgolette nel comando

	if [ -z "$msg" ];
	then
	  msg='Messaggio non definito'
	fi
	git add . && git commit -m "$msg" && refresh_and_rebase && git push
	#restart_services
}

revert()
{
	git revert --no-edit HEAD && git push
}

if [ -z "$1" ]; then
	echo "$help"
	exit 1
fi

init_git_config

case $1 in
log)
	log
;;
list)
	list
;;
clone)
	shift
	clone $@
;;
refresh) 
	refresh
;;
save)
	shift # passo tutti gli argomenti dal due in poi alla funzione save
	save $@
;;
revert)
	revert
;;
restart)
	restart_services
;;
*) echo "$help"
;;
esac
