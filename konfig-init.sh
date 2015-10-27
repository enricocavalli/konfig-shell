#!/bin/bash -e

KONFIG_GROUP=${KONFIG_GROUP:-"konfig"}
REPOS_PATH=${REPOS_PATH:-"/usr/local/konfigrepo"}

addgroup $KONFIG_GROUP

mkdir -p $REPOS_PATH
chown root:konfig  $REPOS_PATH
chmod 2770 $REPOS_PATH


echo "Konfig dir $REPOS_PATH created."
echo "Now remember to adduser ... konfig"

echo "Installing git"
apt-get update
apt-get install git-core git
