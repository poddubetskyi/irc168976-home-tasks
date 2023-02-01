# IRC168976 DevOps GL BaseCamp homework 10. Kubernetes, manual deployment (Setup Kubernetes)

## Conditions 

Deploy a Kubernetes cluster by following [the instructions](https://docs.google.com/document/d/1pdjbDpzc2l23B_w84-m2ft1JdLVYXsvA/edit) provided

## Solution 

### Prerequisites

1) Valid Google account that is a user of Google Cloud Platform
2) Open Cloud Billing account
3) Local Linux environment with BASH 4.0 (WSL or a PC that is running Linux)
4) The [Google Cloud CLI](https://cloud.google.com/sdk/) installed in that mentioned Linux environment

### Preparatory actions

1) Create two SSH key pairs:
   1) for the `kubemaster` VM:
      * The command:
        ```bash
        ssh-keygen -t ed25519 -C 'adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key' -f ~/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key
        ```
      * The output:
        ```
        Generating public/private ed25519 key pair.
        Enter passphrase (empty for no passphrase):
        Enter same passphrase again:
        Your identification has been saved in /c/Users/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key
        Your public key has been saved in /c/Users/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key.pub
        The key fingerprint is:
        SHA256:d6EMwzJJc2/5vad9ovjzD+JFRS6sTB3laA5M/FMIh2M adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key
        The key's randomart image is:
        +--[ED25519 256]--+
        |      o .  .ooooo|
        |     . = . +E+.*.|
        |      + + +.=o*.+|
        |       o = = Boo |
        |        S + = +. |
        |         . . . . |
        |            . + .|
        |           o.o.=.|
        |          ..++oo+|
        +----[SHA256]-----+
        ```
      * The result:
        ```
        "${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key"
        "${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key.pub"
        ```
   2) for the `kubenode` VM:
      * The command:
        ```bash
        ssh-keygen -t ed25519 -C 'adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key' -f ~/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key
        ```
      * The output:
        ```
        Generating public/private ed25519 key pair.
        Enter passphrase (empty for no passphrase):
        Enter same passphrase again:
        Your identification has been saved in /c/Users/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key
        Your public key has been saved in /c/Users/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key.pub
        The key fingerprint is:
        SHA256:8zkrkcNBW4OXVcp20GkbebhFsL7RUNK+eskgT1jIhlA adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key
        The key's randomart image is:
        +--[ED25519 256]--+
        |        .E ooo+Bo|
        |       .o =. oB++|
        |       ..+o.=.+B |
        |        o. = +oo.|
        |       .So. o o o|
        |        =o + o + |
        |         o+ + = .|
        |        .  o o + |
        |         ..   .  |
        +----[SHA256]-----+
        ```
      * The result:
        ```
        ${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key
        ${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key.pub
        ```
2) Set the private mode on private key files:
   * The command:
     ```bash
     find ${HOME}/.ssh/ -type f -iname '*hw10*kube*.key' -exec chmod -v =0600 '{}' ';'
     ```
   * The result:
     ```
     mode of '/home/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key' changed from 0664 (rw-rw-r--) to 0600 (rw-------)
     mode of '/home/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key' changed from 0664 (rw-rw-r--) to 0600 (rw-------)
     ```
3) Create two metadata files from SSH public key files:
   1) for the `kubemaster` VM:
      * The commands:
        ```bash
        printf 'adminuser:' > "${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key.pub.metadata"
        cat "${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key.pub" >> "${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key.pub.metadata"
        ```
      * The result:
        ```
        "${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key.pub.metadata"
        ```
   2) for the `kubenode` VM:
      * The commands:
        ```bash
        printf 'adminuser:' > "${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key.pub.metadata"
        cat "${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key.pub" >> "${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key.pub.metadata"
        ```
      * The result:
        ```
        "${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key.pub.metadata"
        ```
4) Start the `ssh-agent` and add created private keys to it:
   1) Start the agent:
      * The command:
        ```bash
        eval `ssh-agent`
        ```
      * The output:
        ```
        Agent pid 25879
        ```
   2) Add the keys:
      * The commands:
        ```bash
        ssh-add /home/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key
        ssh-add /home/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key
        ```
      * The output:
        ```
        Enter passphrase for /home/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key:
        Identity added: /home/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key (adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-from-pm-7091-key-ed25519.key)
        Enter passphrase for /home/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key:
        Identity added: /home/poddubetskyi/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key (adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-from-pm-7091-key-ed25519.key)
        ```
5) Set up the `gcloud` configuration:
   1) Project ID: `irc168976-hw10-k8s-man-dply`
   2) Default region: `europe-west1`
   3) Default zone: `europe-west1-b`
   4) Enable the billing for the prooject
   5) Enable the `compute.googleapis.com` service.


### The deployment steps

1)  Create instances using `gcloud`:
    1) The `kubemaster` instance:
       * The command:
         ```bash
         gcloud compute instances create \
               "irc168976-hw10-k8s-manual-deployment-kubemaster-vm" \
               --zone "$(gcloud config get-value compute/zone)" \
               --boot-disk-auto-delete \
               --boot-disk-size '25GB' \
               '--custom-vm-type=e2' \
               '--custom-cpu=4' '--custom-memory=8192MB' \
               --image-family 'ubuntu-2004-lts' \
               --image-project 'ubuntu-os-cloud' \
               --scopes 'cloud-platform' \
               --address "$( gcloud compute addresses create \
                               hw10-k8s-kubemaster-ext-ip \
                               --region=$(gcloud config get-value compute/region) \
                               --format='value(name)' )" \
               --metadata-from-file=ssh-keys="${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key.pub.metadata" \
               --metadata="enable-guest-attributes=TRUE"
         ```
       * The output:
         ```
         Your active configuration is: [irc168976-hw10-k8s-man-dply-cfg]
         Your active configuration is: [irc168976-hw10-k8s-man-dply-cfg]
         Created [https://www.googleapis.com/compute/v1/projects/irc168976-hw10-k8s-man-dply/regions/europe-west1/addresses/hw10-k8s-kubemaster-ext-ip].
         WARNING: You have selected a disk size of under [200GB]. This may result in poor I/O performance. For more information, see: https://developers.google.com/compute/docs/disks#performance.
         Created [https://www.googleapis.com/compute/v1/projects/irc168976-hw10-k8s-man-dply/zones/europe-west1-b/instances/irc168976-hw10-k8s-manual-deployment-kubemaster-vm].
         WARNING: Some requests generated warnings:
         - Disk size: '25 GB' is larger than image size: '10 GB'. You might need to resize the root repartition manually if the operating system does not support automatic resizing. See https://cloud.google.com/compute/docs/disks/add-persistent-disk#resize_pd for details.
 
         NAME                                                ZONE            MACHINE_TYPE                   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP  STATUS
         irc168976-hw10-k8s-manual-deployment-kubemaster-vm  europe-west1-b  custom (e2, 4 vCPU, 8.00 GiB)               10.132.0.6   34.79.40.78  RUNNING
         ```
    1) The `kubenode` instance:
       * The command:
         ```bash
         gcloud compute instances create \
               "irc168976-hw10-k8s-manual-deployment-kubenode-vm" \
               --zone "$(gcloud config get-value compute/zone)" \
               --boot-disk-auto-delete \
               --boot-disk-size '25GB' \
               '--custom-vm-type=e2' \
               '--custom-cpu=4' '--custom-memory=8192MB' \
               --image-family 'ubuntu-2004-lts' \
               --image-project 'ubuntu-os-cloud' \
               --scopes 'cloud-platform' \
               --address "$( gcloud compute addresses create \
                               hw10-k8s-kubenode-ext-ip \
                               --region=$(gcloud config get-value compute/region) \
                               --format='value(name)' )" \
               --metadata-from-file=ssh-keys="${HOME}/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key.pub.metadata" \
               --metadata="enable-guest-attributes=TRUE"
         ```
       * The output:
         ```
         Your active configuration is: [irc168976-hw10-k8s-man-dply-cfg]
         Your active configuration is: [irc168976-hw10-k8s-man-dply-cfg]
         Created [https://www.googleapis.com/compute/v1/projects/irc168976-hw10-k8s-man-dply/regions/europe-west1/addresses/hw10-k8s-kubenode-ext-ip].
         WARNING: You have selected a disk size of under [200GB]. This may result in poor I/O performance. For more information, see: https://developers.google.com/compute/docs/disks#performance.
         Created [https://www.googleapis.com/compute/v1/projects/irc168976-hw10-k8s-man-dply/zones/europe-west1-b/instances/irc168976-hw10-k8s-manual-deployment-kubenode-vm].
         WARNING: Some requests generated warnings:
         - Disk size: '25 GB' is larger than image size: '10 GB'. You might need to resize the root repartition manually if the operating system does not support automatic resizing. See https://cloud.google.com/compute/docs/disks/add-persistent-disk#resize_pd for details.
 
         NAME                                              ZONE            MACHINE_TYPE                   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP   STATUS
         irc168976-hw10-k8s-manual-deployment-kubenode-vm  europe-west1-b  custom (e2, 4 vCPU, 8.00 GiB)               10.132.0.7   34.79.109.57  RUNNING
         ```
2)  Update a local user's SSH client config file `${HOME}/.ssh/config`. Add the  `kubemaster` and `kubenode` instances connection settings to the beginning of the file:
    1) The `kubemaster` instance connection settings:
       ```config ~/.ssh/config
       # GL devops basecamp irc168976 home work 10 kubemaster instance
       Host hw10-kubemaster
       HostName 34.79.40.78
       Port 22
       User adminuser
       IdentityFile ~/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubemaster-key-ed25519.key
       IdentitiesOnly yes
       ```
    2) The `kubenode` instance connection settings:
       ```config ~/.ssh/config
       # GL devops basecamp irc168976 home work 10 kubenode instance
       Host hw10-kubenode
       HostName 34.79.109.57
       Port 22
       User adminuser
       IdentityFile ~/.ssh/adminuser@irc168976-hw10-k8s-manual-deployment-kubenode-key-ed25519.key
       IdentitiesOnly yes
       ```
