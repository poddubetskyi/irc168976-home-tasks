#!/usr/bin/env bash

# The values of the following attributes should be set in the instance metadata 
instanceMetadataAttributes=( \
'mysqlDBMSRootUserSecretName' \
'phpMyAdminDbUserSecretName' \
'phpMyAdminAppUserSecretName' \
'nonRestrictedDataBucketURL' \
'websiteSSLPrivateKeySecretName' \
'websiteSSLPublicKeyCertObjectName' \
'websiteSSLPublicKeyCertsChainObjectName' \
'websiteSSLApacheConfigFileObjectName' \
'websiteStartPageFileObjectName' \
'isSSLSetupDataProvided' \
'instanceSSHServerPublicKeysContentsAttributePathValue' \
'instanceStartupScriptStateAttributePathValue' \
)

# the names of variables to store their contents
# in instance guest attributes
instanceSSHServerPublicKeysContents=''
instanceSSHServerPublicKeysContentsPath=''
instanceStartupScriptStateFlag=''
instanceStartupScriptStateFlagPath=''

apache_distros_list_to_install(){
tr --squeeze-repeats '\r\n' ' ' <<APACHEPKGLST
apache2
libapache2-mod-php
APACHEPKGLST
}

php_distros_list_to_install(){
tr --squeeze-repeats '\r\n' ' ' <<PHPPKGLST
php
php-cli
php-mysql
php-xml
php-iconv
php-mbstring
php-curl
php-tokenizer
php-xmlrpc
php-soap
php-ctype
php-zip
php-gd
php-simplexml
php-dom
php-intl
php-json
php-bz2
php-twig/buster-backports
PHPPKGLST
}

# Input
## $1 - secret name
# Standard output: secret value
# Status: gcloud tool exit status
get_secret(){
  gcloud secrets versions access 1 --secret "${1}"
  return ${?}
}

# Input:
## $1 - variable name that contains attribute path
## $2 - variable name in this script that contains attribute value. Must be scalar, not array
# Standard output: curl output if any
# Status:
## 0 - successful
## 1 - Instance guest attribute path variable name is not provided or its value is unset
## >1 - some other error occured
set_guest_attribute_value(){
  declare curlParameters=( \
    '--write-out' '%{http_code}' \
    '--header' "Metadata-Flavor: Google" \
    '--request' 'PUT'\
    '--silent')

    guestAttributesUrl='http://metadata.google.internal/computeMetadata/v1/instance/guest-attributes'

    if [[ -n "${1}" && ( ${!1:-itIsUnset} != 'itIsUnset' ) ]] ; then
      attributePath="${!1}"
      if [[ -n "${2}" && ( ${!2:-itIsUnset} != 'itIsUnset' ) ]] ; then
        attributeData="${!2}"
      else
        attributeData=''
      fi
      curl "${curlParameters[@]}" --data "${attributeData}" \
        "${guestAttributesUrl}${attributePath}" >&2
      return ${?}
    else
      printf 'ERROR in (%s). Instance guest attribute path variable name `%s` is not provided or its value is unset: `%s`\n' \
              "${FUNCNAME[0]}"
              "${1}" \
              "${!1}" >&2
      return 1
    fi
}

change_startup_script_state_flag(){
  set_guest_attribute_value 'instanceStartupScriptStateFlagPath' 'instanceStartupScriptStateFlag'
  return ${?}
}

# Input:
#   $1 property path
# Standard output:
#   property value
# Status:
# 0 - success
# 1 - proerty path not provided (empty string)
# 2 - any other error
get_instance_metadata_property_value(){
  if [[ -z "${1}" ]] ; then
    printf 'ERROR in (%s): Property path is not provided\n' \
      "${FUNCNAME[0]}" >&2
    return 1
  fi

  declare requestParameters=( \
  '--write-out' '%{http_code}' \
  '--header' "Metadata-Flavor: Google" \
  '--silent')

  local metadataServerBaseUrl='http://metadata.google.internal/computeMetadata/v1'

  response=$(curl "${requestParameters[@]}" "${metadataServerBaseUrl}${1}")
  httpCode="${response: -3}"
  if [[ "${httpCode}" == '200' ]] ; then
    printf '%s' "${response:0:-3}"
    return 0
  else
    return 2
  fi
}

# Input:
# $1 - The name of attribute to read
# Standard output:
#   attribute value
# Status:
# 0 - success
# 1 - empty name of attribute 
# 2 - http or curl error
get_metadata_attribute_value(){
  [[ -z "${1}" ]] && return 1

  attrName=${1}
  attrBasePath="/instance/attributes/"

  get_instance_metadata_property_value "${attrBasePath}${attrName}"
  return ${?}
}

