#!/usr/bin/env bash
#
# What needs to be set:
## The project ID must be provided
## It can exist or will be created by this script
## projectID value must meet the constraints that described in GCP documentation
## that is available using the following URL:
## https://cloud.google.com/resource-manager/docs/creating-managing-projects#before_you_begin
projectID='irc168976-hw04-gcp-e2e-t01'
projectIDShortenedTo27Chars="${projectID:0:27}"
# configurationName will be built as "${projectID}-cfg"
configurationName="${projectID}-cfg"
vmServiceAccountName="${projectIDShortenedTo27Chars}-sa"
vmServiceAccountMemberString="serviceAccount:${vmServiceAccountName}@${projectID}.iam.gserviceaccount.com"

requiredGCPServicesList=( \
  'compute.googleapis.com' \
  'secretmanager.googleapis.com' \
  'iam.googleapis.com' \
  'cloudasset.googleapis.com' \
  'storage.googleapis.com' \
)

# Default compute region and zone values 
defaultRegion='us-east1'
defaultZone='us-east1-b'

if [[ "${projectID}" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]{1}$ && \
        ! ( "${prId}" =~ ssl || "${prId}" =~ google ) ]] ; then
  printf 'The provided value `%s` meets the required constraints and will be used as a project ID\n' \
            "${projectID}"
else
  printf 'ERROR in (%s). The provided value `%s` does not meet the required constraints and cannot be used as project ID\n' "${0}" "${projectID}" >&2
  exit 1
fi

# if configuration with ${configurationName} doesn't exist
if [[ $(gcloud config configurations list \
        "--filter=(name:${configurationName})" \
        --format='value(name)' | wc -l ) -eq 0 ]] ; then
  #  then it will be created
  if gcloud config configurations create \
      --no-activate "${configurationName}" ; then
    printf 'The gcloud tool configuration with the name `%s` created successfully\n' \
              "${configurationName}"
  else
    printf 'ERROR in (%s). An error occurred while creating the gcloud tool configuration `%s`.\n' \
              "${0}" "${configurationName}" >&2
    exit 3
  fi
else
  printf 'A configuration with the name `%s` already exists and will be activated.\n' "${configurationName}"
fi

# The configuration will be activated
if gcloud config configurations activate \
    "${configurationName}" ; then
  printf 'The gcloud configuration with the name `%s` is activated successfully\n' "${configurationName}"
else
  printf 'ERROR in (%s). An error occurred while activating the gcloud configuration `%s`.\n' \
              "${0}" "${configurationName}" >&2
  exit 4
fi

# Get the first credentialed account
if credentialedAccountName=$(gcloud auth list \
                        --format="value(account)" | head --lines 1) && \
                        [[ -n "${credentialedAccountName}" ]] ; then
  # Set active account in active gcloud configuration
  if gcloud config set account "${credentialedAccountName}" ; then
    printf 'Credentialed account `%s` is successfully set for the configuration `%s`\n' \
             "${credentialedAccountName}" "${configurationName}"
  else
    printf 'ERROR in (%s). An error occurred while trying to set the account `%s` for the configuration `%s`.\n' \
        "${0}" "${credentialedAccountName}" "${configurationName}" >&2
    exit 5
  fi
else
  # No active accounts were found. Invoking GCP sign in procedure
  printf 'No credentialed accounts were found. In order to continue working with this configuration\n'
  printf 'script it is required to sign in with Google Cloud Platform.\n'
  printf 'To do this right now the following command will be automatically invoked:\n'
  printf '\t`gcloud auth login --no-launch-browser`\n'
  printf 'To complete the sign in procedure please follow\nthe instructions that will be displayed here.\n'
  if gcloud auth login --no-launch-browser 2>&1 ; then
    printf 'Sign in procedure is completed successfully.\n'
  else
    printf 'ERROR in (%s). The sign in procedure faled\n' "${0}" >&2
    exit 6
  fi 
fi

# List project with the provided name
if [[ $(gcloud projects list --filter="(project_id:${projectID})" \
        --format='value(project_id)' | wc -l) -eq 0 ]] ; then
  # The project is not found and will be created
  if gcloud projects create "${projectID}" --name="${projectID}" ; then
    printf 'A project with the ID `%s` is created successfully\n' "${projectID}"    
  else
    printf 'ERROR in (%s). An error occurred while trying to create a project with the ID `%s`.\n' \
        "${0}" "${projectID}" >&2
    exit 7
  fi
fi

# The project will be associated with current gcloud configuration
if gcloud config set project "${projectID}" ; then
  printf 'The project `%s` is successfully associated with the configuration `%s`\n' \
              "${projectID}" "${configurationName}"