3)  Download a SSH server public keys from the instances to the local user's `${HOME}/.ssh/known_hosts` file:
    * The command:
      ```bash
      ssh-keyscan 34.79.40.78 34.79.109.57 >> ${HOME}/.ssh/known_hosts
      ```
    * The output:
      ```
      # 34.79.109.57:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.5
      # 34.79.40.78:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.5
      # 34.79.40.78:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.5
      # 34.79.40.78:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.5
      # 34.79.109.57:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.5
      # 34.79.109.57:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.5
      ```
    * The `${HOME}/.ssh/known_hosts` file contents:
      ```
      34.79.109.57 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCmUtbyhDvXFmSKUCWtjYD7VCyANNfV/lmSBU88klS4AIOtmM80ZOoMRve6YMYbTzhOrEAmJT4M2x4Zm46IYQ2s=
      34.79.40.78 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxcQvZWiV6jVyLDVt5RWKdF1rfMu/OVHEINIYqyc+be3hxVO1PM+HHMXEdY++hiAUe9b7qPlAmtQixSaCktjMmA1CzxBWb3B52++FYL7WFQWPBrsUBswYDDO4HlV5IKPJCYKU/PiMhc5Cafja8FKU73pWnI9HUPDiwaorrICuP1qGM5/FspbGHlePNmWJSV4HcRMkDnq1pjuoudfOrfyMxGp8EShL/vPsVvu3GFpIinc8PGQLhO4RkwJJWBpk7ih3U+WwXjDSkjD3NKx0qZ9RIkKUGTrMcmVQiko6jRRCiSrVn/tNB/9k+2s0XL5zMqwTxN9IEe6vo9uh35ES9ZRrJr7JlHbS6pQS3HYyNbiU6RhFYtVLTaLLTNnL0C3KNriv1B5ouNPIe2AieHEi/1iBc+90yRjyIrgtsA13/fZcc8+4V/t7Ecdzqlra7k9Z4mT6sMYCcAU3QvHIrihtG+2mGxOwZ9lr9rsXe8WZdfvQbiX5ji98V4HJRWHsp4fZQV+s=
      34.79.40.78 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBG90FUEApVqOVbG7WVod7eX46PXNzmqlzYEmm4N1m3a2nmZ4bUl6vLXdt5GGXZbX59pMjCcZ+Wzd+fO+35oMy1Q=
      34.79.40.78 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGzAHc0UMdeTWr3A0xkkD+HewZv5I+w7zESJpVJ8isgi
      34.79.109.57 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIFMTWLnv8bcGZTsVUIGC9qZA1HjtTjWQ+ynJKwAmpbBIoRxry5iJ/dWOttym66wlHWpg18p09iXK5Wqrr/wdN3mkLz+2A9RcmIAA78TQSoAkG/jTA5scU4HEhkJP+dJlnE6m+swCkXN1JGx2Qrcd4kbYH/kswMBeHxUBhTLWlKeYdROWSKqVF7HkfRHPJfsm6ddo2JsgSVC51Q4oZRQEecj0ljE/+ku1J4IX2iIf1zx+/wfg1WcpHqqOAoZEilxAnoWjxgjlIh/jgoqs8dde5GQzH4qzJ4boiCPaEVy7PURpBRm8Cs81WwB/Cmb2APh1xQpu5PEwezc8AvaHxslzoL2m7GClTtLwcrpvUqaCQ4a8HcmeQ1Mz9vh5HdT18CkZ3pVQFEoIRlScgdbzakkYRTXhHyR+gM1HlZsaNzg1dq0KCDNn8es5Yc4oHt4eaciOIkFK1q3AvmLcjnjzOeL7wD4RTEK/14D1oSb9nf8agIM0xUd3qAUwfxBewuEJ9ZVc=
      34.79.109.57 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIW9hX/7nVgb4sbghIetTq+h60ib4IODBDFgSNDnV5nQ
      ```
4)  Add the `kubemaster` and `kubenode` aliases into the `/etc/host` file:
    1) The `kubemaster` instance:
       * The command:
         ```bash
         ssh hw10-kubemaster 'cat /etc/hosts && sudo sed -i '\''s/\(^127.0.0.1\s\+localhost$\)/\1\n10.132.0.6 kubemaster\n10.132.0.7 kubenode\n/'\'' /etc/hosts && printf "\n\n" && cat /etc/hosts'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         127.0.0.1 localhost

         # The following lines are desirable for IPv6 capable hosts
         ::1 ip6-localhost ip6-loopback
         fe00::0 ip6-localnet
         ff00::0 ip6-mcastprefix
         ff02::1 ip6-allnodes
         ff02::2 ip6-allrouters
         ff02::3 ip6-allhosts
         169.254.169.254 metadata.google.internal metadata
         
         
         127.0.0.1 localhost
         10.132.0.6 kubemaster
         10.132.0.7 kubenode
         
         
         # The following lines are desirable for IPv6 capable hosts
         ::1 ip6-localhost ip6-loopback
         fe00::0 ip6-localnet
         ff00::0 ip6-mcastprefix
         ff02::1 ip6-allnodes
         ff02::2 ip6-allrouters
         ff02::3 ip6-allhosts
         169.254.169.254 metadata.google.internal metadata
         ```
         </details>
    2) The `kubenode` instance:
       * The command:
         ```bash
         ssh hw10-kubenode 'cat /etc/hosts && sudo sed -i '\''s/\(^127.0.0.1\s\+localhost$\)/\1\n10.132.0.6 kubemaster\n10.132.0.7 kubenode\n/'\'' /etc/hosts && printf "\n\n" && cat /etc/hosts'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         127.0.0.1 localhost

         # The following lines are desirable for IPv6 capable hosts
         ::1 ip6-localhost ip6-loopback
         fe00::0 ip6-localnet
         ff00::0 ip6-mcastprefix
         ff02::1 ip6-allnodes
         ff02::2 ip6-allrouters
         ff02::3 ip6-allhosts
         169.254.169.254 metadata.google.internal metadata
 
 
         127.0.0.1 localhost
         10.132.0.6 kubemaster
         10.132.0.7 kubenode
 
 
         # The following lines are desirable for IPv6 capable hosts
         ::1 ip6-localhost ip6-loopback
         fe00::0 ip6-localnet
         ff00::0 ip6-mcastprefix
         ff02::1 ip6-allnodes
         ff02::2 ip6-allrouters
         ff02::3 ip6-allhosts
         169.254.169.254 metadata.google.internal metadata
         ```
         </details>
5)  Enable Kernel modules on both instances:
    1) The `kubemaster` instance:
       * The commands:
         ```bash
         ssh hw10-kubemaster 'sudo modprobe overlay && printf "Success!\n"'
         ssh hw10-kubemaster 'sudo modprobe br_netfilter && printf "Success!\n"'
         ```
       * The output:
         ```
         Success!
         Success!
         ```
    2) The `kubenode` instance:
       * The commands:
         ```
         ssh hw10-kubenode 'sudo modprobe overlay && printf "Success!\n"'
         ssh hw10-kubenode 'sudo modprobe br_netfilter && printf "Success!\n"'
         ```
       * The output:
         ```
         Success!
         Success!
         ```
6)  Add Kubernetes and Docker repository keys and repositories:
    1) The `kubemaster` instance:
       * The commands:
         ```
         ssh hw10-kubemaster 'curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -'
         ssh hw10-kubemaster 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -'
         ```
       * The output:
         ```
         Warning: apt-key output should not be parsed (stdout is not a terminal)
         OK
         Warning: apt-key output should not be parsed (stdout is not a terminal)
         OK
         ```
    2) The `kubenode` instance:
       * The commands:
         ```
         ssh hw10-kubenode 'curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -'
         ssh hw10-kubenode 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -'
         ```
       * The output:
         ```
         Warning: apt-key output should not be parsed (stdout is not a terminal)
         OK
         Warning: apt-key output should not be parsed (stdout is not a terminal)
         OK
         ```
7)  Add Kubernetes and Docker repositories:
    1) The `kubemaster` instance:
       * The command:
         ```
         ssh hw10-kubemaster 'echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list'
         ```
       * The output:
         ```
         deb https://apt.kubernetes.io/ kubernetes-xenial main
         ```
       * The command:
         ```
         ssh hw10-kubemaster 'sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         Hit:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal InRelease
         Get:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates InRelease [114 kB]
         Get:3 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports InRelease [108 kB]
         Get:4 https://download.docker.com/linux/ubuntu focal InRelease [57.7 kB]
         Get:6 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/universe amd64 Packages [8628 kB]
         Get:7 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/universe Translation-en [5124 kB]
         Get:8 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/universe amd64 c-n-f Metadata [265 kB]
         Get:9 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/multiverse amd64 Packages [144 kB]
         Get:10 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/multiverse Translation-en [104 kB]
         Get:11 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/multiverse amd64 c-n-f Metadata [9136 B]
         Get:12 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 Packages [2344 kB]
         Get:13 http://security.ubuntu.com/ubuntu focal-security InRelease [114 kB]
         Get:14 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main Translation-en [404 kB]
         Get:15 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 c-n-f Metadata [16.2 kB]
         Get:16 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/restricted amd64 Packages [1564 kB]
         Get:17 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/restricted Translation-en [221 kB]
         Get:5 https://packages.cloud.google.com/apt kubernetes-xenial InRelease [8993 B]
         Get:18 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/universe amd64 Packages [1021 kB]
         Get:19 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/universe Translation-en [236 kB]
         Get:20 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/universe amd64 c-n-f Metadata [23.4 kB]
         Get:21 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/multiverse amd64 Packages [25.2 kB]
         Get:22 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/multiverse Translation-en [7408 B]
         Get:23 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/multiverse amd64 c-n-f Metadata [604 B]
         Get:24 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports/main amd64 Packages [45.7 kB]
         Get:25 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports/main Translation-en [16.3 kB]
         Get:26 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports/main amd64 c-n-f Metadata [1420 B]
         Get:27 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports/restricted amd64 c-n-f Metadata [116 B]
         Get:28 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports/universe amd64 Packages [24.9 kB]
         Get:29 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports/universe Translation-en [16.3 kB]
         Get:30 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports/universe amd64 c-n-f Metadata [880 B]
         Get:31 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports/multiverse amd64 c-n-f Metadata [116 B]
         Get:32 https://download.docker.com/linux/ubuntu focal/stable amd64 Packages [23.3 kB]
         Get:33 http://security.ubuntu.com/ubuntu focal-security/main amd64 Packages [1968 kB]
         Get:34 http://security.ubuntu.com/ubuntu focal-security/main Translation-en [322 kB]
         Get:35 http://security.ubuntu.com/ubuntu focal-security/main amd64 c-n-f Metadata [11.9 kB]
         Get:36 http://security.ubuntu.com/ubuntu focal-security/restricted amd64 Packages [1467 kB]
         Get:37 http://security.ubuntu.com/ubuntu focal-security/restricted Translation-en [207 kB]
         Get:38 http://security.ubuntu.com/ubuntu focal-security/universe amd64 Packages [792 kB]
         Get:39 http://security.ubuntu.com/ubuntu focal-security/universe Translation-en [153 kB]
         Get:40 http://security.ubuntu.com/ubuntu focal-security/universe amd64 c-n-f Metadata [16.9 kB]
         Get:41 http://security.ubuntu.com/ubuntu focal-security/multiverse amd64 Packages [22.2 kB]
         Get:42 http://security.ubuntu.com/ubuntu focal-security/multiverse Translation-en [5464 B]
         Get:43 http://security.ubuntu.com/ubuntu focal-security/multiverse amd64 c-n-f Metadata [516 B]
         Get:44 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 Packages [63.2 kB]
         Fetched 25.7 MB in 4s (5960 kB/s)
         Reading package lists...
         ```
         </details>
    2) The `kubenode` instance:
       * The command:
         ```bash
         ssh hw10-kubenode 'echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list'
         ```
       * The output:
         ```
         deb https://apt.kubernetes.io/ kubernetes-xenial main
         ```
       * The command:
         ```bash
         ssh hw10-kubenode 'sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"'
         ```
       * The output:
         ```
         Hit:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal InRelease
         Hit:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates InRelease
         Hit:3 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports InRelease
         Hit:4 http://security.ubuntu.com/ubuntu focal-security InRelease
         Get:5 https://download.docker.com/linux/ubuntu focal InRelease [57.7 kB]
         Get:6 https://packages.cloud.google.com/apt kubernetes-xenial InRelease [8993 B]
         Get:7 https://download.docker.com/linux/ubuntu focal/stable amd64 Packages [23.3 kB]
         Get:8 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 Packages [63.2 kB]
         Fetched 153 kB in 1s (199 kB/s)
         Reading package lists...
         ```
