#!/bin/bash

# Initialize
DESTBRANCH=''
SRCBRANCH=''
DESTREMOTE=''
SRCREMOTE=''
COMMITMESSAGE=''
INSTALLDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

error()
{
  echo $*
  exit 1
}

spawn_shell()
{
  # $1: function to run if subshell returns != 0
  recover_function=$1

  echo "rebase failed, spawning shell"
  bash
  exit_code=$?

  if ((exit_code!=0)) && [[ -n $1 ]]; then
    $recover_function
    exit_code=$?
  fi

  return $exit_code
}

recover_merge()
{
  git reset --hard $SRCBRANCH
}

# Check Arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 <github_repo> <PR#>"
  exit 1
fi

# Make sure current dir is a git repo
(git rev-parse --is-inside-work-tree &> /dev/null) || error "Not a git repo"

# Make sure github username file exists (AKA install script has been run)
if [ ! -e $INSTALLDIR/username ]; then
  echo "Please run $INSTALLDIR/install.sh before continuing"
  exit 1
fi

# Store arguments
GITHUBREPO=$1
PULLREQUEST=$2

# Read in username
USERNAME=$(cat $INSTALLDIR/username)

# Load info from github API
INFOFILE=".fancyMerge-PrInfo"
curl -u $USERNAME -H 'User-Agent: LeafyGreen/FancyMerge' https://api.github.com/repos/$GITHUBREPO/pulls/$PULLREQUEST > $INSTALLDIR/$INFOFILE
SRCREPO=$(cat $INSTALLDIR/$INFOFILE | underscore select ".head .repo .full_name" | sed -E 's/^.{2}//' | sed -E 's/.{2}$//' | sed -E 's/:/\//')
DESTREPO=$(cat $INSTALLDIR/$INFOFILE | underscore select ".base .repo .full_name" | sed -E 's/^.{2}//' | sed -E 's/.{2}$//' | sed -E 's/:/\//')

SRCBRANCH=$(cat $INSTALLDIR/$INFOFILE | underscore select ".head .ref" | sed -E 's/^.{2}//' | sed -E 's/.{2}$//' | sed -E 's/:/\//')
DESTBRANCH=$(cat $INSTALLDIR/$INFOFILE | underscore select ".base .ref" | sed -E 's/^.{2}//' | sed -E 's/.{2}$//' | sed -E 's/:/\//')
rm $INFOFILE

SRCREMOTE=$(git remote -v | grep "$SRCREPO" | grep "(fetch)" | head -n1 | cut -f 1)
DESTREMOTE=$(git remote -v | grep "$DESTREPO" | grep "(fetch)" | head -n1 | cut -f 1)

if [ -z "$SRCREMOTE" -o -z "$DESTREMOTE" ]; then
  echo "Could not match github repos with local remotes. Are you sure you're in the right repository?"
  exit 1
fi
if [ -z "$SRCBRANCH" -o -z "$DESTBRANCH" ]; then
  echo "Could not find branches from github"
  exit 1
fi

echo "Fancy Merge from $SRCREMOTE/$SRCBRANCH to $DESTREMOTE/$DESTBRANCH"

# Stash old work
{
  git stash -u
} || error "Could not stash."

# Fetch PR to local

# Move to working branch
git checkout $SRCBRANCH
git fetch $SRCREMOTE $SRCBRANCH

# Squash
git fetch $DESTREMOTE/$DESTBRANCH
SQUASHBASE=$(git merge-base --fork-point $DESTREMOTE/$DESTBRANCH $SRCBRANCH)
git reset --soft $SQUASHBASE
git commit -m "$COMMITMESSAGE"

# Rebase 
git rebase $DESTREMOTE/$DESTBRANCH
exit_code=$?

# Manual recover from bad rebase
((exit_code != 0)) && spawn_shell recover_merge

# Force Push

# Checkout master

# Merge

# Push

# Restore
{
  git stash -u
} || error "Could not stash."

