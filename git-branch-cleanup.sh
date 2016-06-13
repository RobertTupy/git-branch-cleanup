#!/bin/bash

usage() {
	cat <<HELP

Usage:
git-branch-cleanup [-l] [-r] [-a] [-h]

Options:
  -l	delete local branches that are fully merged to master
  -r	delete remote branches that are  fully merged to master
  -a	delete local and remote branches that are fully merged to master
  -h	this help
HELP
exit
}

dir=$(dirname $0)
prune=false
delete_local=false
delete_remote=false

bold=`tput bold`
normal=`tput sgr0`

while getopts "lrah" opt; do
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

# This has to be run from master
git checkout master

# Update our list of remotes
git fetch

# Get rid of remotly deleted branches that are still on local
if $prune
then
	git remote prune origin
fi

echo ""
echo "${bold}Local branches${normal} fully merged to master:"
git branch --merged master
echo ""

# Remove local fully merged branches
if $delete_local
then
	echo "${bold}Deleting local branches${normal}"
	git branch --merged master | grep -v 'master$' | xargs git branch -d
	echo ""
fi

# Show remote fully merged branches
echo "${bold}Remote branches${normal} are fully merged:"
git branch -r --merged master | sed 's/ *origin\///' | grep -v 'master$'
echo ""

# Delete remote fully merged branches
if $delete_remote
then
	echo "${bold}Deleting remote branches${normal}"
	git branch -r --merged master | sed 's/ *origin\///' | grep -v 'master$' | xargs -i% git push origin :%
fi