8)  Update package lists and upgrade packages:
    1) The `kubemaster` instance:
       * The command:
         ```bash
         ssh hw10-kubemaster 'sudo apt update -y -q && sudo apt upgrade -y -q'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
 
         Hit:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal InRelease
         Get:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates InRelease [114 kB]
         Get:3 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports InRelease [108 kB]
         Hit:4 http://security.ubuntu.com/ubuntu focal-security InRelease
         Hit:5 https://download.docker.com/linux/ubuntu focal InRelease
         Hit:6 https://packages.cloud.google.com/apt kubernetes-xenial InRelease
         Fetched 222 kB in 1s (293 kB/s)
         Reading package lists...
         Building dependency tree...
         Reading state information...
         6 packages can be upgraded. Run 'apt list --upgradable' to see them.
 
         WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
 
         Reading package lists...
         Building dependency tree...
         Reading state information...
         Calculating upgrade...
         The following packages were automatically installed and are no longer required:
           libatasmart4 libblockdev-fs2 libblockdev-loop2 libblockdev-part-err2
           libblockdev-part2 libblockdev-swap2 libblockdev-utils2 libblockdev2
           libmbim-glib4 libmbim-proxy libmm-glib0 libnspr4 libnss3 libnuma1
           libparted-fs-resize0 libqmi-glib5 libqmi-proxy libudisks2-0 libxmlb2
           usb-modeswitch usb-modeswitch-data
         Use 'sudo apt autoremove' to remove them.
         #
         # News about significant security updates, features and services will
         # appear here to raise awareness and perhaps tease /r/Linux ;)
         # Use 'pro config set apt_news=false' to hide this and future APT news.
         #
         The following packages will be upgraded:
           grub-efi-amd64-bin grub-efi-amd64-signed python3-software-properties snapd
           software-properties-common ubuntu-advantage-tools
         6 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
         Need to get 41.0 MB of archives.
         After this operation, 899 kB of additional disk space will be used.
         Get:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 ubuntu-advantage-tools amd64 27.13.2~20.04.1 [173 kB]
         Get:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 grub-efi-amd64-signed amd64 1.187.2~20.04.2+2.06-2ubuntu14 [1342 kB]
         Get:3 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 grub-efi-amd64-bin amd64 2.06-2ubuntu14 [1591 kB]
         Get:4 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 software-properties-common all 0.99.9.10 [10.4 kB]
         Get:5 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 python3-software-properties all 0.99.9.10 [21.7 kB]
         Get:6 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 snapd amd64 2.58+20.04 [37.9 MB]
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         debconf: unable to initialize frontend: Readline
         debconf: (This frontend requires a controlling tty.)
         debconf: falling back to frontend: Teletype
         dpkg-preconfigure: unable to re-open stdin:
         Fetched 41.0 MB in 1s (49.1 MB/s)
         (Reading database ... 62112 files and directories currently installed.)
         Preparing to unpack .../0-ubuntu-advantage-tools_27.13.2~20.04.1_amd64.deb ...
         Unpacking ubuntu-advantage-tools (27.13.2~20.04.1) over (27.12~20.04.1) ...
         Preparing to unpack .../1-grub-efi-amd64-signed_1.187.2~20.04.2+2.06-2ubuntu14_amd64.deb ...
         Unpacking grub-efi-amd64-signed (1.187.2~20.04.2+2.06-2ubuntu14) over (1.173.4+2.04-1ubuntu47.5) ...
         Preparing to unpack .../2-grub-efi-amd64-bin_2.06-2ubuntu14_amd64.deb ...
         Unpacking grub-efi-amd64-bin (2.06-2ubuntu14) over (2.04-1ubuntu47.5) ...
         Preparing to unpack .../3-software-properties-common_0.99.9.10_all.deb ...
         Unpacking software-properties-common (0.99.9.10) over (0.99.9.8) ...
         Preparing to unpack .../4-python3-software-properties_0.99.9.10_all.deb ...
         Unpacking python3-software-properties (0.99.9.10) over (0.99.9.8) ...
         Preparing to unpack .../5-snapd_2.58+20.04_amd64.deb ...
         Unpacking snapd (2.58+20.04) over (2.57.5+20.04ubuntu0.1) ...
         Setting up snapd (2.58+20.04) ...
         Installing new version of config file /etc/apt/apt.conf.d/20snapd.conf ...
         snapd.failure.service is a disabled or a static unit not running, not starting it.
         snapd.snap-repair.service is a disabled or a static unit not running, not starting it.
         Failed to restart snapd.mounts-pre.target: Operation refused, unit snapd.mounts-pre.target may be requested by dependency only (it is configured to refuse manual start/stop).
         See system logs and 'systemctl status snapd.mounts-pre.target' for details.
         Setting up python3-software-properties (0.99.9.10) ...
         Setting up ubuntu-advantage-tools (27.13.2~20.04.1) ...
         Installing new version of config file /etc/apt/apt.conf.d/20apt-esm-hook.conf ...
         Installing new version of config file /etc/ubuntu-advantage/help_data.yaml ...
         Installing new version of config file /etc/ubuntu-advantage/uaclient.conf ...
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         Setting up grub-efi-amd64-bin (2.06-2ubuntu14) ...
         Setting up grub-efi-amd64-signed (1.187.2~20.04.2+2.06-2ubuntu14) ...
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         Trying to migrate /boot/efi into esp config
         Installing grub to /boot/efi.
         Installing for x86_64-efi platform.
         Installation finished. No error reported.
         Setting up software-properties-common (0.99.9.10) ...
         Processing triggers for mime-support (3.64ubuntu1) ...
         Processing triggers for man-db (2.9.1-1) ...
         Processing triggers for dbus (1.12.16-2ubuntu2.3) ...
         ```
         </details>
    2) The `kubenode` instance:
       * The command:
         ```bash
         ssh hw10-kubenode 'sudo apt update -y -q && sudo apt upgrade -y -q'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
 
         Hit:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal InRelease
         Hit:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates InRelease
         Hit:3 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-backports InRelease
         Hit:4 http://security.ubuntu.com/ubuntu focal-security InRelease
         Hit:5 https://download.docker.com/linux/ubuntu focal InRelease
         Hit:6 https://packages.cloud.google.com/apt kubernetes-xenial InRelease
         Reading package lists...
         Building dependency tree...
         Reading state information...
         6 packages can be upgraded. Run 'apt list --upgradable' to see them.
 
         WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
 
         Reading package lists...
         Building dependency tree...
         Reading state information...
         Calculating upgrade...
         The following packages were automatically installed and are no longer required:
           libatasmart4 libblockdev-fs2 libblockdev-loop2 libblockdev-part-err2
           libblockdev-part2 libblockdev-swap2 libblockdev-utils2 libblockdev2
           libmbim-glib4 libmbim-proxy libmm-glib0 libnspr4 libnss3 libnuma1
           libparted-fs-resize0 libqmi-glib5 libqmi-proxy libudisks2-0 libxmlb2
           usb-modeswitch usb-modeswitch-data
         Use 'sudo apt autoremove' to remove them.
         #
         # News about significant security updates, features and services will
         # appear here to raise awareness and perhaps tease /r/Linux ;)
         # Use 'pro config set apt_news=false' to hide this and future APT news.
         #
         The following packages will be upgraded:
           grub-efi-amd64-bin grub-efi-amd64-signed python3-software-properties snapd
           software-properties-common ubuntu-advantage-tools
         6 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
         Need to get 41.0 MB of archives.
         After this operation, 899 kB of additional disk space will be used.
         Get:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 ubuntu-advantage-tools amd64 27.13.2~20.04.1 [173 kB]
         Get:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 grub-efi-amd64-signed amd64 1.187.2~20.04.2+2.06-2ubuntu14 [1342 kB]
         Get:3 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 grub-efi-amd64-bin amd64 2.06-2ubuntu14 [1591 kB]
         Get:4 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 software-properties-common all 0.99.9.10 [10.4 kB]
         Get:5 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 python3-software-properties all 0.99.9.10 [21.7 kB]
         Get:6 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/main amd64 snapd amd64 2.58+20.04 [37.9 MB]
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         debconf: unable to initialize frontend: Readline
         debconf: (This frontend requires a controlling tty.)
         debconf: falling back to frontend: Teletype
         dpkg-preconfigure: unable to re-open stdin:
         Fetched 41.0 MB in 1s (58.0 MB/s)
         (Reading database ... 62112 files and directories currently installed.)
         Preparing to unpack .../0-ubuntu-advantage-tools_27.13.2~20.04.1_amd64.deb ...
         Unpacking ubuntu-advantage-tools (27.13.2~20.04.1) over (27.12~20.04.1) ...
         Preparing to unpack .../1-grub-efi-amd64-signed_1.187.2~20.04.2+2.06-2ubuntu14_amd64.deb ...
         Unpacking grub-efi-amd64-signed (1.187.2~20.04.2+2.06-2ubuntu14) over (1.173.4+2.04-1ubuntu47.5) ...
         Preparing to unpack .../2-grub-efi-amd64-bin_2.06-2ubuntu14_amd64.deb ...
         Unpacking grub-efi-amd64-bin (2.06-2ubuntu14) over (2.04-1ubuntu47.5) ...
         Preparing to unpack .../3-software-properties-common_0.99.9.10_all.deb ...
         Unpacking software-properties-common (0.99.9.10) over (0.99.9.8) ...
         Preparing to unpack .../4-python3-software-properties_0.99.9.10_all.deb ...
         Unpacking python3-software-properties (0.99.9.10) over (0.99.9.8) ...
         Preparing to unpack .../5-snapd_2.58+20.04_amd64.deb ...
         Unpacking snapd (2.58+20.04) over (2.57.5+20.04ubuntu0.1) ...
         Setting up snapd (2.58+20.04) ...
         Installing new version of config file /etc/apt/apt.conf.d/20snapd.conf ...
         snapd.failure.service is a disabled or a static unit not running, not starting it.
         snapd.snap-repair.service is a disabled or a static unit not running, not starting it.
         Failed to restart snapd.mounts-pre.target: Operation refused, unit snapd.mounts-pre.target may be requested by dependency only (it is configured to refuse manual start/stop).
         See system logs and 'systemctl status snapd.mounts-pre.target' for details.
         Setting up python3-software-properties (0.99.9.10) ...
         Setting up ubuntu-advantage-tools (27.13.2~20.04.1) ...
         Installing new version of config file /etc/apt/apt.conf.d/20apt-esm-hook.conf ...
         Installing new version of config file /etc/ubuntu-advantage/help_data.yaml ...
         Installing new version of config file /etc/ubuntu-advantage/uaclient.conf ...
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         Setting up grub-efi-amd64-bin (2.06-2ubuntu14) ...
         Setting up grub-efi-amd64-signed (1.187.2~20.04.2+2.06-2ubuntu14) ...
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         Trying to migrate /boot/efi into esp config
         Installing grub to /boot/efi.
         Installing for x86_64-efi platform.
         Installation finished. No error reported.
         Setting up software-properties-common (0.99.9.10) ...
         Processing triggers for mime-support (3.64ubuntu1) ...
         Processing triggers for man-db (2.9.1-1) ...
         Processing triggers for dbus (1.12.16-2ubuntu2.3) ...
         ```
         </details>
