#!/bin/bash


function obtain_sudo_password() {
  if [ -z "${ar18_sudo_passwd+x}" ]; then
    echo "Testing for sudo capabilities..."
    set +e
    timeout 2 sudo id || (echo "User $(whoami) does not have sudo rights, aborting"; exit 1)
    set -e
    read -s -p "Enter your password: " sudo_passwd
    export ar18_sudo_passwd="${sudo_passwd}"
  fi
}


function pacman_install() {
  local errexit="$(shopt -op | grep errexit)"
  set -e
  packages="$1"
  obtain_sudo_password
  if [ -z "${ar18_pacman_cache_updated+x}" ]; then
    echo "${ar18_sudo_passwd}" | sudo -S -k pacman -Sy
    export ar18_pacman_cache_updated=1
  fi
  echo "${ar18_sudo_passwd}" | sudo -S -k pacman -S "${packages}" --noconfirm
  eval "${errexit}"
}
