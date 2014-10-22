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

# Make sure current dir is a git repo
(git rev-parse --is-inside-work-tree &> /dev/null) || error "Not a git repo"

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

# Force Push

# Checkout master

# Merge

# Push

# Restore
{
  git stash -u
} || error "Could not stash."

