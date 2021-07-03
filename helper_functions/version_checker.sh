#!/bin/bash

ar18_version_cheker_caller="$(caller | cut -d ' ' -f2-)"
ar18_version_cheker_dir_name="$(dirname "${ar18_version_cheker_caller}")"
ar18_version_cheker_module_name="$(basename "${ar18_version_cheker_dir_name}")"
if [ -f "${dirname}/VERSION" ]; then
  ar18_version_cheker_module_version_local="$(cat "${dirname}/VERSION")"
  rm -f /tmp/VERSION
  wget "https://raw.githubusercontent.com/ar18-linux/${ar18_version_cheker_module_name}/master/${ar18_version_cheker_module_name}/VERSION" -P /tmp
  ar18_version_cheker_module_version_remote="$(cat "/tmp/VERSION")"
  if [ "${ar18_version_cheker_module_version_remote}" > "${ar18_version_cheker_module_version_local}" ]; then
    echo "new version available"
  fi
  #if [ -f "/home/$(whoami)/.config/${ar18_version_cheker_module_name}/INSTALL_DIR" ]; then
    
  #fi
fi
#rm -rf "/tmp/helper_functions_$(whoami)"; 
#mkdir -p "/tmp/helper_functions_$(whoami)"; cd "/tmp/helper_functions_$(whoami)";
#wget https://raw.githubusercontent.com/ar18-linux/helper_functions/master/helper_functions/helper_functions.sh
#. "/tmp/helper_functions_$(whoami)/helper_functions.sh"