# Input:
# $1 - bucket name attribute
# $2 - object name attribute
# Standard output:
#   object URL
# Status:
# 0 - success
# 1 - any error
build_source_object_path(){
  sourceURL=''
  for attrName in ${*} ; do
    if ! sourceURL="${sourceURL}/$(get_metadata_attribute_value ${attrName})" ; then
      printf 'ERROR in (%s): cannot get value of metadata attribute `%s`\n' \
        "${FUNCNAME[0]}" "${attrName}" >&2
      return 1
    fi
  done
  printf '%s' "${sourceURL#/}"
  return 0
}

# Input:
# $1 - bucket name attribute
# $2 - object name attribute
# $3 - local path to place to
# Standard output:
#   gcloud storage cp output if any
# Status:
# 0 - success
# 1 - any error
copy_object_from_cloud_storage(){
  if sourceURL=$(build_source_object_path "${1}" "${2}") &&
      destPath="${3}$(get_metadata_attribute_value ${2})" ; then
    sudo gcloud storage cp "${sourceURL}" ${destPath}
  else
    printf 'ERROR in (%s). Cannot build source (%s/%s), destination path (%s%s) or both of them\n' \
      "${FUNCNAME[0]}" "${1}" "${2}" "${3}" "${2}" >&2
    return 1
  fi
  return 0
}

get_documents_from_cloud_storage(){
  ## Copy an object with the name websiteStartPageFileObjectName to /var/www/html/${websiteStartPageFileObjectName}
  copy_object_from_cloud_storage \
    nonRestrictedDataBucketURL \
    websiteStartPageFileObjectName \
    '/var/www/html/'
}

get_and_apply_apache_ssl_config(){
  # Configuring APACHE
  ## Copy Apache configuration file to /etc/apache2/sites-available/
  copy_object_from_cloud_storage \
    nonRestrictedDataBucketURL \
    websiteSSLApacheConfigFileObjectName \
    '/etc/apache2/sites-available/'
  ## Copy webserver SSL certificate and chain files to /etc/ssl/certs/
  copy_object_from_cloud_storage \
    nonRestrictedDataBucketURL \
    websiteSSLPublicKeyCertObjectName \
    '/etc/ssl/certs/'
  copy_object_from_cloud_storage \
    nonRestrictedDataBucketURL \
    websiteSSLPublicKeyCertsChainObjectName \
    '/etc/ssl/certs/'
  
  if sslSecretName=$(get_metadata_attribute_value websiteSSLPrivateKeySecretName) ; then
    ## Copy website SSL private key contents to /etc/ssl/private/ as a file with the name ${sslSecretName}
    get_secret "${sslSecretName}" | \
      sudo tee "/etc/ssl/private/${sslSecretName}" > /dev/null
    ### Set ownership of the website's SSL private key file
    ### and restrict access to it only for the root user
    sudo chown -v root:root "/etc/ssl/private/${sslSecretName}"
    sudo chmod -v =700 "/etc/ssl/private/${sslSecretName}"
  else
    printf 'ERROR in (%s). Cannot get ssl private key file from a secret with the name `%s`\n' \
      "${FUNCNAME[0]}" "${sslSecretName}"
    return 1
  fi
  ## Enabling Apache SSL modules
  sudo a2enmod socache_shmcb
  sudo a2enmod ssl
  ## Enabling Apace SSL configuration
  sudo a2ensite $(get_metadata_attribute_value websiteSSLApacheConfigFileObjectName)
  ## Disabling Apache default configuration
  sudo a2dissite '000-default'
  if sudo apachectl configtest ; then
    sudo apachectl restart
  fi
}

unattended_mysql_secure_installation_data(){
cat <<ENDSQL
ALTER USER 'root'@'localhost' IDENTIFIED by '$(get_secret $(get_metadata_attribute_value mysqlDBMSRootUserSecretName))';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\\\_%';
FLUSH PRIVILEGES;
ENDSQL
}