9)  Install necessary tools:
    1) The `kubemaster` instance:
       * The command:
         ```
         ssh hw10-kubemaster 'sudo apt install -q -y vim git curl wget gnupg2 software-properties-common apt-transport-https ca-certificates'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
         
         Reading package lists...
         Building dependency tree...
         Reading state information...
         ca-certificates is already the newest version (20211016ubuntu0.20.04.1).
         ca-certificates set to manually installed.
         curl is already the newest version (7.68.0-1ubuntu2.15).
         curl set to manually installed.
         git is already the newest version (1:2.25.1-1ubuntu3.8).
         git set to manually installed.
         software-properties-common is already the newest version (0.99.9.10).
         software-properties-common set to manually installed.
         vim is already the newest version (2:8.1.2269-1ubuntu5.11).
         vim set to manually installed.
         wget is already the newest version (1.20.3-1ubuntu2).
         wget set to manually installed.
         The following packages were automatically installed and are no longer required:
           libatasmart4 libblockdev-fs2 libblockdev-loop2 libblockdev-part-err2
           libblockdev-part2 libblockdev-swap2 libblockdev-utils2 libblockdev2
           libmbim-glib4 libmbim-proxy libmm-glib0 libnspr4 libnss3 libnuma1
           libparted-fs-resize0 libqmi-glib5 libqmi-proxy libudisks2-0 libxmlb2
           usb-modeswitch usb-modeswitch-data
         Use 'sudo apt autoremove' to remove them.
         The following NEW packages will be installed:
           apt-transport-https gnupg2
         0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
         Need to get 7020 B of archives.
         After this operation, 213 kB of additional disk space will be used.
         Get:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/universe amd64 apt-transport-https all 2.0.9 [1704 B]
         Get:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/universe amd64 gnupg2 all 2.2.19-3ubuntu2.2 [5316 B]
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         debconf: unable to initialize frontend: Readline
         debconf: (This frontend requires a controlling tty.)
         debconf: falling back to frontend: Teletype
         dpkg-preconfigure: unable to re-open stdin:
         Fetched 7020 B in 0s (193 kB/s)
         Selecting previously unselected package apt-transport-https.
         (Reading database ... 62118 files and directories currently installed.)
         Preparing to unpack .../apt-transport-https_2.0.9_all.deb ...
         Unpacking apt-transport-https (2.0.9) ...
         Selecting previously unselected package gnupg2.
         Preparing to unpack .../gnupg2_2.2.19-3ubuntu2.2_all.deb ...
         Unpacking gnupg2 (2.2.19-3ubuntu2.2) ...
         Setting up gnupg2 (2.2.19-3ubuntu2.2) ...
         Setting up apt-transport-https (2.0.9) ...
         Processing triggers for man-db (2.9.1-1) ...
         ```
         </details>
    2) The `kubenode` instance:
       * The command:
         ```
         ssh hw10-kubenode 'sudo apt install -q -y vim git curl wget gnupg2 software-properties-common apt-transport-https ca-certificates'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
 
         Reading package lists...
         Building dependency tree...
         Reading state information...
         ca-certificates is already the newest version (20211016ubuntu0.20.04.1).
         ca-certificates set to manually installed.
         curl is already the newest version (7.68.0-1ubuntu2.15).
         curl set to manually installed.
         git is already the newest version (1:2.25.1-1ubuntu3.8).
         git set to manually installed.
         software-properties-common is already the newest version (0.99.9.10).
         software-properties-common set to manually installed.
         vim is already the newest version (2:8.1.2269-1ubuntu5.11).
         vim set to manually installed.
         wget is already the newest version (1.20.3-1ubuntu2).
         wget set to manually installed.
         The following packages were automatically installed and are no longer required:
           libatasmart4 libblockdev-fs2 libblockdev-loop2 libblockdev-part-err2
           libblockdev-part2 libblockdev-swap2 libblockdev-utils2 libblockdev2
           libmbim-glib4 libmbim-proxy libmm-glib0 libnspr4 libnss3 libnuma1
           libparted-fs-resize0 libqmi-glib5 libqmi-proxy libudisks2-0 libxmlb2
           usb-modeswitch usb-modeswitch-data
         Use 'sudo apt autoremove' to remove them.
         The following NEW packages will be installed:
           apt-transport-https gnupg2
         0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
         Need to get 7020 B of archives.
         After this operation, 213 kB of additional disk space will be used.
         Get:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/universe amd64 apt-transport-https all 2.0.9 [1704 B]
         Get:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal-updates/universe amd64 gnupg2 all 2.2.19-3ubuntu2.2 [5316 B]
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         debconf: unable to initialize frontend: Readline
         debconf: (This frontend requires a controlling tty.)
         debconf: falling back to frontend: Teletype
         dpkg-preconfigure: unable to re-open stdin:
         Fetched 7020 B in 0s (197 kB/s)
         Selecting previously unselected package apt-transport-https.
         (Reading database ... 62118 files and directories currently installed.)
         Preparing to unpack .../apt-transport-https_2.0.9_all.deb ...
         Unpacking apt-transport-https (2.0.9) ...
         Selecting previously unselected package gnupg2.
         Preparing to unpack .../gnupg2_2.2.19-3ubuntu2.2_all.deb ...
         Unpacking gnupg2 (2.2.19-3ubuntu2.2) ...
         Setting up gnupg2 (2.2.19-3ubuntu2.2) ...
         Setting up apt-transport-https (2.0.9) ...
         Processing triggers for man-db (2.9.1-1) ...
         ```
         </details>
10) Disable swap:
    1) The `kubemaster` instance:
       * The command:
         ```bash
         ssh hw10-kubemaster "sudo sed -i 's/\(^.*swap.*$\)/#\1/' /etc/fstab && cat /etc/fstab && sudo swapoff -a"
         ```
       * The output:
         ```
         LABEL=cloudimg-rootfs   /        ext4   defaults        0 1
         LABEL=UEFI      /boot/efi       vfat    umask=0077      0 1
         ```
    2) The `kubenode` instance:
       * The command:
         ```bash
         ssh hw10-kubenode "sudo sed -i 's/\(^.*swap.*$\)/#\1/' /etc/fstab && cat /etc/fstab && sudo swapoff -a"
         ```
       * The output:
         ```
         LABEL=cloudimg-rootfs   /        ext4   defaults        0 1
         LABEL=UEFI      /boot/efi       vfat    umask=0077      0 1
         ```
