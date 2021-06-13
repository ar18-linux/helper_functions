#!/bin/bash


function has_sudo_capabilities() {
  # Function template 2021-06-12.01
  local shell_options
  IFS=$'\n' shell_options=($(shopt -op))
  set -eu
  set -o pipefail
  local LD_PRELOAD_old
  LD_PRELOAD_old="${LD_PRELOAD}"
  LD_PRELOAD=
  local ret
  ret=0
  set -x
  ##############################FUNCTION_START#################################
  
  local output
  set +e
  output="$(sudo -vn 2>&1)"
  ret=$?
  set -e
  if [ "${ret}" = "0" ];then
    ret=0
  else
    if [[ "${output}" =~ "sudo: a password is required" ]]; then
      ret=0
    elif [[ "${output}" =~ "Sorry, user" ]]; then
      ret=1
    else
      echo "[ERROR]: Could not determine sudo access from:"
      echo "${output}"
      exit 1
    fi
  fi
  
  ###############################FUNCTION_END##################################
  set +x
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
  LD_PRELOAD="${LD_PRELOAD_old}"
  return "${ret}"
}


function obtain_sudo_password() {
  # Function template 2021-06-12.01
  local LD_PRELOAD_old
  LD_PRELOAD_old="${LD_PRELOAD}"
  LD_PRELOAD=
  local shell_options
  IFS=$'\n' shell_options=($(shopt -op))
  set -eu
  set -o pipefail
  local ret
  ret=0
  set +x
  ###############################FUNCTION_START#################################
  
  if [ "$(whoami)" = "root" ]; then
    read -p "[ERROR]: Must not be root!"
    exit 1
  fi
  if [ -z "${ar18_sudo_password+x}" ]; then
    echo "Testing for sudo capabilities..."
    
    if $(has_sudo_capabilities); then
      echo "Sudo rights have been asserted"
    else
       read -p "[ERROR]: User $(whoami) does not have sudo rights, aborting"; 
       exit 1
    fi
    local sudo_passwd
    read -s -p "Enter your password: " sudo_passwd
    echo ""
    echo "Testing the password with 'sudo -Sk id'"
    if [ ! "$(echo "${sudo_passwd}" | sudo -Sk id)" ]; then
      read -p "[ERROR]: Password is wrong (keyboard layout wrong, CAPS lock on?), or maybe your account is locked due to too many wrong password attempts. In this case, reset the counter with '#faillock --reset'"; 
      exit 1
    fi
    export ar18_sudo_password="${sudo_passwd}"
  fi
  
  ###############################FUNCTION_END##################################
  set +x
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
  LD_PRELOAD="${LD_PRELOAD_old}"
  return "${ret}"
}
export -f obtain_sudo_password


function pacman_install() {
  # Function template 2021-06-12.01
  local LD_PRELOAD_old
  LD_PRELOAD_old="${LD_PRELOAD}"
  LD_PRELOAD=
  local shell_options
  IFS=$'\n' shell_options=($(shopt -op))
  set -eu
  set -o pipefail
  local ret
  ret=0
  set +x
  ##############################FUNCTION_START#################################
  
  local packages
  packages="$1"
  obtain_sudo_password
  if [ ! -v ar18_pacman_cache_updated ]; then
    echo "${ar18_sudo_password}" | sudo -S -k pacman -Sy --noconfirm
    export ar18_pacman_cache_updated=1
  fi
  echo "${ar18_sudo_password}" | sudo -S -k pacman -S "${packages}" --noconfirm
  
  ###############################FUNCTION_END##################################
  set +x
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
  LD_PRELOAD="${LD_PRELOAD_old}"
  return "${ret}"
}
export -f pacman_install


function pip_install() {
  # Function template 2021-06-12.01
  local LD_PRELOAD_old
  LD_PRELOAD_old="${LD_PRELOAD}"
  LD_PRELOAD=
  local shell_options
  IFS=$'\n' shell_options=($(shopt -op))
  set -eu
  set -o pipefail
  local ret
  ret=0
  set +x
  ##############################FUNCTION_START#################################
  
  local packages
  packages="$1"
  pip3 install ${packages}
  
  ###############################FUNCTION_END##################################
  set +x
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
  LD_PRELOAD="${LD_PRELOAD_old}"
  return "${ret}"
}
export -f pip_install


