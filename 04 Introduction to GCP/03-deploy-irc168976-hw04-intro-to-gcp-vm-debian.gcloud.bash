#!/usr/bin/env bash
# ===THE START OF DATA BLOCK ===

instanceStartupScriptStateAttributePath='provisioning-state/has-startup-script-reached-its-end'
instanceSSHServerPublicKeysContentsAttributePath='instance-properties/ssh-server-public-keys-list'

# Getting project properties
projectID="$(gcloud config get-value project)"
projectIDShortenedTo27Chars="${projectID:0:27}"

# VM general properties
vmName="${projectIDShortenedTo27Chars}-vm"
vmZoneId="$(gcloud config get-value compute/zone)"
startupScriptFilePath="./irc168976-hw04-intro-to-gcp-debian.startup-script.bash"

if [[ ! -f "${startupScriptFilePath}" ]] ; then
  printf 'ERROR in (%s): startup script file `%s` is not found\n' \
                  "${0}" \
                  "${startupScriptFilePath}" >&2
  exit 1
fi

# An array of command line options to pass to the gcloud tool
vmCreationCommandProperties=(
  "${vmName}"
  '--zone' "${vmZoneId}" \
  '--boot-disk-auto-delete' \
  '--boot-disk-size' '10GB' \
  '--machine-type' 'e2-micro' \
  '--image-family' 'debian-10' \
  '--image-project' 'debian-cloud' \
)

# Get VM service account MemberString
if ! vmServiceAccountMemberString=$(gcloud compute \
      project-info describe \
      --format='value(commonInstanceMetadata.items.vmServiceAccountMemberString)') || \
      [[ -z ${vmServiceAccountMemberString} ]] ; then
  printf 'ERROR in (%s). An error occurred while trying to get\n' "${0}" >&2
  printf 'the `vmServiceAccountMemberString` value from the `%s` project metadata\n' "${projectID}" >&2
  exit 2
fi

# Get bucket URL from project metadata
if ! bucketURL=$(gcloud compute \
      project-info describe \
      --format='value(commonInstanceMetadata.items.bucketURL)') || \
      [[ -z ${bucketURL} ]] ; then
  printf 'ERROR in (%s). An error occurred while trying to get\n' "${0}" >&2
  printf 'the `bucketURL` value from the `%s` project metadata\n' "${projectID}" >&2
  exit 3
fi

# VM creation command parameters to associate service account
# with new VM and allow it access the Secret Manager service
# [Use Secret Manager with Compute Engine and Google Kubernetes Engine](https://cloud.google.com/secret-manager/docs/accessing-the-api#oauth-scopes)
vmCreationCommandProperties+=(
  '--service-account' "${vmServiceAccountMemberString/#serviceAccount:/}" \
  '--scopes' 'cloud-platform' \
)

# VM user account properties
vmUsername='adminuser'
sshPublicKeyFilePath="${HOME}/.ssh/irc168976-hw04-intro-to-gcp-vm-key-ed25519.key.pub"
sshPublicKeyMetadataFilePath="${sshPublicKeyFilePath}.metadata"

# VM IP address properties
externalIpAddrID='hw04-vm-ext-ip-addr'
vmCreationCommandProperties+=( \
  '--address' "${externalIpAddrID}" \
)

# VM Matadata from file properties list
declare -A metadataFromFileProperties=(
  ['startup-script']="${startupScriptFilePath}" \
  ['ssh-keys']="${sshPublicKeyMetadataFilePath}" \
)

# VM Metadata inline properties list
declare -A metadataInlineProperties=( \
  ['enable-guest-attributes']='TRUE' \
  ['isSSLSetupDataProvided']='false' \
  ['mysqlDBMSRootUserSecretName']='hw04-vm-mysql-db-root-pw' \
  ['phpMyAdminDbUserSecretName']='hw04-vm-mysqladmin-app-db-pw' \
  ['phpMyAdminAppUserSecretName']='hw04-vm-mysqladmin-app-adm-pw' \
  ['nonRestrictedDataBucketURL']="${bucketURL}" \
  ['websiteSSLPrivateKeySecretName']='website-key-pem' \
  ['websiteSSLPublicKeyCertObjectName']='website.cert.pem' \
  ['websiteSSLPublicKeyCertsChainObjectName']='website.chain.pem' \
  ['websiteStartPageFileObjectName']='index.html' \
  ['websiteSSLApacheConfigFileObjectName']='website-ssl.conf' \
  ['instanceStartupScriptStateAttributePathValue']="${instanceStartupScriptStateAttributePath}" \
  ['instanceSSHServerPublicKeysContentsAttributePathValue']="${instanceSSHServerPublicKeysContentsAttributePath}" \
)

