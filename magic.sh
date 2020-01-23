#!/bin/bash

# Original Authors of "skadoosh" ---
# Neil "regalstreak" Agarwal,
# Harsh "MSF Jarvis" Shandilya,
# Tarang "DigiGoon" Kagathara
# Copyright © 2017
# -----------------------------------------------------
# Modified by - Rokib Hasan Sagar @rokibhasansagar
# =====================================================

### Definitions need to be in ENV ---

# ROMName= "Short Name of ROM"
# Manifest_Link= "Git URL of Manifest Repo"
# Branch= "Exact Name of the Branch"

# GitHubMail, GitHubName
# FTPHost, FTPUser, FTPPass
# SFUser, SFPass, SFProject

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

echo -en "$CL_GRN Setup Google Cookies for Smooth googlesource Clonning $CL_RST"
git clone -q "https://$GITHUB_TOKEN@github.com/rokibhasansagar/google-git-cookies.git" &> /dev/null
if [ -e google-git-cookies ]; then
  bash google-git-cookies/setup_cookies.sh
  rm -rf google-git-cookies
else
  echo "google-git-cookies repo not found on your account, see steps on README"
fi

echo -e "$CL_RED Initialize repo $CL_RST"
repo init -q -u $Manifest_Link -b $Branch --depth 1

# Trim Darwin
cd .repo/manifests
sed -i '/darwin/d' default.xml
git commit -a -m "Magic" || true
cd ../
sed -i '/darwin/d' manifest.xml
cd ../

echo -e "$CL_YLW Syncing it up! Wait for a few minutes... $CL_RST"
repo sync -c -q --force-sync --no-clone-bundle --optimized-fetch --prune --no-tags -j32

echo -e "$CL_RED SHALLOW Source Syncing done $CL_RST"

# All Checked-out Folder/File Sizes
du -sh *

cd $DIR

mkdir transload
mv tranSKadooSH/.repo transload/

echo -e "$CL_CYN Cleaning Checked-out Files $CL_RST"
rm -rf tranSKadooSH

mkdir fileparts

cd transload/
echo -e "$CL_RED Source Compressing in parts, This will take some time $CL_RST"
tar -cJf - * | split -b 1280M - ../fileparts/$ROMName-$Branch-repo-$datetime.tar.xz.

cd ../fileparts/
echo -e "$CL_PFX Taking md5sums $CL_RST"
md5sum * > $ROMName-$Branch-repo-$datetime.md5sum
echo -e "$CL_GRN The Compressed Files are - $CL_RST"
du -sh *

if [[ $Upload2AFH = 'true' ]]
# Upload to AFH FTP
echo -e "$CL_XOS Begin to upload $CL_RST"

for afhfile in $ROMName*; do wput $afhfile ftp://"$FTPUser":"$FTPPass"@"$FTPHost"/tranSkadooSH/$ROMName/$Branch/; done
echo -e "$CL_GRN Done uploading $CL_RST"
fi

if [[ $Upload2SF = 'true' ]]
# Upload to SF
echo -e "$CL_XOS Begin to upload in SF $CL_RST"

echo "exit" | sshpass -p "$SFPass" ssh -tto StrictHostKeyChecking=no $SFUser@shell.sourceforge.net create
for sffile in $ROMName*; do rsync -v --rsh="sshpass -p $SFPass ssh -l $SFUser" $sffile $SFUser@shell.sourceforge.net:/home/frs/project/$SFProject/$ROMName/$Branch/; done

echo -e "$CL_GRN Done uploading $CL_RST"
fi

# Clean Up
cd $DIR
rm -rf fileparts transload

echo -e "$CL_BLU All Process Done $CL_RST"