function aur_install() {
  # Function template 2021-06-12.01
  local LD_PRELOAD_old
  LD_PRELOAD_old="${LD_PRELOAD}"
  LD_PRELOAD=
  local shell_options
  IFS=$'\n' shell_options=($(shopt -op))
  set -eu
  set -o pipefail
  local ret
  ret=0
  set +x
  ##############################FUNCTION_START#################################
  
  obtain_sudo_password
  for package in "$@"; do
    name="${package}"
    rm -rf /tmp/build 
    mkdir /tmp/build
    cd /tmp/build
    git clone https://aur.archlinux.org/${name}.git
    cd /tmp/build/${name}
    set +e
    LD_PRELOAD= makepkg -m --noconfirm
    if [ "$?" != "0" ]; then
      out="$(LD_PRELOAD= makepkg -m --noconfirm)"
      echo "${out}" | grep "Missing dependencies"
      if [ "$?" = "0" ]; then
        out="$(echo "${out}" | grep '\->')"
        declare -a arr
        arr=($(echo ${out}))
        for item in "${arr[@]}"; do
          if [ "${item}" != "->" ] && [ "${item}" != "" ]; then
            clean="$(echo "${item}" | sed -e 's/>=.*//g')"
            pacman_install "${clean}"
          fi
        done
      fi
      LD_PRELOAD= makepkg --noconfirm
    fi
    set -e
    echo "${ar18_sudo_password}" | sudo -S -k pacman -U --noconfirm --asdep ./*zst
  done
  
  ###############################FUNCTION_END##################################
  set +x
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
  LD_PRELOAD="${LD_PRELOAD_old}"
  return "${ret}"
}
export -f aur_install


function ar18_install() {
  # Function template 2021-06-12.01
  local LD_PRELOAD_old
  LD_PRELOAD_old="${LD_PRELOAD}"
  LD_PRELOAD=
  local shell_options
  IFS=$'\n' shell_options=($(shopt -op))
  set -eu
  set -o pipefail
  local ret
  ret=0
  set +x
  ##############################FUNCTION_START#################################
  
  set -x
  local install_dir
  install_dir="$1"
  local module_name
  module_name="$2"
  local script_dir
  script_dir="$3"
  
  obtain_sudo_password
  
  echo "${ar18_sudo_password}" | sudo -Sk mkdir -p "${install_dir}"
  echo "${ar18_sudo_password}" | sudo -Sk rm -rf "${install_dir}/${module_name}"
  echo "${ar18_sudo_password}" | sudo -Sk cp -rf "${script_dir}/${module_name}" "${install_dir}/${module_name}"
  echo "${ar18_sudo_password}" | sudo -Sk chmod +x "${install_dir}/${module_name}/"* -R
  
  if [ -f "${script_dir}/${module_name}/vars" ]; then
    mkdir -p "/home/${user_name}/.config/ar18/${module_name}"
    echo "${ar18_sudo_password}" | sudo -Sk chown "${user_name}:${user_name}" "/home/${user_name}/.config/ar18/${module_name}"
    if [ ! -f "/home/${user_name}/.config/${module_name}/vars" ]; then
      cp ${script_dir}/${module_name}/vars /home/${user_name}/.config/ar18/${module_name}/vars
      echo "${ar18_sudo_password}" | sudo -Sk chown "${user_name}:${user_name}" "/home/${user_name}/.config/ar18/${module_name}/vars"
    fi
  fi
  
  if [ -d "${script_dir}/${module_name}/config" ]; then
    local base_name
    mkdir -p "/home/${user_name}/.config/ar18/${module_name}"
    echo "${ar18_sudo_password}" | sudo -Sk chown "${user_name}:${user_name}" "/home/${user_name}/.config/ar18/${module_name}"
    for filename in "${script_dir}/${module_name}/config/"*; do
      base_name="$(basename "${filename}")"
      if [ ! -f "/home/${user_name}/.config/ar18/${module_name}/${base_name}" ]; then
      cp "${filename}" "/home/${user_name}/.config/ar18/${module_name}/${base_name}"
      echo "${ar18_sudo_password}" | sudo -Sk chown "${user_name}:${user_name}" "/home/${user_name}/.config/ar18/${module_name}/${base_name}"
    fi
    done
  fi
  
  if [ -f "${script_dir}/${module_name}/${module_name}.service" ]; then
    echo "${ar18_sudo_password}" | sudo -Sk chmod 644 "${install_dir}/${module_name}/${module_name}.service"
    echo "${ar18_sudo_password}" | sudo -Sk rm -rf "/etc/systemd/system/${module_name}.service"
    echo "${ar18_sudo_password}" | sudo -Sk ln -s "${install_dir}/${module_name}/${module_name}.service" "/etc/systemd/system/${module_name}.service"
    echo "${ar18_sudo_password}" | sudo -Sk systemctl enable "${module_name}.service"
    echo "${ar18_sudo_password}" | sudo -Sk systemctl start "${module_name}.service"
  fi
  
  if [ -f "${install_dir}/${module_name}/autostart.sh" ]; then
    if [ ! -d "/home/${user_name}/.config/ar18/autostarts" ]; then
      mkdir -p "/home/${user_name}/.config/ar18/autostarts"
    fi
    auto_start="/home/${user_name}/.config/ar18/autostarts/${module_name}.sh"
    echo "${ar18_sudo_password}" | sudo -Sk cp "${script_dir}/${module_name}/autostart.sh" "${auto_start}"
    echo "${ar18_sudo_password}" | sudo -Sk chmod 4750 "${auto_start}"
    echo "${ar18_sudo_password}" | sudo -Sk chown "root:${user_name}" "${auto_start}"
    echo "${ar18_sudo_password}" | sudo -Sk sed -i "s~{{INSTALL_DIR}}~${install_dir}~g" "${auto_start}"
  fi
  
  ###############################FUNCTION_END##################################
  set +x
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
  LD_PRELOAD="${LD_PRELOAD_old}"
  return "${ret}"
}
export -f ar18_install