# ===THE END OF DATA BLOCK===
# ===THE START OF CODE BLOCK===

# Create SSH public key metadata file
# [Metadata-managed SSH connections](https://cloud.google.com/compute/docs/instances/ssh#metadata)
create_ssh_public_key_metadata_file () {
  if [[ ! -f "${sshPublicKeyMetadataFilePath}" ]] ; then
    if [[ -f "${sshPublicKeyFilePath}" ]] ; then
      printf '%s:' "${vmUsername}" > "${sshPublicKeyMetadataFilePath}"
      cat "${sshPublicKeyFilePath}" >> "${sshPublicKeyMetadataFilePath}"
    else
      printf 'ERROR in (%s): SSH public key file `%s` is not found\n' \
                      "${0}" \
                      "${sshPublicKeyFilePath}" >&2
      return 1
    fi
  fi
  return 0
}

# Input: the name of an associative array that contains metadata properties
# Output: a string of comma-separated key=value pairs that is printed to standard output 
populate_metadata_properties(){
  # get associative array contents inside this function
  rpMeta=$(declare -p   ${1})
  eval "declare -A metadataProperties=""${rpMeta#*=}";
  propertiesString=''
  for propName in ${!metadataProperties[@]} ; do
    propertiesString+="${propName}=${metadataProperties[${propName}]},"
  done
  printf '%s' "${propertiesString/%,/}"
}

# Check for existence or create a new public IP address
# No input
check_does_public_ip_exist() {
  if [[ $(gcloud compute addresses list --quiet \
            --filter="name=${externalIpAddrID}" \
            --format='value(name)' | wc -l ) -eq 0 ]] ; then
    printf 'Allocating external IP address with name `%s`\n' "${externalIpAddrID}"
    gcloud compute addresses create "${externalIpAddrID}" --region=$(gcloud config get-value compute/region)
    gcloud compute firewall-rules create allow-inbound-http-traffic --action allow --rules tcp:80,tcp:443
    gcloud compute firewall-rules create allow-inbound-ssh-traffic-from-me \
      --source-ranges "$(curl http://ipecho.net/plain)/32" --action allow --rules tcp:22
  else
    printf 'External IP address with name `%s` already exists.\n Its IP address value is `%s`\n' \
        "${externalIpAddrID}" \
        "$(gcloud compute addresses describe ${externalIpAddrID} --format='value(address)')"
  fi
}

# Input:
## $1 - attribute path string
## $2 - wait threshold in seconds. The default value is 60
# Standard output: attribute value
# Status:
## 0 - The attribute has become available
## 1 - attribute path string is not set
## 2 - Waiting threshold has been reached
wait_for_the_instance_guest_attribute_availability(){
  if [[ "${1:-itIsUnset}" == 'itIsUnset' ]] ; then return 1 ; fi
  if [[ "${2:-itIsUnset}" == 'itIsUnset' || \
        ! "${2}" =~ ^[[:digit:]]{1,3}$ ]] ; then 
    secondsToWait=60
  else
    secondsToWait=${2}
  fi

  threshold=$(date --date="+${secondsToWait} second" "+%s")
  # emulate do..while loop for the case when secondsToWait=0
  timeout=0
  while [[ "${timeout}" -ge 0 ]] ; do
    if attrContents=$(gcloud compute instances get-guest-attributes "${vmName}" \
                    --query-path="${1}" \
                    --zone="${vmZoneId}" --format='value(value)' 2>/dev/null) ; then
      printf '%s' "${attrContents}"
      return 0
    fi
    sleep 5
    timeout=$(( $threshold - $(date "+%s") ))
  done
  return 2
} 

