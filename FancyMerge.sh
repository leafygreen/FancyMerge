# Initialize
DESTBRANCH=''
SRCBRANCH=''
DESTREMOTE=''
SRCREMOTE=''
COMMITMESSAGE=''

# Make sure current dir is a git repo
(git rev-parse --is-inside-work-tree &> /dev/null) || echo "Not a git repo" && exit 1;

# Stash old work
{
  git stash -u
} || {
  echo "Could not stash."
  exit 1
}

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
  git stash pop
} || {
  echo "Could not pop stash."
  exit 1
}
