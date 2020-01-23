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

mkdir -p {tranSKadooSH,transload,fileparts}
cd tranSKadooSH

datetime=$(date +%Y%m%d)

google_cookies() {
  echo -en "\n$CL_GRN Setup Google Cookies for Smooth googlesource Clonning $CL_RST"
  git clone -q "https://$GITHUB_TOKEN@github.com/rokibhasansagar/google-git-cookies.git" &> /dev/null
  if [ -e google-git-cookies ]; then
    bash google-git-cookies/setup_cookies.sh
    rm -rf google-git-cookies
  fi
}

git_auth() {
  echo -e "\n$CL_GRN Github Authorization setting up $CL_RST"
  git config --global user.email $GitHubMail
  git config --global user.name $GitHubName
  git config --global color.ui true

  google_cookies
}

trim_darwin() {
  echo -e "\n$CL_RED Removing Unimportant Darwin-specific Files $CL_RST"
  cd .repo/manifests
  sed -i '/darwin/d' default.xml
  git commit -a -m "Magic" || true
  cd ../
  sed -i '/darwin/d' manifest.xml
  cd ../
}

repo_sync_shallow() {
  echo -e "\n$CL_RED Initialize repo $CL_RST"
  repo init -q -u $Manifest_Link -b $Branch --depth 1

  trim_darwin

  echo -e "\n$CL_YLW Syncing it up! Wait for a few minutes... $CL_RST"
  repo sync -c -q --force-sync --no-clone-bundle --optimized-fetch --prune --no-tags -j32

  echo -e "\n$CL_RED SHALLOW Source Syncing done $CL_RST"

  echo -e "\n$CL_BLU All Checked-out Folder/File Sizes $CL_RST"
  du -sh *
}

move_repo() {
  cd $DIR
  mv tranSKadooSH/.repo transload/
  tree -a --du -sh -- $DIR/transload/
}

clean_checkout() {
  cd $DIR
  echo -e "\n$CL_CYN Cleaning Checked-out Files $CL_RST"
  rm -rf tranSKadooSH
}

compress_shallow() {
  cd $DIR/transload/
  echo -e "\n$CL_RED Source Compressing in parts, This will take some time $CL_RST"
  tar -cJf - .repo | split -b 1280M - ../fileparts/$ROMName-$Branch-repo-$datetime.tar.xz.

  cd $DIR/fileparts/
  echo -e "\n$CL_PFX Taking md5sums $CL_RST"
  md5sum * > $ROMName-$Branch-repo-$datetime.md5sum
  echo -e "\n$CL_GRN The Compressed Files are - $CL_RST"
  du -sh *
}

upload_afh_ftp() {
  cd $DIR/fileparts/
  echo -e "\n$CL_XOS Begin to upload into AndroidFileHost FTP $CL_RST"

  for afhfile in $ROMName*; do wput $afhfile ftp://"$FTPUser":"$FTPPass"@"$FTPHost"/tranSkadooSH/$ROMName/$Branch/; done
  echo -e "\n$CL_GRN Done uploading $CL_RST"
}

upload_sf_rel() {
  cd $DIR/fileparts/
  echo -e "\n$CL_XOS Begin to upload into SourceForge Release $CL_RST"

  echo "exit" | sshpass -p "$SFPass" ssh -tto StrictHostKeyChecking=no $SFUser@shell.sourceforge.net create
  for sffile in $ROMName*; do rsync -v --rsh="sshpass -p $SFPass ssh -l $SFUser" $sffile $SFUser@shell.sourceforge.net:/home/frs/project/$SFProject/$ROMName/$Branch/; done

  echo -e "\n$CL_GRN Done uploading $CL_RST"
}

release_payload() {
  if [[ $Upload2AFH = 'true' ]]; then
    upload_afh_ftp
  fi
  if [[ $Upload2SF = 'true' ]]; then
    upload_sf_rel
  fi
}

clean_all() {
  cd $DIR
  rm -rf fileparts transload
}

tranSKadooSH() {
  git_auth || exit 1
  repo_sync_shallow
  if [ $? -eq 0 ]; then
    move_repo
    clean_checkout
    compress_shallow
    if [ $? -eq 0 ]; then
      release_payload || exit 1
    fi
  fi
}

tranSKadooSH
if [ $? -eq 0 ]; then
  clean_all
fi

echo -e "\n\n$CL_BLU All Process Done $CL_RST\n\n"