# Monitor the VM provisioning process by checking whether the end of the startup script has been reached
# Input: no input
wait_startup_script_to_finish() {
  attributePathToWatchFor="${instanceStartupScriptStateAttributePath}"
  threshold=$(date --date="+9 min" "+%s")
  timestamp=$(date "+%s")
  printf 'Wait for "%s" startup script to reach its end.' "${vmName}"
  while [[ $(( $threshold - $timestamp )) -gt 0 ]] ; do
    if status="$(wait_for_the_instance_guest_attribute_availability \
              ${attributePathToWatchFor} 5)" && \
              [[ "${status}" -eq 1 ]] ; then
      printf '\nThe end of the startup script has been reached\n'
      return 0
    fi
    printf '.'
    sleep 5
    timestamp=$(date "+%s")
  done
  printf '\nThe initialization process seems to be taking longer than expected\nGiving up.\n'
  printf 'It'\''s recommended to connect to new VM using SSH and look at its state from inside\n'
  return 1
}

# Inform user about further actions
# No input
print_summary_info (){
  printf '\nWaiting for information about ssh server public keys list on "%s"...\n' "${vmName}"
  if instanceSSHServerPublicKeys=$(wait_for_the_instance_guest_attribute_availability \
    "${instanceSSHServerPublicKeysContentsAttributePath}") ; then
    printf '# Instance SSH Server Public Keys are as follows:\n%s\n' "${instanceSSHServerPublicKeys}"
    printf '\nTo import them into user known_hosts file use the following command:\n'
    printf 'gcloud compute instances get-guest-attributes \
              "%s" \
              --query-path="%s" \
              --zone="%s" \
              --format="value(value)" >> \
              "%s/.ssh/known_hosts"\n' \
              "${vmName}" \
              "${instanceSSHServerPublicKeysContentsAttributePath}" \
              "${vmZoneId}" \
              "${HOME}"
    printf '\nTo remove all keys belonging to `%s` from user known_hosts file use the following command:\n' \
              "$(gcloud compute addresses describe ${externalIpAddrID} --format='value(address)')"
    printf 'ssh-keygen -f "%s/.ssh/known_hosts" \\\n -R "%s"\n' \
              "${HOME}" \
              "$(gcloud compute addresses describe ${externalIpAddrID} --format='value(address)')"
  fi

  printf '\nUse the following commands to work with VM instance and resources:\n'
  printf '1) To access VM CLI using SSH:\n'
  printf '\tgcloud compute ssh "%s@%s" \\\n\t\t--ssh-key-file="%s" \\\n\t\t--ssh-flag="-v" \\\n\t\t--zone="%s"\n' \
            "${vmUsername}" \
            "${vmName}" \
            "${sshPublicKeyFilePath/%\.pub/}" \
            "${vmZoneId}"
  printf '2) To delete this VM instance:\n\t%s\n' \
            "gcloud compute instances delete '${vmName}'"

}

# Create the VM
# No input
main () {
  # Call SSH public key metadata file creation code 
  create_ssh_public_key_metadata_file || exit ${?}
  # Test does the VM with provided name exist
  if [[ $(gcloud compute instances list --quiet \
            --filter="(name=${vmName})" \
            --format="value(name)" | wc -l) -eq 0 ]] ; then

    check_does_public_ip_exist
    # Create VM
    if gcloud compute instances create \
      "${vmCreationCommandProperties[@]}" \
      --metadata-from-file="$(populate_metadata_properties metadataFromFileProperties)" \
      --metadata="$(populate_metadata_properties metadataInlineProperties)"
    then
      print_summary_info

      # Keep this script running until the end of startup-script is not reached, but not more than 9 minutes
      wait_startup_script_to_finish
    else
      printf 'Looks like some errors were occured after running VM creation command :(\n'
    fi
  else
    printf 'Looks like VM with the name `%s` already exists\n' "${vmName}"
    print_summary_info
  fi
}

# Call a VM creation code
main
