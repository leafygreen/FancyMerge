INSTALLDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

npm install -g underscore-cli

# Collect github username
echo "Enter your github username"
read USERNAME
echo "$USERNAME" > $INSTALLDIR/username