configure_phpmyadmin_unattended_installation_settings_and_install_it(){
# dbconfig-common dbconfig-common/mysql/admin-pass password $(get_secret $(get_metadata_attribute_value mysqlDBMSRootUserSecretName))
# dbconfig-common dbconfig-common/remember-admin-pass boolean false
# phpmyadmin phpmyadmin/mysql/admin-pass password $(get_secret $(get_metadata_attribute_value mysqlDBMSRootUserSecretName))
sudo debconf-set-selections << PHPMYADMIN_UNATTENDED_INSTALL_SETTINGS
phpmyadmin phpmyadmin/dbconfig-install boolean true
phpmyadmin phpmyadmin/app-password-confirm password $(get_secret $(get_metadata_attribute_value phpMyAdminAppUserSecretName))
phpmyadmin phpmyadmin/mysql/app-pass password $(get_secret $(get_metadata_attribute_value phpMyAdminDbUserSecretName))
phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2
PHPMYADMIN_UNATTENDED_INSTALL_SETTINGS

sudo cp /etc/mysql/debian.cnf /etc/mysql/debian.cnf.bak
# temporarily add mysql root password into dbconfig tool configuration file
sudo sed --in-place --expression "s/^\(password =\) \?$/\1 $(get_secret $(get_metadata_attribute_value mysqlDBMSRootUserSecretName))/" /etc/mysql/debian.cnf

sudo apt-get install -y -q phpmyadmin

# revert the /etc/mysql/debian.cnf file to its original version
sudo mv /etc/mysql/debian.cnf.bak /etc/mysql/debian.cnf

}

get_instance_ssh_server_public_keys_and_place_them_into_instance_guest_attribute() {
  propertyPath='/instance/network-interfaces/0/access-configs/0/external-ip'
  if instanceSSHServerPublicKeysContents=$(ssh-keyscan \
                  $(get_instance_metadata_property_value "${propertyPath}")) ; then
    set_guest_attribute_value instanceSSHServerPublicKeysContentsPath instanceSSHServerPublicKeysContents
    return ${?}
  fi
  return 1
}

main (){
  # Where to place instance SSH Server Public Keys Contents in instance guest metadata
  instanceSSHServerPublicKeysContentsPath="/$(get_metadata_attribute_value \
                                              instanceSSHServerPublicKeysContentsAttributePathValue)"
  # Where to place instance Startup Script State Flag in instance guest metadata
  instanceStartupScriptStateFlagPath="/$(get_metadata_attribute_value \
                                              instanceStartupScriptStateAttributePathValue)"

  get_instance_ssh_server_public_keys_and_place_them_into_instance_guest_attribute

  # Check if this script has been executed before and skip re-execution if it is true
  if [[ -f "/etc/${HOSTNAME}-startup-was-launched" ]]; then exit 0; fi

  # This boot parameter controls the type of user interface used for the installer
  export DEBIAN_FRONTEND=noninteractive

  # Create the indicator that the startup-script has been started
  change_startup_script_state_flag

  # Updating the list of packages
  printf 'Updating the list of packages\n' >&2
  sudo apt update -y -q

  # Installing common tools
  printf 'Installing common tools\n' >&2
  sudo apt-get install -y -q curl debconf-utils

  # Installing Apache and modules
  printf 'Installing Apache and modules\n' >&2
  sudo apt-get install -y -q $(apache_distros_list_to_install)

  # Applying SSL settings to Apache configuration
  if sslDataProvided=$(get_metadata_attribute_value isSSLSetupDataProvided) && \
    [[ "${sslDataProvided}" == 'true' ]] ; then
    printf 'Applying Apache SSL configuration\n' >&2
    get_and_apply_apache_ssl_config
  fi

  # Getting website documents from cloud storage
  printf 'Getting website documents from cloud storage\n' >&2
  get_documents_from_cloud_storage

  # Installing PHP
  printf 'Installing PHP and modules\n' >&2
  sudo apt-get install -y -q $(php_distros_list_to_install)

  # Installing MySQL (MariaDB)
  printf 'Installing MySQL (MariaDB)\n' >&2
  sudo apt-get install -y -q mariadb-server 

  if ! systemctl --quiet --no-pager --state=active status mariadb > /dev/null ; then
    printf 'Starting MySQL (MariaDB)\n' >&2
    sudo systemctl start mariadb
  else
    printf 'The MySQL (MariaDB) DBMS is running\n' >&2
  fi

  printf 'Securing MySQL installation\n' >&2
  sudo mysql -sfu root < <(unattended_mysql_secure_installation_data)

  printf 'Installing PHPMyAdmin\n' >&2
  configure_phpmyadmin_unattended_installation_settings_and_install_it

  if ! systemctl --quiet --no-pager --state=active status apache2 > /dev/null ; then
    printf 'Starting Apache2\n' >&2
    sudo apachectl start
  else
    printf 'Restarting Apache2\n' >&2
    sudo apachectl restart
  fi

  # Create a file that indicates that this script has already been run once
  sudo touch -v "/etc/${HOSTNAME}-startup-was-launched"

  # https://cloud.google.com/compute/docs/metadata/manage-guest-attributes#gcloud
  # Set the indicator that the end of startup-script has been reached
  instanceStartupScriptStateFlag=1
  change_startup_script_state_flag
}

main
