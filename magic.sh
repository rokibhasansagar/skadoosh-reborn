#!/bin/bash

# Original Authors of "skadoosh" ---
# Neil "regalstreak" Agarwal,
# Harsh "MSF Jarvis" Shandilya,
# Tarang "DigiGoon" Kagathara
# Copyright © 2017
# -----------------------------------------------------
# Modified by - Rokib Hasan Sagar @rokibhasansagar
# -----------------------------------------------------

### Definitions need to be in ENV ---

# ROMNAME= "Short Name of ROM"
# Manifest_Link= "Git URL of Manifest Repo"
# BRANCH= "Exact Name of the Branch"

# GitHubMail, GitHubName
# FTPHost, FTPUser, FTPPass
# SFUser, SFPass, SFProject=transkadoosh

### ---------------------------------------------------

# Colors
CL_XOS="\033[34;1m"
CL_PFX="\033[33m"
CL_INS="\033[36m"
CL_RED="\033[31m"
CL_GRN="\033[32m"
CL_YLW="\033[33m"
CL_BLU="\033[34m"
CL_MAG="\033[35m"
CL_CYN="\033[36m"
CL_RST="\033[0m"

# Prepare
DIR=$(pwd)
echo -en "$CL_BLU Current directory is - $CL_RST" && echo $DIR

echo -e "$CL_GRN Github Authorization setting up $CL_RST"
git config --global user.email $GitHubMail
git config --global user.name $GitHubName
git config --global color.ui true

mkdir tranSKadooSH
cd tranSKadooSH

datetime=$(date +%Y%m%d)

echo -e "$CL_RED Initialize repo $CL_RST"
repo init -q -u $Manifest_Link -b $BRANCH --depth 1

echo -e "$CL_YLW Syncing it up! Wait for a few minutes... $CL_RST"
repo sync -c -q --force-sync --no-clone-bundle --no-tags -j32

echo -e "$CL_RED SHALLOW Source Syncing done $CL_RST"

cd $DIR

mkdir transload
mv tranSKadooSH/.repo transload/

echo -e "$CL_CYN Cleaning Checked-out Files $CL_RST"
rm -rf tranSKadooSH

mkdir fileparts

cd transload/
echo -e "$CL_RED Source Compressing in parts, This will take some time $CL_RST"
tar -cJf --verbose - * | split -b 700M - ../fileparts/$ROMNAME-$BRANCH-repo-$datetime.tar.xz.

cd ../fileparts/
echo -e "$CL_PFX Taking md5sums $CL_RST"
md5sum * > $ROMNAME-$BRANCH-repo-$datetime.md5sum

# Upload to AFH FTP
cd $DIR
echo -e "$CL_XOS Begin to upload $CL_RST"

wput fileparts ftp://"$FTPUser":"$FTPPass"@"$FTPHost"/tranSkadooSH/
echo -e "$CL_GRN Done uploading $CL_RST"

# Upload to SF
cd $DIR
echo -e "$CL_XOS Begin to upload in SF $CL_RST"

echo "exit" | sshpass -p "$SFPass" ssh -tto StrictHostKeyChecking=no $SFUser@shell.sourceforge.net create
rsync -v --rsh="sshpass -p $SFPass ssh -l $SFUser" fileparts/ $SFUser@shell.sourceforge.net:/home/frs/project/$SFProject/$ROMNAME/$BRANCH/

echo -e "$CL_GRN Done uploading $CL_RST"

# Clean Up
cd $DIR
rm -rf fileparts transload

echo -e "$CL_BLU All Process Done $CL_RST"
