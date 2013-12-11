#!/bin/bash

REPOS_PATH=${REPOS_PATH:-"/usr/local/konfigrepo"}

help="

Usage:  konfig.sh [save|log|revert|restart|refresh|list|clone] ['descrizione commit']

  save  'descrizione commit' :  Salva i file di configurazione ed aggiorna il versioning
  log :     Mostra la lista dei commit effettuati
  revert:    Esegue il rollback all'ultima configurazione salvata
  restart:   Effettua il restart del servizio
  reload:	 Effettua il reload della configurazione del servizio
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
	. Konfigfile
	[ -z "$service" ] && echo "Unable to find configuration to restart service" && exit 1
	echo "$service"
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

exec_service_scripts()
{

	local reload_or_restart = $1
	#esiste il file per il controllo della sintassi?
	restart_scripts_dir=$(get_restart_scripts)

	for file in $restart_scripts_dir/[0-9]*.sh; do
		[ -x "$file" ] && echo "Executing $file" && exec_script "$file"
	done

  exec_script "$restart_scripts_dir/$reload_or_restart"
}

save()
{

	msg="$@" # metto tra virgolette così gli argomenti vengono preservati anche se non ci sono virgolette nel comando

	if [ -z "$msg" ];
	then
	  msg='Messaggio non definito'
	fi
	git add . && git commit -m "$msg" && refresh_and_rebase && git push

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
	refresh_and_rebase
;;
save)
	shift # passo tutti gli argomenti dal due in poi alla funzione save
	save $@
;;
revert)
	revert
;;
restart)
	exec_service_scripts "restart"
;;
reload)
	exec_service_scripts "reload"
;;
*) echo "$help"
;;
esac
