#!/usr/bin/env bash
# Which project needs to be changed
projectID=$(gcloud config get-value project)
# Where to find files that contain secrets
secretsFolder='./secrets-data/'
# What rights must be granted
memberRole="roles/secretmanager.secretAccessor"
#
secretNamePattern='^[a-zA-Z_0-9-]+$'

# Who must be granted access to
if ! vmServiceAccountMemberString=$(gcloud compute \
      project-info describe \
      --format='value(commonInstanceMetadata.items.vmServiceAccountMemberString)') || \
      [[ -z ${vmServiceAccountMemberString} ]] ; then
  printf 'ERROR in (%s). An error occurred while trying to get\n' "${0}" >&2
  printf 'the `vmServiceAccountMemberString` value from the `%s` project metadata\n' "${projectID}" >&2
  exit 1
fi

# Inputs
# $1 - secret name
# Outputs
# the status of the operation
# 0 - success, the secret exists
does_secret_exist(){
  [[ $(gcloud secrets list --filter="${1}" --format='value(name)' | wc -l) -gt 0 ]]
  return ${?}
}

# Inputs
# $1 - secret name
# $2 - member
# $3 - role
# Outputs
# the status of the operation
# 0 - success, the member of role exists for the secret
does_member_of_role_exist(){
  [[ $(gcloud secrets get-iam-policy "${1}" --filter="bindings.role:${3} AND bindings.members:${2}" --format='value(name)' | wc -l) -gt 0 ]]
  return ${?}
}
# Create secrets and grant access to them
# Create a secret in the Secret Manager for every *.secret file
while IFS=; read secretFile ; do
  secretName="${secretFile/%\.secret}"
  secretName="${secretName/#${secretsFolder}/}"
  if [[ ! ${secretName} =~ ${secretNamePattern} ]] ; then
    printf 'The secret name `%s` does not match required pattern `%s`. Skipped\n' "${secretName}" "${secretNamePattern}"
    continue
  fi
  if ! does_secret_exist "${secretName}" ; then 
    gcloud secrets create "${secretName}" --data-file="${secretFile}"
    lastResult=${?}
    if [[ ${lastResult} -gt 0 ]] ; then
      printf 'There are some errors are occured when creating a secret with the name `%s`\n' "${secretName}"
      continue
    fi
  else
    printf 'The secret `%s` already exists. Creation skipped\n' "${secretName}"
  fi
  # check if policy is already bound
  if ! does_member_of_role_exist "${secretName}" "${vmServiceAccountMemberString}" "${memberRole}" ; then 
    # grant access to the secret for particular service account
    gcloud secrets add-iam-policy-binding "${secretName}" \
      --member="${vmServiceAccountMemberString}" \
      --role="${memberRole}"
  else
    printf 'The role `%s` \nis already bounded for the member\n `%s` \non the secret `%s`.\n Binding skipped\n' \
      "${memberRole}" "${vmServiceAccountMemberString}" "${secretName}"
  fi
done < <(find "${secretsFolder}" -type f -iname '*.secret')

printf '\nAll operations have been completed successfully!\n'
printf 'Please, run the `./02-create-bucket-and-upload-non-restricted-data.bash` script to continue with this work\n'
