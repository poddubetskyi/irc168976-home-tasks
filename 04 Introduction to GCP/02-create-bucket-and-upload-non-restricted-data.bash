# Where to search for files to upload
nonRestrictedDataSourceDirName='non-restricted-data/'

# Getting project properties
projectID="$(gcloud config get-value project)"
projectIDShortenedTo27Chars="${projectID:0:27}"

bucketURL="gs://${projectID}-vm-non-restricted-data"
bucketLocation="$(gcloud config get-value compute/region)"

if ! vmServiceAccountMemberString=$(gcloud compute \
      project-info describe \
      --format='value(commonInstanceMetadata.items.vmServiceAccountMemberString)') || \
      [[ -n ${vmServiceAccountMemberString} ]] ; then
  printf 'ERROR in (%s). An error occurred while trying to get\n' "${0}" >&2
  printf 'the `vmServiceAccountMemberString` value from the `%s` project metadata\n' "${projectID}" >&2
  exit 1
fi

memberRole="roles/storage.objectViewer"

# Input
## $1 - bucket url
## $2 - bucket location
# Output
## Operation status
### 0 - successful, bucket exists
does_bucket_exist(){
  # gcloud storage ls --format
  [[ $(gcloud storage buckets list "${1}" --filter="location=${2}" --format='value(name)' | wc -l) -gt 0 ]]
  return ${?}
}

# Create bucket and grant access to it
create_bucket(){
  # Check if bucket exists
  if ! does_bucket_exist "${bucketURL}" "${bucketLocation}" ; then
    # create bucket
    if gcloud storage buckets create "${bucketURL}" \
        --public-access-prevention \
        --location "${bucketLocation}" \
        --uniform-bucket-level-access ; then
      # Store bucket URL into project metadata
      if gcloud compute project-info add-metadata \
          --metadata=bucketURL="${bucketURL}" ; then
        printf 'The bucketURL value\n`%s`\n' "${bucketURL}"
        printf 'has been successfully stored in the project metadata'
      else
        printf 'ERROR in (%s). An error occurred while trying to store\n' "${0}"  >&2
        printf 'the `%s` \nbucketURL value into project metadata\n' "${bucketURL}" >&2
      fi
    else
      printf 'ERROR in (%s). An error occurred while creating the bucket `%s`.\n' \
              "${0}" "${bucketURL}" >&2
      exit 3
    fi
  else
    printf 'The bucket `%s` already exists. Creation skipped\n' "${bucketURL}"
  fi

  # Grant access to created bucket for a service account that will be associated with a VM instance
  gcloud storage buckets add-iam-policy-binding "${bucketURL}" \
    --member="${vmServiceAccountMemberString}" \
    --role="${memberRole}"
}

# Upload files into bucket. If a file exists it will be replaced
upload_files_into_bucket(){
  while IFS=; read fileName ; do
    fileNameOnly="${fileName/${nonRestrictedDataSourceDirName}/}"
    gcloud storage cp "${fileName}" "${bucketURL}"
  done < <(find "${nonRestrictedDataSourceDirName}" -type f)
}