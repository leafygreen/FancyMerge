# Initialize
DESTBRANCH=''
SRCBRANCH=''
DESTREMOTE=''
SRCREMOTE=''

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
SQUASHBASE=$(git merge-base --fork-point $DESTREMOTE/$DESTBRANCH $SRCBRANCH)

# Rebase 

# Force Push

# Checkout master

# Merge

# Push

# Restore
{
  git stash -u
} || {
  echo "Could not stash."
  exit 1
}