11) Install the Kubernetes components and prevent changes of them (put them on hold)
    1) The `kubemaster` instance:
       * The command:
         ```bash
         ssh hw10-kubemaster 'sudo apt install -y -q kubelet kubeadm kubectl && sudo apt-mark hold -q kubelet kubeadm kubectl'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
 
         Reading package lists...
         Building dependency tree...
         Reading state information...
         The following packages were automatically installed and are no longer required:
           libatasmart4 libblockdev-fs2 libblockdev-loop2 libblockdev-part-err2
           libblockdev-part2 libblockdev-swap2 libblockdev-utils2 libblockdev2
           libmbim-glib4 libmbim-proxy libmm-glib0 libnspr4 libnss3 libnuma1
           libparted-fs-resize0 libqmi-glib5 libqmi-proxy libudisks2-0 libxmlb2
           usb-modeswitch usb-modeswitch-data
         Use 'sudo apt autoremove' to remove them.
         The following additional packages will be installed:
           conntrack cri-tools ebtables kubernetes-cni socat
         Suggested packages:
           nftables
         The following NEW packages will be installed:
           conntrack cri-tools ebtables kubeadm kubectl kubelet kubernetes-cni socat
         0 upgraded, 8 newly installed, 0 to remove and 0 not upgraded.
         Need to get 87.2 MB of archives.
         After this operation, 341 MB of additional disk space will be used.
         Get:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/main amd64 conntrack amd64 1:1.4.5-2 [30.3 kB]
         Get:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/main amd64 ebtables amd64 2.0.11-3build1 [80.3 kB]
         Get:3 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/main amd64 socat amd64 1.7.3.3-2 [323 kB]
         Get:4 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 cri-tools amd64 1.26.0-00 [18.9 MB]
         Get:5 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 kubernetes-cni amd64 1.2.0-00 [27.6 MB]
         Get:6 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 kubelet amd64 1.26.1-00 [20.5 MB]
         Get:7 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 kubectl amd64 1.26.1-00 [10.1 MB]
         Get:8 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 kubeadm amd64 1.26.1-00 [9732 kB]
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         debconf: unable to initialize frontend: Readline
         debconf: (This frontend requires a controlling tty.)
         debconf: falling back to frontend: Teletype
         dpkg-preconfigure: unable to re-open stdin:
         Fetched 87.2 MB in 9s (10.1 MB/s)
         Selecting previously unselected package conntrack.
         (Reading database ... 62128 files and directories currently installed.)
         Preparing to unpack .../0-conntrack_1%3a1.4.5-2_amd64.deb ...
         Unpacking conntrack (1:1.4.5-2) ...
         Selecting previously unselected package cri-tools.
         Preparing to unpack .../1-cri-tools_1.26.0-00_amd64.deb ...
         Unpacking cri-tools (1.26.0-00) ...
         Selecting previously unselected package ebtables.
         Preparing to unpack .../2-ebtables_2.0.11-3build1_amd64.deb ...
         Unpacking ebtables (2.0.11-3build1) ...
         Selecting previously unselected package kubernetes-cni.
         Preparing to unpack .../3-kubernetes-cni_1.2.0-00_amd64.deb ...
         Unpacking kubernetes-cni (1.2.0-00) ...
         Selecting previously unselected package socat.
         Preparing to unpack .../4-socat_1.7.3.3-2_amd64.deb ...
         Unpacking socat (1.7.3.3-2) ...
         Selecting previously unselected package kubelet.
         Preparing to unpack .../5-kubelet_1.26.1-00_amd64.deb ...
         Unpacking kubelet (1.26.1-00) ...
         Selecting previously unselected package kubectl.
         Preparing to unpack .../6-kubectl_1.26.1-00_amd64.deb ...
         Unpacking kubectl (1.26.1-00) ...
         Selecting previously unselected package kubeadm.
         Preparing to unpack .../7-kubeadm_1.26.1-00_amd64.deb ...
         Unpacking kubeadm (1.26.1-00) ...
         Setting up conntrack (1:1.4.5-2) ...
         Setting up kubectl (1.26.1-00) ...
         Setting up ebtables (2.0.11-3build1) ...
         Setting up socat (1.7.3.3-2) ...
         Setting up cri-tools (1.26.0-00) ...
         Setting up kubernetes-cni (1.2.0-00) ...
         Setting up kubelet (1.26.1-00) ...
         Created symlink /etc/systemd/system/multi-user.target.wants/kubelet.service → /lib/systemd/system/kubelet.service.
         Setting up kubeadm (1.26.1-00) ...
         Processing triggers for man-db (2.9.1-1) ...
         kubelet set on hold.
         kubeadm set on hold.
         kubectl set on hold.
         ```
         </details>
    2) The `kubenode` instance:
       * The command:
         ```bash
         ssh hw10-kubenode 'sudo apt install -y -q kubelet kubeadm kubectl && sudo apt-mark hold -q kubelet kubeadm kubectl'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
         
         Reading package lists...
         Building dependency tree...
         Reading state information...
         The following packages were automatically installed and are no longer required:
           libatasmart4 libblockdev-fs2 libblockdev-loop2 libblockdev-part-err2
           libblockdev-part2 libblockdev-swap2 libblockdev-utils2 libblockdev2
           libmbim-glib4 libmbim-proxy libmm-glib0 libnspr4 libnss3 libnuma1
           libparted-fs-resize0 libqmi-glib5 libqmi-proxy libudisks2-0 libxmlb2
           usb-modeswitch usb-modeswitch-data
         Use 'sudo apt autoremove' to remove them.
         The following additional packages will be installed:
           conntrack cri-tools ebtables kubernetes-cni socat
         Suggested packages:
           nftables
         The following NEW packages will be installed:
           conntrack cri-tools ebtables kubeadm kubectl kubelet kubernetes-cni socat
         0 upgraded, 8 newly installed, 0 to remove and 0 not upgraded.
         Need to get 87.2 MB of archives.
         After this operation, 341 MB of additional disk space will be used.
         Get:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/main amd64 conntrack amd64 1:1.4.5-2 [30.3 kB]
         Get:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/main amd64 ebtables amd64 2.0.11-3build1 [80.3 kB]
         Get:3 http://europe-west1.gce.archive.ubuntu.com/ubuntu focal/main amd64 socat amd64 1.7.3.3-2 [323 kB]
         Get:4 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 cri-tools amd64 1.26.0-00 [18.9 MB]
         Get:5 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 kubernetes-cni amd64 1.2.0-00 [27.6 MB]
         Get:6 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 kubelet amd64 1.26.1-00 [20.5 MB]
         Get:7 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 kubectl amd64 1.26.1-00 [10.1 MB]
         Get:8 https://packages.cloud.google.com/apt kubernetes-xenial/main amd64 kubeadm amd64 1.26.1-00 [9732 kB]
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         debconf: unable to initialize frontend: Readline
         debconf: (This frontend requires a controlling tty.)
         debconf: falling back to frontend: Teletype
         dpkg-preconfigure: unable to re-open stdin:
         Fetched 87.2 MB in 2s (42.4 MB/s)
         Selecting previously unselected package conntrack.
         (Reading database ... 62128 files and directories currently installed.)
         Preparing to unpack .../0-conntrack_1%3a1.4.5-2_amd64.deb ...
         Unpacking conntrack (1:1.4.5-2) ...
         Selecting previously unselected package cri-tools.
         Preparing to unpack .../1-cri-tools_1.26.0-00_amd64.deb ...
         Unpacking cri-tools (1.26.0-00) ...
         Selecting previously unselected package ebtables.
         Preparing to unpack .../2-ebtables_2.0.11-3build1_amd64.deb ...
         Unpacking ebtables (2.0.11-3build1) ...
         Selecting previously unselected package kubernetes-cni.
         Preparing to unpack .../3-kubernetes-cni_1.2.0-00_amd64.deb ...
         Unpacking kubernetes-cni (1.2.0-00) ...
         Selecting previously unselected package socat.
         Preparing to unpack .../4-socat_1.7.3.3-2_amd64.deb ...
         Unpacking socat (1.7.3.3-2) ...
         Selecting previously unselected package kubelet.
         Preparing to unpack .../5-kubelet_1.26.1-00_amd64.deb ...
         Unpacking kubelet (1.26.1-00) ...
         Selecting previously unselected package kubectl.
         Preparing to unpack .../6-kubectl_1.26.1-00_amd64.deb ...
         Unpacking kubectl (1.26.1-00) ...
         Selecting previously unselected package kubeadm.
         Preparing to unpack .../7-kubeadm_1.26.1-00_amd64.deb ...
         Unpacking kubeadm (1.26.1-00) ...
         Setting up conntrack (1:1.4.5-2) ...
         Setting up kubectl (1.26.1-00) ...
         Setting up ebtables (2.0.11-3build1) ...
         Setting up socat (1.7.3.3-2) ...
         Setting up cri-tools (1.26.0-00) ...
         Setting up kubernetes-cni (1.2.0-00) ...
         Setting up kubelet (1.26.1-00) ...
         Created symlink /etc/systemd/system/multi-user.target.wants/kubelet.service → /lib/systemd/system/kubelet.service.
         Setting up kubeadm (1.26.1-00) ...
         Processing triggers for man-db (2.9.1-1) ...
         kubelet set on hold.
         kubeadm set on hold.
         kubectl set on hold.
         ```
         </details>
12) Install the `containerd`:
    1) The `kubemaster` instance:
       * The command:
         ```bash
         ssh hw10-kubemaster 'sudo apt install -y -q containerd.io'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
         
         Reading package lists...
         Building dependency tree...
         Reading state information...
         The following packages were automatically installed and are no longer required:
           libatasmart4 libblockdev-fs2 libblockdev-loop2 libblockdev-part-err2
           libblockdev-part2 libblockdev-swap2 libblockdev-utils2 libblockdev2
           libmbim-glib4 libmbim-proxy libmm-glib0 libnspr4 libnss3 libnuma1
           libparted-fs-resize0 libqmi-glib5 libqmi-proxy libudisks2-0 libxmlb2
           usb-modeswitch usb-modeswitch-data
         Use 'sudo apt autoremove' to remove them.
         The following NEW packages will be installed:
           containerd.io
         0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
         Need to get 27.7 MB of archives.
         After this operation, 114 MB of additional disk space will be used.
         Get:1 https://download.docker.com/linux/ubuntu focal/stable amd64 containerd.io amd64 1.6.16-1 [27.7 MB]
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         debconf: unable to initialize frontend: Readline
         debconf: (This frontend requires a controlling tty.)
         debconf: falling back to frontend: Teletype
         dpkg-preconfigure: unable to re-open stdin:
         Fetched 27.7 MB in 1s (18.7 MB/s)
         Selecting previously unselected package containerd.io.
         (Reading database ... 62222 files and directories currently installed.)
         Preparing to unpack .../containerd.io_1.6.16-1_amd64.deb ...
         Unpacking containerd.io (1.6.16-1) ...
         Setting up containerd.io (1.6.16-1) ...
         Created symlink /etc/systemd/system/multi-user.target.wants/containerd.service → /lib/systemd/system/containerd.service.
         Processing triggers for man-db (2.9.1-1) ...
         ```
         </details>
    2) The `kubenode` instance:
       * The command:
         ```bash
         ssh hw10-kubenode 'sudo apt install -y -q containerd.io'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
         
         Reading package lists...
         Building dependency tree...
         Reading state information...
         The following packages were automatically installed and are no longer required:
           libatasmart4 libblockdev-fs2 libblockdev-loop2 libblockdev-part-err2
           libblockdev-part2 libblockdev-swap2 libblockdev-utils2 libblockdev2
           libmbim-glib4 libmbim-proxy libmm-glib0 libnspr4 libnss3 libnuma1
           libparted-fs-resize0 libqmi-glib5 libqmi-proxy libudisks2-0 libxmlb2
           usb-modeswitch usb-modeswitch-data
         Use 'sudo apt autoremove' to remove them.
         The following NEW packages will be installed:
           containerd.io
         0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
         Need to get 27.7 MB of archives.
         After this operation, 114 MB of additional disk space will be used.
         Get:1 https://download.docker.com/linux/ubuntu focal/stable amd64 containerd.io amd64 1.6.16-1 [27.7 MB]
         debconf: unable to initialize frontend: Dialog
         debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
         debconf: falling back to frontend: Readline
         debconf: unable to initialize frontend: Readline
         debconf: (This frontend requires a controlling tty.)
         debconf: falling back to frontend: Teletype
         dpkg-preconfigure: unable to re-open stdin:
         Fetched 27.7 MB in 2s (16.0 MB/s)
         Selecting previously unselected package containerd.io.
         (Reading database ... 62222 files and directories currently installed.)
         Preparing to unpack .../containerd.io_1.6.16-1_amd64.deb ...
         Unpacking containerd.io (1.6.16-1) ...
         Setting up containerd.io (1.6.16-1) ...
         Created symlink /etc/systemd/system/multi-user.target.wants/containerd.service → /lib/systemd/system/containerd.service.
         Processing triggers for man-db (2.9.1-1) ...
         ```
         </details>
