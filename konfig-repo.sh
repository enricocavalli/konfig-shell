#!/bin/bash

KONFIG_GROUP=${KONFIG_GROUP:-"konfig"}
REPOS_PATH=${REPOS_PATH:-"/usr/local/konfigrepo"}

if [ -d "$REPOS_PATH" ]; then
	for path in "$@" ; do

		if [ -d "$path" ]; then

			if [ "$path" == "." ]; then
				path=$(pwd)
			fi

		dir_to_be_managed=${path%/} # remove trailing slash from arg
		repo_name=${dir_to_be_managed##*/}


		git init --bare --shared=group "$REPOS_PATH/$repo_name"

		cd "$dir_to_be_managed"
		echo "service=\"/etc/konfig/$repo_name\"" >> Konfigfile

		git init
		git add .
		git commit -m 'Initial commit'

		git remote add origin "$REPOS_PATH/$repo_name"
		git config branch.master.remote origin
		git config branch.master.merge refs/heads/master
		
		git push origin master

		mkdir -p /etc/konfig/$repo_name

		cat << EOF > /etc/konfig/$repo_name/00_pull.sh
cd $dir_to_be_managed
git pull --rebase
EOF


		cat << EOF > /etc/konfig/$repo_name/02_reload.sh
/etc/init.d/$repo_name reload
EOF


		cat << EOF > /etc/konfig/$repo_name/01_check_syntax.sh
true
EOF


		cat << EOF > /etc/konfig/$repo_name/zz_restart.sh
/etc/init.d/$repo_name restart
EOF

		chmod +x /etc/konfig/$repo_name/*.sh		
		
		fi
	done
else

	echo "Please create $REPOS_PATH with konfig-init.sh"

fi
