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

cat << EOF > /etc/konfig/$repo_name/konfig_restart_service.sh
cd $dir_to_be_managed
git pull --rebase
/etc/init.d/$repo_name restart
EOF
chmod +x /etc/konfig/$repo_name/konfig_restart_service.sh

cat << EOF > /etc/konfig/$repo_name/konfig_check_syntax_service.sh
true
EOF
chmod +x /etc/konfig/$repo_name/konfig_check_syntax_service.sh
fi
done
else
echo "Please create $REPOS_PATH with konfig-init.sh"
fi
