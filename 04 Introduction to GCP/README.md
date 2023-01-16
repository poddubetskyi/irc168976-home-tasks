# IRC168976 DevOps GL BaseCamp homework 04. Introduction to GCP


## Conditions

1) Create a Google Cloud CLI or Terraform script that will automatically deploy, configure, and run the [LAMP Main TASK](https://cloud.google.com/community/tutorials/setting-up-lamp) on a Google Compute Engine instance. 

## Solution

#### Distribution contents

* `README.md` - the file with the inforbation about this work
* `00-configure.bash` - a script to automatically configure the Google Cloud CLI tool to further deploy the resource as part of this work.
* `01-create-secrets-in-secret-manager.bash` - a script to automatically create a set of secrets in the Secret Manager. The secrets are created based on the contents and file names of the `secrets-data` directory and are intended for further use in the process of deploying and configuring a virtual machine instance
* `02-create-bucket-and-upload-non-restricted-data.bash` - a script to automatically create a bucket for some data that is not sensitive and place that data into it
* `03-deploy-irc168976-hw04-intro-to-gcp-vm-debian.gcloud.bash` - a script to run the deployment process
* `irc168976-hw04-intro-to-gcp-debian.startup-script.bash` - a script to automatically set the deployed vm instance up
* `secrets-data/` - the folder that contain files with secrets
  * `hw04-vm-mysql-db-root-pw.secret` - a file that contain the desired password for the MySql DBMS
  * `hw04-vm-mysqladmin-app-adm-pw.secret` - a file that contain the desired password for the PHPMyAdmin App
  * `hw04-vm-mysqladmin-app-db-pw.secret` - a file that contain the desired password for the PHPMyAdmin App 
secrets-data/website-key-pem.secret
* `non-restricted-data/`
  * `index.html` - the main page document for the website that is deployed within this work
  * `website-ssl.conf` - the configuration file for the Apache web server
  * `website.cert.pem` - the X.509 public key certificate that pairs to the website private key
  * `website.chain.pem` - the certificate chain to validate the website public key certificate



### How to use

#### Prerequisites

1) Valid Google account that is a user of Google Cloud Platform
2) Open Cloud Billing account
3) Local Linux environment with BASH 4.0 (WSL or a PC that is running Linux)
4) The [Google Cloud CLI](https://cloud.google.com/sdk/) installed in that mentioned Linux environment

#### Configure deployment and deploy the VM

1) Download the distro contents into some folder:
2) Set the execution flag for the files with the zero digit at the beginning of their names:
```
chmod u+x 0*.bash
``` 
1) Go to the `secrets-data` folder:
   1) Populate the files in it with your passwords in plain text format. Each file must contain only one password and only the password symbols. No newlines, leading or trailing spaces are allowed or they will be added to the secret.
2) Go to the `non-restricted-data` folder:
   1) Replace the `index.html` file content with your own, if needed.

3) If you wish to set up a secure TLS connection on your website and you have an ssl private key file, x.509 cerificate, and certificate chain for your website certificate then do the following:
   1) Place the contents of ssl private key file into the `secrets-data/website-key-pem.secret` file. The private key file should be in PEM (that is not DER) format. The keys in the PEM format contain the lines `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines at the beginning and the end of the private key file.
   2) Place the contents of your certificate file and certificate chain file into `non-restricted-data/website.cert.pem` and `non-restricted-data/website.chain.pem` files accordingly.
   3) In the file search the line `['isSSLSetupDataProvided']='false'` and replace the `false` value to `true`
4) Run the following commands:
    1) ```
    ./00-configure.bash 2>$(date '+%0Y.%0m.%0d_%0H-%0M-%0S')-00-configure.bash.err | tee $(date '+%0Y.%0m.%0d_%0H-%0M-%0S')-00-configure.bash.log
    ```
    2) ```
    ./01-create-secrets-in-secret-manager.bash 2>$(date '+%0Y.%0m.%0d_%0H-%0M-%0S')-01-create-secrets-in-secret-manager.bash.err | tee $(date '+%0Y.%0m.%0d_%0H-
    %0M-%0S')-01-create-secrets-in-secret-manager.bash.log
    ```
    3) ```
    ./02-create-bucket-and-upload-non-restricted-data.bash 2>$(date '+%0Y.%0m.%0d_%0H-%0M-%0S')-02-create-bucket-and-upload-non-restricted-data.bash.err | tee $(date '+%0Y.%0m.%0d_%0H-%0M-%0S')-02-create-bucket-and-upload-non-restricted-data.bash.log
    ```
    4) ```
    ./03-deploy-irc168976-hw04-intro-to-gcp-vm-debian.gcloud.bash 2>$(date '+%0Y.%0m.%0d_%0H-%0M-%0S')-03-deploy-irc168976-hw04-intro-to-gcp-vm-debian.gcloud.bash.err | tee $(date '+%0Y.%0m.%0d_%0H-%0M-%0S')-03-deploy-irc168976-hw04-intro-to-gcp-vm-debian.gcloud.bash.log
    ```