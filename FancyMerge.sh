#!/bin/bash

# Initialize
DESTBRANCH=''
SRCBRANCH=''
DESTREMOTE=''
SRCREMOTE=''
COMMITMESSAGE=''

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

# Get parameters from command line
if [[ -z "$1" ]]; then
    error "Error: need a pull-request number as the first argument"
else
    number=$1
fi

if [[ -n "$2" ]]; then
    remote=$2
else
    remote='origin'
fi

uri=$( git remote -v 2> /dev/null | grep "$remote" | head -1 | cut -f 2 )
[[ -n "$uri" ]] || error "Error: couldn't determine origin URI"
uri="${uri% (fetch)}"
uri="${uri% (push)}"

# Make sure current dir is a git repo
(git rev-parse --is-inside-work-tree &> /dev/null) || error "Not a git repo"

# Stash old work
{
  git stash -u
} || error "Could not stash."

# Fetch PR to local
(git fetch -f "$uri" "refs/pull/$number/head:PR/$number" &> /dev/null) \
    || error "Error: can't fetch PR $number from $uri"

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

