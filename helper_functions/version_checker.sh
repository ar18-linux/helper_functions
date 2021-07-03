#!/bin/bash

set -x

echo "checking version...4"
ar18_version_checker_caller="$(caller | cut -d ' ' -f2-)"
ar18_version_checker_caller="$(realpath "${ar18_version_checker_caller}")"
ar18_version_checker_dir_name="$(dirname "${ar18_version_checker_caller}")"
ar18_version_checker_module_name="$(basename "${ar18_version_checker_dir_name}")"
if [ -f "${ar18_version_checker_dir_name}/VERSION" ]; then
  ar18_version_checker_module_version_local="$(cat "${ar18_version_checker_dir_name}/VERSION")"
  rm -f /tmp/VERSION
  wget "https://raw.githubusercontent.com/ar18-linux/${ar18_version_checker_module_name}/master/${ar18_version_checker_module_name}/VERSION" -P /tmp
  ar18_version_checker_module_version_remote="$(cat "/tmp/VERSION")"
  echo "local version is ${ar18_version_checker_module_version_local}"
  echo "remote version is ${ar18_version_checker_module_version_remote}"
  if [[ "${ar18_version_checker_module_version_remote}" > "${ar18_version_checker_module_version_local}" ]]; then
    echo "new version available"
    if [ -f "/home/$(whoami)/.config/${ar18_version_checker_module_name}/INSTALL_DIR" ]; then
      echo "reinstalling"
    else
      echo "replacing"
      rm -rf "/tmp/${ar18_version_checker_module_name}"
      mkdir -p "/tmp/${ar18_version_checker_module_name}"
      old_cwd="${PWD}"
      cd "/tmp/${ar18_version_checker_module_name}"
      git clone "http://github.com/ar18-linux/${ar18_version_checker_module_name}"
      cp -raf "/tmp/${ar18_version_checker_module_name}/${ar18_version_checker_module_name}/${ar18_version_checker_module_name}/." "${ar18_version_checker_dir_name}/"
      cd "${old_cwd}"
      "${ar18_version_checker_caller}"
    fi
  fi
  
fi
#rm -rf "/tmp/helper_functions_$(whoami)"; 
#mkdir -p "/tmp/helper_functions_$(whoami)"; cd "/tmp/helper_functions_$(whoami)";
#wget https://raw.githubusercontent.com/ar18-linux/helper_functions/master/helper_functions/helper_functions.sh
#. "/tmp/helper_functions_$(whoami)/helper_functions.sh"