#!/bin/bash


function has_sudo_capabilities() {
  local ret
  ret=0
  local errexit
  errexit="$(shopt -op | grep errexit)"
  set -e
  # Function template 2021-06-12.03
  # Function start
  local output
  set +e
  output="$(sudo -vn 2>&1)"
  set -e
  echo $?
  if [[ "${output}" =~ "sudo: a password is required" ]]; then
    ret=1
  elif [[ "${output}" =~ "Sorry, user" ]]; then
    ret=0
  else
    echo "[ERROR]: Could not determine sudo access from:"
    echo "${output}"
    exit 1
  fi
  # Function end
  eval "${errexit}"
  return "${ret}"
}


function obtain_sudo_password() {
  local errexit
  errexit="$(shopt -op | grep errexit)"
  set -e
  # Function start
  if [[ "$(whoami)" = "root" ]]; then
    read -p "[ERROR]: Must not be root!"
    exit 1
  fi
  if [ -z "${ar18_sudo_password+x}" ]; then
    echo "Testing for sudo capabilities..."
    has_sudo_capabilities
    if [ "$?" = "1" ]; then
      echo "Sudo rights have been asserted"
    else
       read -p "[ERROR]: User $(whoami) does not have sudo rights, aborting"; 
       exit 1
    fi
    local sudo_passwd
    read -s -p "Enter your password: " sudo_passwd
    export ar18_sudo_password="${sudo_passwd}"
  fi
  # Function end
  eval "${errexit}"
}


function pacman_install() {
  local errexit="$(shopt -op | grep errexit)"
  set -e
  # Function start
  packages="$1"
  obtain_sudo_password
  if [ -z "${ar18_pacman_cache_updated+x}" ]; then
    echo "${ar18_sudo_passwd}" | sudo -S -k pacman -Sy
    export ar18_pacman_cache_updated=1
  fi
  echo "${ar18_sudo_passwd}" | sudo -S -k pacman -S "${packages}" --noconfirm
  # Function end
  eval "${errexit}"
}


function ar18_install() {
  local errexit="$(shopt -op | grep errexit)"
  set -e
  # Function start
  local install_dir="$1"
  local module_name="$2"
  local script_dir="$3"
  
  obtain_sudo_password
  
  echo "${ar18_sudo_password}" | sudo -Sk mkdir -p "${install_dir}"
  echo "${ar18_sudo_password}" | sudo -Sk rm -rf "${install_dir}/${module_name}"
  echo "${ar18_sudo_password}" | sudo -Sk cp -rf "${script_dir}/${module_name}" "${install_dir}/${module_name}"
  echo "${ar18_sudo_password}" | sudo -Sk chmod +x "${install_dir}/${module_name}/"* -R
  
  if [ -f "${script_dir}/${module_name}/vars" ]; then
    if [ ! -f "/home/$(logname)/.config/${module_name}/vars" ]; then
      mkdir -p "/home/$(logname)/.config/${module_name}"
      cp ${script_dir}/${module_name}/vars /home/$(logname)/.config/${module_name}/vars
    fi
  fi
  # Function end
  eval "${errexit}"
}