13) Configure the `containerd`:
    1) Create a new directory for the `containerd` and generate the configuration file for it:
       1) The `kubemaster` instance:
          * The command:
            ```bash
            ssh hw10-kubemaster 'sudo mkdir -p /etc/containerd && sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null && sudo ls -l /etc/containerd/config.toml'
            ```
          * The output:
            ```
            -rw-r--r-- 1 root root 6994 Jan 31 20:38 /etc/containerd/config.toml
            ```
       2) The `kubenode` instance:
          * The command:
            ```bash
            ssh hw10-kubenode 'sudo mkdir -p /etc/containerd && sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null && sudo ls -l /etc/containerd/config.toml'
            ```
          * The output:
            ```
            -rw-r--r-- 1 root root 6994 Jan 31 20:42 /etc/containerd/config.toml
            ```
    2) Restart the containerd service and enable it to run at startup: 
       1) The `kubemaster` instance:
          * The command:
            ```bash
            ssh hw10-kubemaster 'sudo systemctl restart containerd && sudo systemctl enable containerd && sudo systemctl status containerd'
            ```
          * The output:
            ```
            ● containerd.service - containerd container runtime
                Loaded: loaded (/lib/systemd/system/containerd.service; enabled; vendor preset: enabled)
                Active: active (running) since Tue 2023-01-31 20:46:01 UTC; 318ms ago
                  Docs: https://containerd.io
              Main PID: 9048 (containerd)
                  Tasks: 11
                Memory: 13.3M
                CGroup: /system.slice/containerd.service
                        └─9048 /usr/bin/containerd
 
            Jan 31 20:46:01 irc168976-hw10-k8s-manual-deployment-kubemaster-vm containerd[9048]: time="2023-01-31T20:46:01.197510063Z" level=info msg="Start subscribing containerd event"
            Jan 31 20:46:01 irc168976-hw10-k8s-manual-deployment-kubemaster-vm containerd[9048]: time="2023-01-31T20:46:01.197598919Z" level=info msg="Start recovering state"
            Jan 31 20:46:01 irc168976-hw10-k8s-manual-deployment-kubemaster-vm containerd[9048]: time="2023-01-31T20:46:01.197680987Z" level=info msg="Start event monitor"
            Jan 31 20:46:01 irc168976-hw10-k8s-manual-deployment-kubemaster-vm containerd[9048]: time="2023-01-31T20:46:01.197708397Z" level=info msg="Start snapshots syncer"
            Jan 31 20:46:01 irc168976-hw10-k8s-manual-deployment-kubemaster-vm containerd[9048]: time="2023-01-31T20:46:01.197720474Z" level=info msg="Start cni network conf syncer for default"
            Jan 31 20:46:01 irc168976-hw10-k8s-manual-deployment-kubemaster-vm containerd[9048]: time="2023-01-31T20:46:01.197728739Z" level=info msg="Start streaming server"
            Jan 31 20:46:01 irc168976-hw10-k8s-manual-deployment-kubemaster-vm containerd[9048]: time="2023-01-31T20:46:01.197763000Z" level=info msg=serving... address=/run/containerd/containerd.sock.ttrpc
            Jan 31 20:46:01 irc168976-hw10-k8s-manual-deployment-kubemaster-vm containerd[9048]: time="2023-01-31T20:46:01.197838092Z" level=info msg=serving... address=/run/containerd/containerd.sock
            Jan 31 20:46:01 irc168976-hw10-k8s-manual-deployment-kubemaster-vm systemd[1]: Started containerd container runtime.
            Jan 31 20:46:01 irc168976-hw10-k8s-manual-deployment-kubemaster-vm containerd[9048]: time="2023-01-31T20:46:01.202383737Z" level=info msg="containerd successfully booted in 0.034209s"
            ```
       2) The `kubenode` instance:
          * The command:
            ```bash
            ssh hw10-kubenode 'sudo systemctl restart containerd && sudo systemctl enable containerd && sudo systemctl status containerd'
            ```
          * The output:
            ```
            ● containerd.service - containerd container runtime
                Loaded: loaded (/lib/systemd/system/containerd.service; enabled; vendor preset: enabled)
                Active: active (running) since Tue 2023-01-31 20:47:31 UTC; 319ms ago
                  Docs: https://containerd.io
              Main PID: 9278 (containerd)
                  Tasks: 11
                Memory: 12.7M
                CGroup: /system.slice/containerd.service
                        └─9278 /usr/bin/containerd

            Jan 31 20:47:31 irc168976-hw10-k8s-manual-deployment-kubenode-vm containerd[9278]: time="2023-01-31T20:47:31.938395915Z" level=info msg="Start subscribing containerd event"
            Jan 31 20:47:31 irc168976-hw10-k8s-manual-deployment-kubenode-vm containerd[9278]: time="2023-01-31T20:47:31.938494076Z" level=info msg="Start recovering state"
            Jan 31 20:47:31 irc168976-hw10-k8s-manual-deployment-kubenode-vm containerd[9278]: time="2023-01-31T20:47:31.938661985Z" level=info msg="Start event monitor"
            Jan 31 20:47:31 irc168976-hw10-k8s-manual-deployment-kubenode-vm containerd[9278]: time="2023-01-31T20:47:31.938748639Z" level=info msg="Start snapshots syncer"
            Jan 31 20:47:31 irc168976-hw10-k8s-manual-deployment-kubenode-vm containerd[9278]: time="2023-01-31T20:47:31.938769661Z" level=info msg="Start cni network conf syncer for default"
            Jan 31 20:47:31 irc168976-hw10-k8s-manual-deployment-kubenode-vm containerd[9278]: time="2023-01-31T20:47:31.938788528Z" level=info msg="Start streaming server"
            Jan 31 20:47:31 irc168976-hw10-k8s-manual-deployment-kubenode-vm containerd[9278]: time="2023-01-31T20:47:31.939110111Z" level=info msg=serving... address=/run/containerd/containerd.sock.ttrpc
            Jan 31 20:47:31 irc168976-hw10-k8s-manual-deployment-kubenode-vm containerd[9278]: time="2023-01-31T20:47:31.939451859Z" level=info msg=serving... address=/run/containerd/containerd.sock
            Jan 31 20:47:31 irc168976-hw10-k8s-manual-deployment-kubenode-vm systemd[1]: Started containerd container runtime.
            Jan 31 20:47:31 irc168976-hw10-k8s-manual-deployment-kubenode-vm containerd[9278]: time="2023-01-31T20:47:31.942306489Z" level=info msg="containerd successfully booted in 0.033987s"
            ```
14) Start and enable the `kubelet` service:
    1) The `kubemaster` instance:
       * The command:
         ```bash
         ssh hw10-kubemaster 'sudo systemctl enable --now kubelet && sudo systemctl status kubelet'
         ```
       * The output:
         ```
         ● kubelet.service - kubelet: The Kubernetes Node Agent
              Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
             Drop-In: /etc/systemd/system/kubelet.service.d
                      └─10-kubeadm.conf
              Active: active (running) since Tue 2023-01-31 20:53:30 UTC; 23ms ago
                Docs: https://kubernetes.io/docs/home/
            Main PID: 9619 (kubelet)
               Tasks: 6 (limit: 9525)
              Memory: 4.4M
              CGroup: /system.slice/kubelet.service
                      └─9619 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml
         
         Jan 31 20:53:30 irc168976-hw10-k8s-manual-deployment-kubemaster-vm systemd[1]: Started kubelet: The Kubernetes Node Agent.
         ```
    2) The `kubenode` instance:
       * The command:
         ```bash
         ssh hw10-kubenode 'sudo systemctl enable --now kubelet && sudo systemctl status kubelet'
         ```
       * The output:
         ```
         ● kubelet.service - kubelet: The Kubernetes Node Agent
             Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
             Drop-In: /etc/systemd/system/kubelet.service.d
                     └─10-kubeadm.conf
             Active: active (running) since Tue 2023-01-31 20:54:41 UTC; 24ms ago
               Docs: https://kubernetes.io/docs/home/
           Main PID: 9779 (kubelet)
               Tasks: 7 (limit: 9525)
             Memory: 4.9M
             CGroup: /system.slice/kubelet.service
                     └─9779 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml
 
         Jan 31 20:54:41 irc168976-hw10-k8s-manual-deployment-kubenode-vm systemd[1]: Started kubelet: The Kubernetes Node Agent.
         ```
