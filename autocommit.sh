#!/bin/bash

#######################################################################
## NOTE: This script originates from here but I tweaked the pull     ##
## command, changed default location for backup, and added a comment ##
## for reference later.                                              ##
#######################################################################

#####################################################################
### Please set the paths accordingly. In case you don't have all  ###
### the listed folders, just keep that line commented out.        ###
#####################################################################
### Path to your config folder you want to backup
config_folder=~/printer_data/config

# NOTE: The above should work for just about everyone, but a somewhat
# recent update to moonraker changed paths, etc. You can run the 
# provided moonraker script 'data-path-fix.sh' to fix/update
# older installs

set -e  # Exit immediately if a command exits with a non-zero status


### Path to your Klipper folder, by default that is '~/klipper'
klipper_folder=~/klipper

### Path to your Moonraker folder, by default that is '~/moonraker'
moonraker_folder=~/moonraker

### Path to your Mainsail folder, by default that is '~/mainsail'
mainsail_folder=~/mainsail

### Path to your Fluidd folder, by default that is '~/fluidd'
#fluidd_folder=~/fluidd

### The branch of the repository that you want to save your config
### By default that is 'main'
branch=master

#####################################################################
#####################################################################


#####################################################################
################ !!! DO NOT EDIT BELOW THIS LINE !!! ################
#####################################################################
grab_version(){
  if [ ! -z "$klipper_folder" ]; then
    cd "$klipper_folder"
    klipper_commit=$(git rev-parse --short=7 HEAD)
    m1="Klipper on commit: $klipper_commit"
    cd ..
  fi
  if [ ! -z "$moonraker_folder" ]; then
    cd "$moonraker_folder"
    moonraker_commit=$(git rev-parse --short=7 HEAD)
    m2="Moonraker on commit: $moonraker_commit"
    cd ..
  fi
  if [ ! -z "$mainsail_folder" ]; then
    mainsail_ver=$(head -n 1 $mainsail_folder/.version)
    m3="Mainsail version: $mainsail_ver"
  fi
  if [ ! -z "$fluidd_folder" ]; then
    fluidd_ver=$(head -n 1 $fluidd_folder/.version)
    m4="Fluidd version: $fluidd_ver"
  fi
}

# To fully automate this and not have to deal with auth issues, generate a legacy token on Github
# then update the command below to use the token. Run the command in your base directory and it will
# handle auth. This should just be executed in your shell and not committed to any files or
# Github will revoke the token. =)
# git remote set-url origin https://XXXXXXXXXXX@github.com/EricZimmerman/Voron24Configs.git/
# Note that that format is for changing things after the repository is in use, vs initially

push_config(){
  cd $config_folder

  # Check if the branch exists locally, create if not
  if ! git show-ref --verify --quiet refs/heads/$branch; then
    git checkout -b $branch
  else
    git checkout $branch
  fi

  # Check if the local branch is ahead of the remote branch
  if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/$branch)" ]; then
    # Check if there are any changes to commit
    if git diff --quiet; then
      # Rebase the local branch to match the remote branch
      git pull origin $branch --rebase
    else
      # Stash local changes, apply remote changes, and reapply stashed changes
      git stash save --include-untracked "Stash local changes"
      git pull origin $branch --rebase
      git stash pop
    fi
  fi

  # Check if there are any changes to commit
  if ! git diff --quiet; then
    # Add, commit, and force push changes to prioritize local changes
    git add .
    current_date=$(date +"%Y-%m-%d %T")
    git commit -m "Autocommit from $current_date" -m "$m1" -m "$m2" -m "$m3" -m "$m4"
    git push origin $branch --force
  else
    echo "No changes to commit."
  fi
}

grab_version
push_config