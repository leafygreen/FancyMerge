#!/bin/bash

INSTALLDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

WHICH=$(which npm)
if [ "$WHICH" == "npm not found" ]; then
  echo "Dependency not met: must install npm"
  exit 1
fi

npm install -g underscore-cli

# Collect github username
echo "Enter your github username"
read USERNAME
mkdir -p $INSTALLDIR/bin
echo "$USERNAME" > $INSTALLDIR/bin/username

# Move script to bin location
cp $INSTALLDIR/FancyMerge.sh $INSTALLDIR/bin/git-FancyMerge
chmod +x $INSTALLDIR/bin/git-FancyMerge

echo "Installation's almost complete"
echo "Add the following line to the end of your shell's rc file"
echo "export PATH=$INSTALLDIR/bin:\$PATH"
echo "and then use FancyMerge by running"
echo "git FancyMerge <github_repo> <pull_request_number>"
