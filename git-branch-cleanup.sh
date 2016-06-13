#!/bin/bash

usage() {
	cat <<HELP

Usage:
git-branch-cleanup [-l] [-r] [-a] [-h] [-b <branch-name>]

Options:
  -l	delete local branches that are fully merged to master
  -r	delete remote branches that are  fully merged to master
  -a	delete local and remote branches that are fully merged to master
  -b	define branch name to compare to (default=master)
  -h	this help
HELP
exit
}

dir=$(dirname $0)
prune=false
delete_local=false
delete_remote=false
branch_name="master"

bold=`tput bold`
normal=`tput sgr0`

while getopts "lrab:h" opt; do
	case $opt in
		l)
			prune=true
			delete_local=true
			;;
		r)
			prune=true
			delete_remote=true
			;;
		a)
			prune=true
			delete_local=true
			delete_remote=true
			;;
		b)
			branch_name=$OPTARG
			;;
		h)
			usage
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			usage
			;;
	esac
done

echo "Checking fully merged branches against '${branch_name}' ..."
echo ""
if [[ `git status --porcelain` ]]; then
	echo "There are unsaved changes in your repo... " >&2
	echo ""
fi

# Update our list of remotes
git fetch -a

# Get rid of remotely deleted branches that are still on local
if $prune
then
	git remote prune origin
fi

# Checkout to reference branch
git checkout $branch_name

echo ""
echo "${bold}Local branches${normal} fully merged to ${branch_name}:"
git branch --merged $branch_name | grep -vE "(${branch_name}|master|nightly|production)$"
echo ""

# Remove local fully merged branches
if $delete_local
then
	echo "${bold}Deleting local branches${normal}"
	git branch --merged $branch_name | grep -vE "(${branch_name}|master|nightly|production)$" | xargs git branch -d
	echo ""
fi

# Show remote fully merged branches
echo "${bold}Remote branches${normal} are fully merged:"
git branch -r --merged $branch_name | sed 's/ *origin\//  /' | grep -vE "(${branch_name}|master|nightly|production)$"
echo ""

# Delete remote fully merged branches
if $delete_remote
then
	echo "${bold}Deleting remote branches${normal}"
	git branch -r --merged $branch_name | sed 's/ *origin\///' | grep -vE "(${branch_name}|master|nightly|production)$" | xargs -i% git push origin :%
fi
