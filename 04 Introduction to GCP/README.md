# IRC168976 DevOps GL BaseCamp homework 04. Introduction to GCP


## Conditions


## Solution

#### Distribution contents




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

3) If you wish to set up a secure TLS connection on your website and you have an ssl private key file, x.509 cerificate and certificate chain for your website then do the following
   1) Place the contents of ssl private key file into the `secrets-data/website-key-pem.secret` file. The private key file should be in PEM (that is not DER) format. The keys in the PEM format contain the lines `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines at the beginning and the end of the private key file.

   2) If you have an  
4) Run 