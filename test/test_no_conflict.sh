#!/bin/bash

# Create working space
git clone git@github.com:leafygreen/FancyMerge.git
cd FancyMerge

# Create branches
git checkout -b testNoConflictSrcBranch
git checkout -b testNoConflictDestBranch
git push origin testNoConflictDestBranch

git checkout testNoConflictSrcBranch

# Generate commits
touch uselessFile
git add uselessFile
git commit -m "First commit"
echo "some content" >> uselessFile
git add -u
git commit -m "Second commit"
echo "some more content" >> uselessFile
git add -u
git commit -m "Third commit"

git push origin testNoConflictSrcBranch

echo "Sleeping to let github process changes"
sleep 5

# Create pull request
hub pull-request -b testNoConflictDestBranch -h testNoConflictSrcBranch -m "TEST GENERATED PULL REQUEST" | sed -E 's/^.*\///'