else
  printf 'ERROR in (%s). An error occurred while trying to associate the project `%s` with the configuration `%s`.\n' \
            "${0}" "${projectID}" "${configurationName}" >&2
  exit 8
fi

# Check if an active billing account exists
if [[ $(gcloud beta billing accounts list --filter='open:true' \
          --format='value(ACCOUNT_ID)' | wc -l) -gt 0 ]] ; then 
  # Billing account exists
  # Check if there is an open billing account for the active project
  if [[ $(gcloud beta billing projects describe "${projectID}" \
            --format="value(billingEnabled)" | \
            tr '[[:upper:]]' '[[:lower:]]' ) == "true" ]] ; then
    # An association between the current active project and the open billing account already exists
    printf 'The project `%s` is already associated with the billing account `%s`\n' \
              "${projectID}" \
              $(gcloud beta billing projects describe "${projectID}" \
                  '--format=value(billingAccountName.scope(billingAccounts).segment(1))')
  else
    # Associate the current active project with the first open billing account
    if gcloud beta billing projects link "${projectID}" \
          --billing-account "$(gcloud beta billing accounts list \
            '--filter=open:true' '--limit=1' \
            '--format=value(ACCOUNT_ID)')" ; then
      printf 'The project `%s` has been successfully associated\nwith the open billing account `%s`.\n' \
            "${projectID}" \
            "$(gcloud beta billing accounts list '--filter=open:true' \
                '--limit=1' '--format=value(ACCOUNT_ID)')"
    else
      printf 'ERROR in (%s). An error occurred while trying to associate\n' "${0}" >&2
      printf 'the project `%s` with the open billing account `%s`.\n' \
            "${projectID}" \
            "$(gcloud beta billing accounts list '--filter=open:true' \
                '--limit=1' '--format=value(ACCOUNT_ID)')" >&2
      exit 10
    fi
  fi
else
  #  No open billing accounts were found for signed in oogle user account
  printf 'ERROR in (%s). No open billing accounts were found\nfor the `%s` Google user account.\n' \
            "${0}" "$(gcloud config get-value account)" >&2
  exit 9 
fi

# Enable required GCP APIs (services) for the active project
# [The list of services enabled by default](https://cloud.google.com/service-usage/docs/enabled-service)
for apiURL in "${requiredGCPServicesList[@]}" ; do 
  if gcloud services enable "${apiURL}" ; then
    printf 'The API (service) `%s` has been enabled successfully\n' "${apiURL}"
  else
    printf 'ERROR in (%s). An error occurred while trying to enable\n' "${0}"  >&2
    printf 'the API (service) `%s`\n' "${apiURL}" >&2
    exit 11
  fi
done

# Set default compute region for the active gcloud configuration
if gcloud config set 'compute/region' "${defaultRegion}"  ; then
    printf 'The compute region `%s` has been set successfully\n' "${defaultRegion}"
  else
    printf 'ERROR in (%s). An error occurred while trying to set\n' "${0}"  >&2
    printf 'the compute region `%s`\n' "${defaultRegion}" >&2
    exit 12
fi

# Set default compute zone for the active gcloud configuration
if gcloud config set 'compute/zone' "${defaultZone}"  ; then
    printf 'The compute zone `%s` has been set successfully\n' "${defaultZone}"
  else
    printf 'ERROR in (%s). An error occurred while trying to set\n' "${0}"  >&2
    printf 'the compute zone `%s`\n' "${defaultZone}" >&2
    exit 13
fi

# Create a service account to use with the project compute instance
if gcloud iam service-accounts create "${vmServiceAccountName}" \
      --description='Service account to access secrets in the Secret Manager and data in a bucket from a compute instance' \
      --display-name="${vmServiceAccountName}" ; then
  if gcloud compute project-info add-metadata \
      --metadata=vmServiceAccountMemberString="${vmServiceAccountMemberString}" ; then
    printf 'The vmServiceAccountMemberString value\n`%s`\n' "${vmServiceAccountMemberString}"
    printf 'has been successfully stored in the project metadata\n'
  else
    printf 'ERROR in (%s). An error occurred while trying to store\n' "${0}"  >&2
    printf 'the `%s` \nvmServiceAccountMemberString value into project metadata\n' "${vmServiceAccountMemberString}" >&2
  fi
else
  printf 'ERROR in (%s). A service account creation operation failed.\n' "${0}"  >&2
  printf 'The service account name is `%s`\n' "${vmServiceAccountName}" >&2
  exit 15
fi

printf '\nAll operations have been completed successfully!\n'
printf 'Please, run the `./01-create-secrets-in-secret-manager.bash` script to continue with this work\n'
