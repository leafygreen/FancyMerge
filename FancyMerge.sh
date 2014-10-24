#!/bin/bash

# Initialize
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

  echo "rebase failed, spawning $SHELL. When rebase complete, run 'exit'"
  echo "If you cannot rebase successfully, run 'git rebase --abort' and then 'exit 1'"
  $SHELL
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
  echo "Usage: git FancyMerge <github_repo> <PR#>"
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

echo "Starting FancyMerge from $SRCREMOTE/$SRCBRANCH to $DESTREMOTE/$DESTBRANCH"

# Stash old work
{
  git stash -u
} || error "Could not stash."

# Move to working branch
git fetch $SRCREMOTE $SRCBRANCH
git checkout $SRCBRANCH

# Squash
echo "Squashing commits into a single commit..."
git fetch $DESTREMOTE $DESTBRANCH
SQUASHBASE=$(git merge-base $DESTREMOTE/$DESTBRANCH $SRCBRANCH)
git reset --soft $SQUASHBASE
git commit

# Rebase 
echo "Attempting to rebase onto $DESTREMOTE/$DESTBRANCH"
git rebase $DESTREMOTE/$DESTBRANCH
REBASE_EXIT_CODE=$?

# Manual recover from bad rebase
if [ $REBASE_EXIT_CODE -ne 0 ]; then
  second_exit=spawn_shell recover_merge
  if [ $second_exit -ne 0 ]; then
    exit 1
  fi
fi

# Force Push
git push -f $SRCREMOTE $SRCBRANCH

# Checkout master
git checkout $DESTBRANCH

# Merge
git merge --ff-only $SRCBRANCH

# Push
git push $DESTREMOTE $DESTBRANCH

# Restore
{
  git stash -u
} || error "Could not stash."