15) Check the `sysctl` settings in the `/etc/sysctl.d/kubernetes.conf` file that their values are as expected and reload `sysctl` after tuning them as necessary:
    1) Expected properties and values are as follows:
       ```conf /etc/sysctl.d/kubernetes.conf
       net.bridge.bridge-nf-call-ip6tables = 1
       net.bridge.bridge-nf-call-iptables = 1
       net.ipv4.ip_forward = 1
    2) Check the content of the `/etc/sysctl.d/kubernetes.conf` file:
       1) The `kubemaster` instance:
          * The command:
            ```bash
            ssh hw10-kubemaster 'if [[ -f /etc/sysctl.d/kubernetes.conf ]] ; then sudo grep --fixed-strings "$(printf '\''net.bridge.bridge-nf-call-ip6tables\nnet.bridge.bridge-nf-call-iptables\nnet.ipv4.ip_forward\n'\'')" /etc/sysctl.d/kubernetes.conf ; else printf "The file /etc/sysctl.d/kubernetes.conf does not exist\n" ; fi'
            ```
          * The output:
            ```
            The file /etc/sysctl.d/kubernetes.conf does not exist
            ```
       2) The `kubenode` instance:
          * The command:
            ```bash
            ssh hw10-kubenode 'if [[ -f /etc/sysctl.d/kubernetes.conf ]] ; then sudo grep --fixed-strings "$(printf '\''net.bridge.bridge-nf-call-ip6tables\nnet.bridge.bridge-nf-call-iptables\nnet.ipv4.ip_forward\n'\'')" /etc/sysctl.d/kubernetes.conf ; else printf "The file /etc/sysctl.d/kubernetes.conf does not exist\n" ; fi'
            ```
          * The output:
            ```
            The file /etc/sysctl.d/kubernetes.conf does not exist
            ```
    3) Create the `/etc/sysctl.d/kubernetes.conf` file with required content:
       1) The `kubemaster` instance:
          * The command:
            ```bash
            ssh hw10-kubemaster 'printf "net.bridge.bridge-nf-call-ip6tables=1\nnet.bridge.bridge-nf-call-iptables=1\nnet.ipv4.ip_forward=1\n" | sudo tee /etc/sysctl.d/kubernetes.conf && ls -l /etc/sysctl.d/kubernetes.conf'
            ```
          * The output:
            ```
            net.bridge.bridge-nf-call-ip6tables=1
            net.bridge.bridge-nf-call-iptables=1
            net.ipv4.ip_forward=1
            -rw-r--r-- 1 root root 97 Jan 31 21:13 /etc/sysctl.d/kubernetes.conf
            ```
       2) The `kubenode` instance:
          * The command:
            ```bash
            ssh hw10-kubenode 'printf "net.bridge.bridge-nf-call-ip6tables=1\nnet.bridge.bridge-nf-call-iptables=1\nnet.ipv4.ip_forward=1\n" | sudo tee /etc/sysctl.d/kubernetes.conf && ls -l /etc/sysctl.d/kubernetes.conf'
            ```
          * The output:
            ```
            net.bridge.bridge-nf-call-ip6tables=1
            net.bridge.bridge-nf-call-iptables=1
            net.ipv4.ip_forward=1
            -rw-r--r-- 1 root root 97 Jan 31 21:14 /etc/sysctl.d/kubernetes.conf
            ```
    4) Reload `sysctl`:
       1) The `kubemaster` instance:
          * The command:
            ```bash
            ssh hw10-kubemaster 'sudo sysctl --system'
            ```
          * The output: (tl/dr) <details><summary>Show details</summary>
            ```
            * Applying /etc/sysctl.d/10-console-messages.conf ...
            kernel.printk = 4 4 1 7
            * Applying /etc/sysctl.d/10-ipv6-privacy.conf ...
            net.ipv6.conf.all.use_tempaddr = 2
            net.ipv6.conf.default.use_tempaddr = 2
            * Applying /etc/sysctl.d/10-kernel-hardening.conf ...
            kernel.kptr_restrict = 1
            * Applying /etc/sysctl.d/10-link-restrictions.conf ...
            fs.protected_hardlinks = 1
            fs.protected_symlinks = 1
            * Applying /etc/sysctl.d/10-magic-sysrq.conf ...
            kernel.sysrq = 176
            * Applying /etc/sysctl.d/10-network-security.conf ...
            net.ipv4.conf.default.rp_filter = 2
            net.ipv4.conf.all.rp_filter = 2
            * Applying /etc/sysctl.d/10-ptrace.conf ...
            kernel.yama.ptrace_scope = 1
            * Applying /etc/sysctl.d/10-zeropage.conf ...
            vm.mmap_min_addr = 65536
            * Applying /usr/lib/sysctl.d/50-default.conf ...
            net.ipv4.conf.default.promote_secondaries = 1
            net.ipv4.ping_group_range = 0 2147483647
            net.core.default_qdisc = fq_codel
            fs.protected_regular = 1
            fs.protected_fifos = 1
            * Applying /usr/lib/sysctl.d/50-pid-max.conf ...
            kernel.pid_max = 4194304
            * Applying /etc/sysctl.d/60-gce-network-security.conf ...
            net.ipv4.tcp_syncookies = 1
            net.ipv4.conf.all.accept_source_route = 0
            net.ipv4.conf.default.accept_source_route = 0
            net.ipv4.conf.all.accept_redirects = 0
            net.ipv4.conf.default.accept_redirects = 0
            net.ipv4.conf.all.secure_redirects = 1
            net.ipv4.conf.default.secure_redirects = 1
            net.ipv4.ip_forward = 0
            net.ipv4.conf.all.send_redirects = 0
            net.ipv4.conf.default.send_redirects = 0
            net.ipv4.conf.all.rp_filter = 1
            net.ipv4.conf.default.rp_filter = 1
            net.ipv4.icmp_echo_ignore_broadcasts = 1
            net.ipv4.icmp_ignore_bogus_error_responses = 1
            net.ipv4.conf.all.log_martians = 1
            net.ipv4.conf.default.log_martians = 1
            kernel.randomize_va_space = 2
            kernel.panic = 10
            * Applying /etc/sysctl.d/99-cloudimg-ipv6.conf ...
            net.ipv6.conf.all.use_tempaddr = 0
            net.ipv6.conf.default.use_tempaddr = 0
            * Applying /etc/sysctl.d/99-sysctl.conf ...
            * Applying /etc/sysctl.d/kubernetes.conf ...
            net.bridge.bridge-nf-call-ip6tables = 1
            net.bridge.bridge-nf-call-iptables = 1
            net.ipv4.ip_forward = 1
            * Applying /usr/lib/sysctl.d/protect-links.conf ...
            fs.protected_fifos = 1
            fs.protected_hardlinks = 1
            fs.protected_regular = 2
            fs.protected_symlinks = 1
            * Applying /etc/sysctl.conf ...
            sysctl: setting key "net.ipv4.conf.all.promote_secondaries": Invalid argument
            ```
            </details>
       2) The `kubenode` instance:
          * The command:
            ```bash
            ssh hw10-kubenode 'sudo sysctl --system'
            ```
          * The output: (tl/dr) <details><summary>Show details</summary>
            ```
            * Applying /etc/sysctl.d/10-console-messages.conf ...
            kernel.printk = 4 4 1 7
            * Applying /etc/sysctl.d/10-ipv6-privacy.conf ...
            net.ipv6.conf.all.use_tempaddr = 2
            net.ipv6.conf.default.use_tempaddr = 2
            * Applying /etc/sysctl.d/10-kernel-hardening.conf ...
            kernel.kptr_restrict = 1
            * Applying /etc/sysctl.d/10-link-restrictions.conf ...
            fs.protected_hardlinks = 1
            fs.protected_symlinks = 1
            * Applying /etc/sysctl.d/10-magic-sysrq.conf ...
            kernel.sysrq = 176
            * Applying /etc/sysctl.d/10-network-security.conf ...
            net.ipv4.conf.default.rp_filter = 2
            net.ipv4.conf.all.rp_filter = 2
            * Applying /etc/sysctl.d/10-ptrace.conf ...
            kernel.yama.ptrace_scope = 1
            * Applying /etc/sysctl.d/10-zeropage.conf ...
            vm.mmap_min_addr = 65536
            * Applying /usr/lib/sysctl.d/50-default.conf ...
            net.ipv4.conf.default.promote_secondaries = 1
            net.ipv4.ping_group_range = 0 2147483647
            net.core.default_qdisc = fq_codel
            fs.protected_regular = 1
            fs.protected_fifos = 1
            * Applying /usr/lib/sysctl.d/50-pid-max.conf ...
            kernel.pid_max = 4194304
            * Applying /etc/sysctl.d/60-gce-network-security.conf ...
            net.ipv4.tcp_syncookies = 1
            net.ipv4.conf.all.accept_source_route = 0
            net.ipv4.conf.default.accept_source_route = 0
            net.ipv4.conf.all.accept_redirects = 0
            net.ipv4.conf.default.accept_redirects = 0
            net.ipv4.conf.all.secure_redirects = 1
            net.ipv4.conf.default.secure_redirects = 1
            net.ipv4.ip_forward = 0
            net.ipv4.conf.all.send_redirects = 0
            net.ipv4.conf.default.send_redirects = 0
            net.ipv4.conf.all.rp_filter = 1
            net.ipv4.conf.default.rp_filter = 1
            net.ipv4.icmp_echo_ignore_broadcasts = 1
            net.ipv4.icmp_ignore_bogus_error_responses = 1
            net.ipv4.conf.all.log_martians = 1
            net.ipv4.conf.default.log_martians = 1
            kernel.randomize_va_space = 2
            kernel.panic = 10
            * Applying /etc/sysctl.d/99-cloudimg-ipv6.conf ...
            net.ipv6.conf.all.use_tempaddr = 0
            net.ipv6.conf.default.use_tempaddr = 0
            * Applying /etc/sysctl.d/99-sysctl.conf ...
            * Applying /etc/sysctl.d/kubernetes.conf ...
            net.bridge.bridge-nf-call-ip6tables = 1
            net.bridge.bridge-nf-call-iptables = 1
            net.ipv4.ip_forward = 1
            * Applying /usr/lib/sysctl.d/protect-links.conf ...
            fs.protected_fifos = 1
            fs.protected_hardlinks = 1
            fs.protected_regular = 2
            fs.protected_symlinks = 1
            * Applying /etc/sysctl.conf ...
            sysctl: setting key "net.ipv4.conf.all.promote_secondaries": Invalid argument
            ```
            </details>
16) Pull down the necessary container images:
    1) The `kubemaster` instance:
       * The command:
         ```bash
         ssh hw10-kubemaster 'sudo kubeadm config images pull'
         ```
       * The output:
         ```
         [config/images] Pulled registry.k8s.io/kube-apiserver:v1.26.1
         [config/images] Pulled registry.k8s.io/kube-controller-manager:v1.26.1
         [config/images] Pulled registry.k8s.io/kube-scheduler:v1.26.1
         [config/images] Pulled registry.k8s.io/kube-proxy:v1.26.1
         [config/images] Pulled registry.k8s.io/pause:3.9
         [config/images] Pulled registry.k8s.io/etcd:3.5.6-0
         [config/images] Pulled registry.k8s.io/coredns/coredns:v1.9.3
         ```
    2) The `kubenode` instance:
       * The command:
         ```bash
         ssh hw10-kubenode 'sudo kubeadm config images pull'
         ```
       * The output:
         ```
         [config/images] Pulled registry.k8s.io/kube-apiserver:v1.26.1
         [config/images] Pulled registry.k8s.io/kube-controller-manager:v1.26.1
         [config/images] Pulled registry.k8s.io/kube-scheduler:v1.26.1
         [config/images] Pulled registry.k8s.io/kube-proxy:v1.26.1
         [config/images] Pulled registry.k8s.io/pause:3.9
         [config/images] Pulled registry.k8s.io/etcd:3.5.6-0
         [config/images] Pulled registry.k8s.io/coredns/coredns:v1.9.3
         ```
17) Initialize the **master** node by performing such actions on the `kubemaster` instance only:
    1) Initialize the Kubernetes control-plane with the following command:
       * The command:
         ```bash
         ssh hw10-kubemaster 'sudo kubeadm init --pod-network-cidr=192.168.0.0/16'
         ```
       * The output: (tl/dr) <details><summary>Show details</summary>
         ```
         [init] Using Kubernetes version: v1.26.1
         [preflight] Running pre-flight checks
         [preflight] Pulling images required for setting up a Kubernetes cluster
         [preflight] This might take a minute or two, depending on the speed of your internet connection
         [preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
         [certs] Using certificateDir folder "/etc/kubernetes/pki"
         [certs] Generating "ca" certificate and key
         [certs] Generating "apiserver" certificate and key
         [certs] apiserver serving cert is signed for DNS names [irc168976-hw10-k8s-manual-deployment-kubemaster-vm kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.132.0.6]
         [certs] Generating "apiserver-kubelet-client" certificate and key
         [certs] Generating "front-proxy-ca" certificate and key
         [certs] Generating "front-proxy-client" certificate and key
         [certs] Generating "etcd/ca" certificate and key
         [certs] Generating "etcd/server" certificate and key
         [certs] etcd/server serving cert is signed for DNS names [irc168976-hw10-k8s-manual-deployment-kubemaster-vm localhost] and IPs [10.132.0.6 127.0.0.1 ::1]
         [certs] Generating "etcd/peer" certificate and key
         [certs] etcd/peer serving cert is signed for DNS names [irc168976-hw10-k8s-manual-deployment-kubemaster-vm localhost] and IPs [10.132.0.6 127.0.0.1 ::1]
         [certs] Generating "etcd/healthcheck-client" certificate and key
         [certs] Generating "apiserver-etcd-client" certificate and key
         [certs] Generating "sa" key and public key
         [kubeconfig] Using kubeconfig folder "/etc/kubernetes"
         [kubeconfig] Writing "admin.conf" kubeconfig file
         [kubeconfig] Writing "kubelet.conf" kubeconfig file
         [kubeconfig] Writing "controller-manager.conf" kubeconfig file
         [kubeconfig] Writing "scheduler.conf" kubeconfig file
         [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
         [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
         [kubelet-start] Starting the kubelet
         [control-plane] Using manifest folder "/etc/kubernetes/manifests"
         [control-plane] Creating static Pod manifest for "kube-apiserver"
         [control-plane] Creating static Pod manifest for "kube-controller-manager"
         [control-plane] Creating static Pod manifest for "kube-scheduler"
         [etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
         [wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
         [apiclient] All control plane components are healthy after 12.502638 seconds
         [upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
         [kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
         [upload-certs] Skipping phase. Please see --upload-certs
         [mark-control-plane] Marking the node irc168976-hw10-k8s-manual-deployment-kubemaster-vm as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
         [mark-control-plane] Marking the node irc168976-hw10-k8s-manual-deployment-kubemaster-vm as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
         [bootstrap-token] Using token: hytykz.ykpsrke4hd4g1w68
         [bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
         [bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
         [bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
         [bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
         [bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
         [bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
         [kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
         [addons] Applied essential addon: CoreDNS
         [addons] Applied essential addon: kube-proxy
 
         Your Kubernetes control-plane has initialized successfully!
 
         To start using your cluster, you need to run the following as a regular user:
 
           mkdir -p $HOME/.kube
           sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
           sudo chown $(id -u):$(id -g) $HOME/.kube/config
 
         Alternatively, if you are the root user, you can run:
 
           export KUBECONFIG=/etc/kubernetes/admin.conf
 
         You should now deploy a pod network to the cluster.
         Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
           https://kubernetes.io/docs/concepts/cluster-administration/addons/
 
         Then you can join any number of worker nodes by running the following on each as root:
 
         kubeadm join 10.132.0.6:6443 --token hytykz.ykpsrke4hd4g1w68 \
                 --discovery-token-ca-cert-hash sha256:fd67ad420dd59883eab431a81e1a563a9a0e04f1dfab6f34f984ce17a053f07a
         ```
         </details>
    2) Create a new directory to house a personal configuration file for the deployed cluster, copy it there from `/etc/kubernetes/admin.conf` and give it the proper permissions using the following command:
       * The command
         ```
         ssh hw10-kubemaster 'mkdir -p ${HOME}/.kube && sudo cp -f /etc/kubernetes/admin.conf ${HOME}/.kube/config && sudo chown $(id -u):$(id -g) ${HOME}/.kube/config && ls -l ${HOME}/.kube/config'

         ```
       * The output:
         ```
         -rw------- 1 adminuser adminuser 5638 Feb  1 21:46 /home/adminuser/.kube/config
         ```
    3) Install network:
       1) `tigera-operator`
          * The command
            ```
            ssh hw10-kubemaster 'kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml"'

            ```
          * The output: (tl/dr) <details><summary>Show details</summary>
            ```
            namespace/tigera-operator created
            customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/caliconodestatuses.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/ipreservations.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
            customresourcedefinition.apiextensions.k8s.io/apiservers.operator.tigera.io created
            customresourcedefinition.apiextensions.k8s.io/imagesets.operator.tigera.io created
            customresourcedefinition.apiextensions.k8s.io/installations.operator.tigera.io created
            customresourcedefinition.apiextensions.k8s.io/tigerastatuses.operator.tigera.io created
            serviceaccount/tigera-operator created
            clusterrole.rbac.authorization.k8s.io/tigera-operator created
            clusterrolebinding.rbac.authorization.k8s.io/tigera-operator created
            deployment.apps/tigera-operator created
            ```
            </details>
       2) `custom-resources`
          * The command:
            ```bash
            ssh hw10-kubemaster 'kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml"'
            ```
          * The output:
            ```
            installation.operator.tigera.io/default created
            apiserver.operator.tigera.io/default created
            ```
18) Check that all cluster pods are in the `running` state:
    * The command:
      ```
      ssh hw10-kubemaster 'kubectl get pods --all-namespaces'
      ```
    * The output:
      ```
      NAMESPACE          NAME                                                                         READY   STATUS    RESTARTS   AGE
      calico-apiserver   calico-apiserver-587d5c9988-4z44w                                            1/1     Running   0          57m
      calico-apiserver   calico-apiserver-587d5c9988-b65vm                                            1/1     Running   0          57m
      calico-system      calico-kube-controllers-6b7b9c649d-qhqjb                                     1/1     Running   0          58m
      calico-system      calico-node-nfjkj                                                            1/1     Running   0          50m
      calico-system      calico-node-pcvbs                                                            1/1     Running   0          58m
      calico-system      calico-typha-c678cb6bd-vhmt4                                                 1/1     Running   0          58m
      calico-system      csi-node-driver-htlk7                                                        2/2     Running   0          50m
      calico-system      csi-node-driver-sg95l                                                        2/2     Running   0          58m
      kube-system        coredns-787d4945fb-57ltm                                                     1/1     Running   0          81m
      kube-system        coredns-787d4945fb-9g7bd                                                     1/1     Running   0          81m
      kube-system        etcd-irc168976-hw10-k8s-manual-deployment-kubemaster-vm                      1/1     Running   0          81m
      kube-system        kube-apiserver-irc168976-hw10-k8s-manual-deployment-kubemaster-vm            1/1     Running   0          81m
      kube-system        kube-controller-manager-irc168976-hw10-k8s-manual-deployment-kubemaster-vm   1/1     Running   0          81m
      kube-system        kube-proxy-crxxz                                                             1/1     Running   0          50m
      kube-system        kube-proxy-ntv74                                                             1/1     Running   0          81m
      kube-system        kube-scheduler-irc168976-hw10-k8s-manual-deployment-kubemaster-vm            1/1     Running   0          81m
      tigera-operator    tigera-operator-54b47459dd-fsgbg                                             1/1     Running   0          61m
      ```
19) Attach `kubenode` to `kubemaster` using the `kubeadm join` command, that has been listed in the output of the Kubernetes control-plane initialization command on the step 17.1. Run the proposed command on the `kubenode` instance only:
    * The command:
      ```
      ssh hw10-kubenode 'sudo kubeadm join 10.132.0.6:6443 --token hytykz.ykpsrke4hd4g1w68 --discovery-token-ca-cert-hash sha256:fd67ad420dd59883eab431a81e1a563a9a0e04f1dfab6f34f984ce17a053f07a'
      ```
    * The output:
      ```
      [preflight] Running pre-flight checks
      [preflight] Reading configuration from the cluster...
      [preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
      [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
      [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
      [kubelet-start] Starting the kubelet
      [kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

      This node has joined the cluster:
      * Certificate signing request was sent to apiserver and a response was received.
      * The Kubelet was informed of the new secure connection details.

      Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
      ```
20) Run `kubectl get nodes` on the `kubemaster` instance to see the `kubenode` instance join the cluster:
    * The command:
      ```bash
      ssh hw10-kubemaster 'kubectl get nodes -o wide'
      ```
    * The output:
      ```
      NAME                                                 STATUS   ROLES           AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
      irc168976-hw10-k8s-manual-deployment-kubemaster-vm   Ready    control-plane   137m   v1.26.1   10.132.0.6    <none>        Ubuntu 20.04.5 LTS   5.15.0-1027-gcp   containerd://1.6.16
      irc168976-hw10-k8s-manual-deployment-kubenode-vm     Ready    <none>          107m   v1.26.1   10.132.0.7    <none>        Ubuntu 20.04.5 LTS   5.15.0-1027-gcp   containerd://1.6.16
      ```
21) Change the role of the `kubenode` node and list the nodes again:
    * The command:
      ```
      ssh hw10-kubemaster 'kubectl label node irc168976-hw10-k8s-manual-deployment-kubenode-vm node-role.kubernetes.io/worker="" && kubectl get nodes -o wide'
      ```
    * The output:
      ```
      node/irc168976-hw10-k8s-manual-deployment-kubenode-vm labeled
      NAME                                                 STATUS   ROLES           AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
      irc168976-hw10-k8s-manual-deployment-kubemaster-vm   Ready    control-plane   139m   v1.26.1   10.132.0.6    <none>        Ubuntu 20.04.5 LTS   5.15.0-1027-gcp   containerd://1.6.16
      irc168976-hw10-k8s-manual-deployment-kubenode-vm     Ready    worker          109m   v1.26.1   10.132.0.7    <none>        Ubuntu 20.04.5 LTS   5.15.0-1027-gcp   containerd://1.6.16
      ```

### Counclusion

The Kubernetes cluster has been deployed successfully 

### Cleaning up resources

1) Delete the instances:
   ```
   gcloud compute instances delete irc168976-hw10-k8s-manual-deployment-kubenode-vm irc168976-hw10-k8s-manual-deployment-kubemaster-vm
   ```
2) Delete the addresses:
   ```
   gcloud compute addresses delete hw10-k8s-kubemaster-ext-ip hw10-k8s-kubenode-ext-ip
   ```
3) Remove the SSh server public keys of the instances from the local user's `${HOME}/.ssh/known_hosts` file:
   * The command:
   ```
   ssh-keygen -R 34.79.40.78 34.79.109.57 -f ~/.ssh/known_hosts
   ```
4) Remove the connection settings used to connect to the `kubemaster` and `kubenode` instances from the local user's SSH client configuration file `${HOME}/.ssh/config`:
   * The command:
     ```
     while lNumber=$(grep --max-count 1 --no-filename --fixed-strings --line-number \
       '# GL devops basecamp irc168976 home work 10 kube' ${HOME}/.ssh/config | \
       cut --delimiter=':' --fields 1 ) && [[ -n "${lNumber}" ]] ; do \
         sed -i "${lNumber},$((${lNumber}+6)) d" ${HOME}/.ssh/config ; done
     ```