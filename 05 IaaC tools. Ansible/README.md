# IRC168976 DevOps GL BaseCamp homework 05. IaaC tools: Ansible

## [Conditions](https://github.com/yurnov/IaC_Ansible_basecamp/blob/master/08-homework.md)

### Prerequisites

* 4 linux machines (VMs, instances in Digital Ocean, GCP, AWS EC2, dosen't matter);
* Python installed (2.7 or 3.5+);
* established password-less connection from one machine (controller) to others;

ps: one of machine (controller) can be a Windows 10 machine with WSL/WSL2

### Task

1) Create a inventory file with four groups, each provisioning VM should be in separate group and group named `iaas` what should include childrens from two first groups.
2) Create reusable roles for that:
   1) creating a empty file /etc/iaac with rigths 0500
   2) fetch a linux distro name/version
3) Create playbook for:
   1) invoke the role for /etc/iaac for hosts group iaas
   2) invoke the role for defining variable for all hosts
   3) print in registered variables
      * printing hostnames together with registered variables will be a plus.
4) Create a repo in your GitHub account and commit code above

Optional:

1) use ansible_user and ansible_password for ssh connection and store passwords for each VM in encrypred way (add vault password to README.md in this case)

## The solution

### Distribution contents

The distribution consists of the following files:
1) `irc168976-hw05-iaac-tools-ansible-inventory.ini` - Created Ansible inventory file.
2) `./roles/create-the-iaac-file-with-0500-mode/tasks/main.yaml` - The «**creating a empty file /etc/iaac with rigths 0500**» role tasks file.
3) `./roles/fetch-a-linux-distro-name-and-version/tasks/main.yaml` - The «**fetch a linux distro name/version**» role tasks file.
4) `irc168976-hw05-iaac-tools-ansible-playbook.yaml` - Created Ansible playbook file.
5) `README.md` - This file. The short description of this work.
6) `irc168976-hw05-iaac-tools-ansible-resources-deployment-script.bash` - The script that is used to deploy the resources which are mentioned in the prerequisites in the AWS, copy the Ansible artifacts to them, run the Ansible playbook and clean the deployed resources up, if needed.
7) `irc168976-hw05-iaac-tools-ansible-ctrl-instance-startup-script.bash` - The script to set the control instance up and running at its provisioning time.

### How to use this distribution

#### Prerequisites

The following conditions must be met to deploy this template:
1) Got an AWS account.
2) Local Linux environment with BASH 4.0 (WSL or a PC that is running Linux).
3) The AWS CLI installed and authenticated in that mentioned Linux environment.
4) All the files of this  distribution are downloaded in some directory on a local PC, preserving the directory structure of the distribution.
5) Four SSH key pairs created or chosen to use with this deployment. They should be without passphrase, should be placed into the `${HOME}/.ssh/` directory on the local PC and have got the following names:
   1) The control instance key name:
      - `irc168976-hw05-iaac-tools-ansible-ctrl-vm-ed25519-key`
   2) Managed instances key names:
      - `irc168976-hw05-iaac-tools-ansible-mngd-vm-01-ed25519-key`
      - `irc168976-hw05-iaac-tools-ansible-mngd-vm-02-ed25519-key`
      - `irc168976-hw05-iaac-tools-ansible-mngd-vm-03-ed25519-key`.
6) The public parts of the SSH key pairs must be imported into AWS EC2 Key pairs storage and must be named there exactly as their respective **private** key files so that in the AWS EC2 Key pairs list the public key that is imported using a file with the name `irc168976-hw05-iaac-tools-ansible-ctrl-vm-ed25519-key.pub` must be named `irc168976-hw05-iaac-tools-ansible-ctrl-vm-ed25519-key` and so on.
7) Execute permission set on the `irc168976-hw05-iaac-tools-ansible-resources-deployment-script.bash` file for its owner.

#### How to deploy

Run the following command in a directory where the distribution has been downloaded to:

```bash
./irc168976-hw05-iaac-tools-ansible-resources-deployment-script.bash 2>$(date '+%0Y.%0m.%0d_%0H-%0M-%0S')-irc168976-hw05-iaac-tools-ansible-resources-deployment-script.bash.err | tee $(date '+%0Y.%0m.%0d_%0H-%0M-%0S')-irc168976-hw05-iaac-tools-ansible-resources-deployment-script.bash.log
```

As a result, four instances will be deployed, Ansible artifacts will be copied to the control instance, the playbook will be run on the control instance and the result of its run will be displayed. In the end, resources cleanup proposition will be displayed and, if confirmed, all deployed resources will be cleaned up. An example of the deployment script output messages are shown below. <details><summary>Show the details</summary>
```log
Creating a VPC 10.0.0.0/27...
Success!

Creating a subnet 10.0.0.0/28...
Success!

Creating a subnet 10.0.0.16/28...
Success!

Creating an internet gateway...
Success!

Attaching created internet gateway to the VPC...
Success!

Creating a custom route table for control subnet...
Success!

Creating a route for all traffic in control subnet route table...
{
    "Return": true
}
Success!

Associating the control route table with the control subnet...
{
    "AssociationId": "rtbassoc-010b3ee542a819219",
    "AssociationState": {
        "State": "associated"
    }
}
Success!

Creating a route for all traffic in managed subnet route table...
Success!

Associating the managed route table with the manged subnet...
{
    "AssociationId": "rtbassoc-0d242450cdfe9a501",
    "AssociationState": {
        "State": "associated"
    }
}
Success!

Creating security group for control instance placement subnet...
Success!

Creating security group for managed instance placement subnet...
Success!

Enabling inbound traffic on TCP port 22 (SSH) from my IP in Ansible control instance security group...
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-09b0251810bded716",
            "GroupId": "sg-0bcd4ba349d329b86",
            "GroupOwnerId": "815363309294",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "CidrIpv4": "46.173.148.62/32"
        }
    ]
}
Success!

Enabling outgoing traffic on TCP port 80,443 in Ansible control instance security group...
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-000febbdb939b01ef",
            "GroupId": "sg-0bcd4ba349d329b86",
            "GroupOwnerId": "815363309294",
            "IsEgress": true,
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIpv4": "0.0.0.0/0",
            "Description": "Allow any destination address"
        },
        {
            "SecurityGroupRuleId": "sgr-07903600ca4273f2a",
            "GroupId": "sg-0bcd4ba349d329b86",
            "GroupOwnerId": "815363309294",
            "IsEgress": true,
            "IpProtocol": "tcp",
            "FromPort": 443,
            "ToPort": 443,
            "CidrIpv4": "0.0.0.0/0",
            "Description": "Allow any destination address"
        }
    ]
}
Success!

Enabling outgoing traffic on TCP port 80,443 in Ansible managed instances security group...
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-0bdb634c6da0b198d",
            "GroupId": "sg-04f7b241ff1a6ac8b",
            "GroupOwnerId": "815363309294",
            "IsEgress": true,
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIpv4": "0.0.0.0/0",
            "Description": "Allow any destination address"
        },
        {
            "SecurityGroupRuleId": "sgr-0d2eb52bca2f22976",
            "GroupId": "sg-04f7b241ff1a6ac8b",
            "GroupOwnerId": "815363309294",
            "IsEgress": true,
            "IpProtocol": "tcp",
            "FromPort": 443,
            "ToPort": 443,
            "CidrIpv4": "0.0.0.0/0",
            "Description": "Allow any destination address"
        }
    ]
}
Success!

Enabling outgoing traffic on TCP port 22 in Ansible control instance security group to managed instance security group...
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-0aa0718f851683b93",
            "GroupId": "sg-0bcd4ba349d329b86",
            "GroupOwnerId": "815363309294",
            "IsEgress": true,
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "ReferencedGroupInfo": {
                "GroupId": "sg-04f7b241ff1a6ac8b",
                "UserId": "815363309294"
            }
        }
    ]
}
Success!

Enabling inbound traffic on TCP port 22 (SSH) from Ansible control instance secirity group in Ansible managed instances security group...
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-06c59e4fffdddc946",
            "GroupId": "sg-04f7b241ff1a6ac8b",
            "GroupOwnerId": "815363309294",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "ReferencedGroupInfo": {
                "GroupId": "sg-0bcd4ba349d329b86",
                "UserId": "815363309294"
            }
        }
    ]
}
Success!

Enabling inbound traffic on TCP port 80 from Ansible managed instances security group in Ansible control instance secirity group...
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-0ee7ac8217d80d993",
            "GroupId": "sg-0bcd4ba349d329b86",
            "GroupOwnerId": "815363309294",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "ReferencedGroupInfo": {
                "GroupId": "sg-04f7b241ff1a6ac8b",
                "UserId": "815363309294"
            }
        }
    ]
}
Success!

Enabling outgoing traffic on TCP port 80,443 in Ansible control instance security group...
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-03e9baea0966bc1c0",
            "GroupId": "sg-0bcd4ba349d329b86",
            "GroupOwnerId": "815363309294",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 443,
            "ToPort": 443,
            "ReferencedGroupInfo": {
                "GroupId": "sg-04f7b241ff1a6ac8b",
                "UserId": "815363309294"
            }
        }
    ]
}
Success!

Running control instance...
Success!

Running the first managed instance...
Success!

Running the second managed instance...
Success!

Running the third managed instance...
Success!

Waiting for the control instance to enter the running state..
Ansible control instance has become running state
Getting control instance IP address...

renamed '/home/poddubetskyi/.ssh/config.new' -> '/home/poddubetskyi/.ssh/config'
Getting ssh server public keys from control instance and placing them into local user known_hosts file...
.Turning off source-dest check to make instance a NAT gateway...
Success!

Creating a route for all traffic in managed subnet route table...
{
    "Return": true
}
Success!

mode of '/home/poddubetskyi/.ssh/irc168976-hw05-iaac-tools-ansible-mngd-vm-01-ed25519-key' retained as 0600 (rw-------)
Copying file `/home/poddubetskyi/.ssh/irc168976-hw05-iaac-tools-ansible-mngd-vm-01-ed25519-key`...
Success!
mode of '/home/poddubetskyi/.ssh/irc168976-hw05-iaac-tools-ansible-mngd-vm-03-ed25519-key' retained as 0600 (rw-------)
Copying file `/home/poddubetskyi/.ssh/irc168976-hw05-iaac-tools-ansible-mngd-vm-03-ed25519-key`...
Success!
mode of '/home/poddubetskyi/.ssh/irc168976-hw05-iaac-tools-ansible-mngd-vm-02-ed25519-key' retained as 0600 (rw-------)
Copying file `/home/poddubetskyi/.ssh/irc168976-hw05-iaac-tools-ansible-mngd-vm-02-ed25519-key`...
Success!
renamed 'ctrl_instance_ssh_config.prepend' -> 'config'
removed 'ctrl_instance_ssh_config.prepend'

________________________________________________________________________________


Wait up to two minutes until `ansible-playbook` will be found in the ${PATH}......./usr/local/bin/ansible-playbook

Display ansible inventory file information that is copied to the control instance
{
    "_meta": {
        "hostvars": {
            "hw05_ctrl_vm": {
                "ansible_connection": "local"
            }
        }
    },
    "all": {
        "children": [
            "ungrouped",
            "iaas",
            "hw05_mngd_vm_03_grp"
        ]
    },
    "hw05_mngd_vm_01_grp": {
        "hosts": [
            "ansible-mngd-vm-01"
        ]
    },
    "hw05_mngd_vm_02_grp": {
        "hosts": [
            "ansible-mngd-vm-02"
        ]
    },
    "hw05_mngd_vm_03_grp": {
        "hosts": [
            "ansible-mngd-vm-03"
        ]
    },
    "iaas": {
        "children": [
            "hw05_mngd_vm_01_grp",
            "hw05_mngd_vm_02_grp"
        ]
    },
    "ungrouped": {
        "hosts": [
            "hw05_ctrl_vm"
        ]
    }
}

PLAY [IRC168976 DevOps GL BaseCamp homework 05. IaaC tools: Ansible. The play that invokes the role for /etc/iaac for hosts group `iaas`] ***

TASK [./roles/create-the-iaac-file-with-0500-mode : Create an empty file /etc/iaac with rigths 0500] ***
changed: [ansible-mngd-vm-01]
changed: [ansible-mngd-vm-02]

TASK [List the file that has been created] *************************************
changed: [ansible-mngd-vm-01]
changed: [ansible-mngd-vm-02]

TASK [Display list command output] *********************************************
ok: [ansible-mngd-vm-01] => {
    "msg": {
        "changed": true,
        "cmd": "ls -la /etc/iaac",
        "delta": "0:00:00.004619",
        "end": "2023-02-07 05:38:38.043036",
        "failed": false,
        "msg": "",
        "rc": 0,
        "start": "2023-02-07 05:38:38.038417",
        "stderr": "",
        "stderr_lines": [],
        "stdout": "-r-x------ 1 root root 0 Feb  7 05:38 /etc/iaac",
        "stdout_lines": [
            "-r-x------ 1 root root 0 Feb  7 05:38 /etc/iaac"
        ]
    }
}
ok: [ansible-mngd-vm-02] => {
    "msg": {
        "changed": true,
        "cmd": "ls -la /etc/iaac",
        "delta": "0:00:00.004294",
        "end": "2023-02-07 05:38:38.035611",
        "failed": false,
        "msg": "",
        "rc": 0,
        "start": "2023-02-07 05:38:38.031317",
        "stderr": "",
        "stderr_lines": [],
        "stdout": "-r-x------ 1 root root 0 Feb  7 05:38 /etc/iaac",
        "stdout_lines": [
            "-r-x------ 1 root root 0 Feb  7 05:38 /etc/iaac"
        ]
    }
}

PLAY [IRC168976 DevOps GL BaseCamp homework 05. IaaC tools: Ansible. The play that invokes the role to fetch a linux distro name/version for all hosts] ***

TASK [Use the `fetch a linux distro name/version` role] ************************

TASK [./roles/fetch-a-linux-distro-name-and-version : Fetch a linux distro name/version using Ansible builtin `setup` module] ***
ok: [ansible-mngd-vm-02]
ok: [ansible-mngd-vm-01]
ok: [ansible-mngd-vm-03]

TASK [./roles/fetch-a-linux-distro-name-and-version : Create a variable that contains the fetched linux distro name/version] ***
ok: [ansible-mngd-vm-01]
ok: [ansible-mngd-vm-02]
ok: [ansible-mngd-vm-03]

TASK [./roles/fetch-a-linux-distro-name-and-version : Display the linux distro name/version that is the value of the created variable] ***
ok: [ansible-mngd-vm-01] => {
    "msg": "A linux distro name/version on the inventory hostname `ansible-mngd-vm-01` is as follows: Ubuntu 20.04"
}
ok: [ansible-mngd-vm-02] => {
    "msg": "A linux distro name/version on the inventory hostname `ansible-mngd-vm-02` is as follows: Ubuntu 20.04"
}
ok: [ansible-mngd-vm-03] => {
    "msg": "A linux distro name/version on the inventory hostname `ansible-mngd-vm-03` is as follows: Ubuntu 20.04"
}

TASK [Display the message that is got from the `fetch a linux distro name/version` role] ***
ok: [ansible-mngd-vm-01] => {
    "msg": "A linux distro name/version on the inventory hostname `ansible-mngd-vm-01` is as follows: Ubuntu 20.04"
}
ok: [ansible-mngd-vm-02] => {
    "msg": "A linux distro name/version on the inventory hostname `ansible-mngd-vm-02` is as follows: Ubuntu 20.04"
}
ok: [ansible-mngd-vm-03] => {
    "msg": "A linux distro name/version on the inventory hostname `ansible-mngd-vm-03` is as follows: Ubuntu 20.04"
}

PLAY RECAP *********************************************************************
ansible-mngd-vm-01         : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
ansible-mngd-vm-02         : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
ansible-mngd-vm-03         : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


________________________________________________________________________________


To connect to Ansible control instance use the following command:

  ssh -v irc168976-hw05-iaac-tools-ansible-ctrl-instance

________________________________________________________________________________


The list of created resources:
declare -A resourcesList=([ansibleVPCControlSubnetRouteTable]="rtb-0477d545122cf5d50" [ansibleMngdInstanceSG]="sg-04f7b241ff1a6ac8b" [ansibleVPCID]="vpc-02402ff81215eb87e" [ansibleCtrlInstance]="i-0b543499f62d3e777" [ansibleVPCManagedSubnetRouteTable]="rtb-09395bf444f508a95" [ansibleCtrlInstanceSG]="sg-0bcd4ba349d329b86" [ansibleMngdInstanceTheSecond]="i-0f23ed7c3360a0419" [ansibleMngdVMsSubnet]="subnet-0454b34681dcc7984" [ansibleInetGW]="igw-0653bca9bc825dafc" [ansibleCtrlInstancePublicIPValue]="3.76.202.46" [ansibleMngdInstanceTheFirst]="i-025d20a9d399bdf0d" [ansibleCtrlVMSubnet]="subnet-085797bfa5a7d9759" [ansibleMngdInstanceTheThird]="i-088f12afb8ba79d05" )

________________________________________________________________________________



The script to clean created resources up:
#!/usr/bin/env bash
# irc168976-hw05-iaac-tools-ansible-resources-cleanup-script.bash
# Clean up
aws ec2 terminate-instances --instance-ids 'i-0b543499f62d3e777' 'i-025d20a9d399bdf0d' 'i-0f23ed7c3360a0419' 'i-088f12afb8ba79d05'

# Wait while all the instances become the 'terminated' state
printf 'Waiting for all instances termination'
while notTerminated=$(aws ec2 describe-instances --instance-ids 'i-0b543499f62d3e777' 'i-025d20a9d399bdf0d' 'i-0f23ed7c3360a0419' 'i-088f12afb8ba79d05' --output text --query 'Reservations[*].Instances[*].State.Name' --filter 'Name=instance-state-name,Values=pending,running,shutting-down,stopping,stopped' | tr --delete '\n') && \
[[ -n ${notTerminated} ]] ; do
printf '.'
sleep 15
done
printf '\nAll instances have been terminated\n'
#
# Delete subnets
## Delete control instance subnet
aws ec2 delete-subnet --subnet-id 'subnet-085797bfa5a7d9759'
## Delete Managed instances subnet
aws ec2 delete-subnet --subnet-id 'subnet-0454b34681dcc7984'
#
## Delete route table:
aws ec2 delete-route-table --route-table-id 'rtb-0477d545122cf5d50'
#
aws ec2 delete-route-table --route-table-id 'rtb-09395bf444f508a95'
#
# Detach internet gateway from VPC
aws ec2 detach-internet-gateway --internet-gateway-id 'igw-0653bca9bc825dafc' --vpc-id 'vpc-02402ff81215eb87e'
#
# Delete internet gateway
aws ec2 delete-internet-gateway --internet-gateway-id "igw-0653bca9bc825dafc"

for sgid in 'sg-04f7b241ff1a6ac8b' 'sg-0bcd4ba349d329b86' ; do
while read sgr ; do
revokeSubcmd='revoke-security-group-ingress'
isEgress=$(aws ec2 describe-security-group-rules --security-group-rule-ids "${sgr}" --output text --query 'SecurityGroupRules[*].IsEgress')
if [[ "${isEgress,,}" == 'true' ]] ; then
revokeSubcmd='revoke-security-group-egress'
fi
aws ec2 ${revokeSubcmd} --group-id "${sgid}" --security-group-rule-ids "${sgr}"
done < <(aws ec2 describe-security-group-rules --filter "Name=group-id,Values=${sgid}" --output text --query 'SecurityGroupRules[*].SecurityGroupRuleId' | tr '\t ' '\n')
done

## Delete security groups
aws ec2 delete-security-group --group-id 'sg-04f7b241ff1a6ac8b'
aws ec2 delete-security-group --group-id 'sg-0bcd4ba349d329b86'

#
# Delete VPC
aws ec2 delete-vpc --vpc-id "vpc-02402ff81215eb87e"
#
# Remove control instance ssh public keys from local user known_hosts file
ssh-keygen -f "/home/poddubetskyi/.ssh/known_hosts" -R "3.76.202.46"
#
# Remove the control instance ssh connection settings from local user ssh 'config' file
while lNumber=$(grep --max-count 1 --no-filename --fixed-strings --line-number   '# irc168976-hw05 Ansible Control Instance (node)' ../.ssh/config |   cut --delimiter=':' --fields 1 ) && [[ -n "${lNumber}" ]] ; do
  sed -i "${lNumber},$((${lNumber}+6)) d" ../.ssh/config
done


________________________________________________________________________________


Looks like the ansible playbook has been run successfully
so there is no future need in the deployed resources.
Would you like to clean up deployed resources? (y/n) 
Starting the cleanup process
{
    "TerminatingInstances": [
        {
            "CurrentState": {
                "Code": 32,
                "Name": "shutting-down"
            },
            "InstanceId": "i-025d20a9d399bdf0d",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        },
        {
            "CurrentState": {
                "Code": 32,
                "Name": "shutting-down"
            },
            "InstanceId": "i-0b543499f62d3e777",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        },
        {
            "CurrentState": {
                "Code": 32,
                "Name": "shutting-down"
            },
            "InstanceId": "i-0f23ed7c3360a0419",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        },
        {
            "CurrentState": {
                "Code": 32,
                "Name": "shutting-down"
            },
            "InstanceId": "i-088f12afb8ba79d05",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        }
    ]
}
Waiting for all instances termination..
All instances have been terminated
{
    "Return": true
}
{
    "Return": true
}
{
    "Return": true
}
{
    "Return": true
}
{
    "Return": true
}
{
    "Return": true
}
{
    "Return": true
}
{
    "Return": true
}
{
    "Return": true
}
{
    "Return": true
}
{
    "Return": true
}
# Host 3.76.202.46 found: line 34
/home/poddubetskyi/.ssh/known_hosts updated.
Original contents retained as /home/poddubetskyi/.ssh/known_hosts.old

```
</details>

#### How the distribution corresponds to the task

1) _Create a inventory file with four groups, each provisioning VM should be in separate group and group named `iaas` what should include childrens from two first groups._
   + Created inventory file name: `irc168976-hw05-iaac-tools-ansible-inventory.ini`
   + Created inventory file contents:
     ```ini
     ; Use explicit control instance host definition in this inventory
     hw05_ctrl_vm ansible_connection=local
     
     [iaas:children]
     hw05_mngd_vm_01_grp
     hw05_mngd_vm_02_grp
     
     [hw05_mngd_vm_01_grp]
     ansible-mngd-vm-01
     
     [hw05_mngd_vm_02_grp]
     ansible-mngd-vm-02
     
     [hw05_mngd_vm_03_grp]
     ansible-mngd-vm-03
  
     ```
2) _Create reusable roles for that:_
   1) _creating a empty file /etc/iaac with rigths 0500_
      + Created role folder name: `create-the-iaac-file-with-0500-mode`
      + Created role tasks file contents:
        ```yaml
        - name: "Create an empty file /etc/iaac with rigths 0500"
          ansible.builtin.file:
            path: '/etc/iaac'
            mode: '0500'
            state: 'touch'
          become: true
  
        ```
   2) _fetch a linux distro name/version_
      + Created role folder name: `fetch-a-linux-distro-name-and-version`
      + Created role tasks file contents:
        ```yaml
        - name: "Fetch a linux distro name/version using Ansible builtin `setup` module"
          ansible.builtin.setup:
          register: setupModuleOutput
  
        - name: "Create a variable that contains the fetched linux distro name/version"
          set_fact:
            linuxDistroNameAndVersion: "{{ setupModuleOutput.ansible_facts.ansible_distribution }} {{ setupModuleOutput.ansible_facts.ansible_distribution_version }}"  
  
        - name: "Display the linux distro name/version that is the value of the created variable"
          ansible.builtin.debug:
            msg: "A linux distro name/version on the inventory hostname `{{ inventory_hostname }}` is as follows: {{ linuxDistroNameAndVersion }}"
          register: fetchALinuxDistroNameAndVersionRoleOutput      
        ```
3) _Create playbook for:_
   1) _invoke the role for /etc/iaac for hosts group iaas_
   2) _invoke the role for defining variable for all hosts_
   3) _print in registered variables_
      * _printing hostnames together with registered variables will be a plus._

   + Created playbook file name: `irc168976-hw05-iaac-tools-ansible-playbook.yaml`
   + Created playbook file contents:
     ```yaml
     - name: "IRC168976 DevOps GL BaseCamp homework 05. IaaC tools: Ansible. The play that invokes the role for /etc/iaac for hosts group `iaas`"
       hosts: iaas
       gather_facts: false
       roles:
         - role: './roles/create-the-iaac-file-with-0500-mode'
       tasks:
         - name: 'List the file that has been created'
           ansible.builtin.shell:
             cmd: 'ls -la /etc/iaac'
           become: true
           register: listCommandOutput
     
         - name: 'Display list command output'
           ansible.builtin.debug:
             msg: "{{ listCommandOutput }}"
     
     - name: "IRC168976 DevOps GL BaseCamp homework 05. IaaC tools: Ansible. The play that invokes the role to fetch a linux distro name/version for all hosts"
       hosts:
         - iaas
         - hw05_mngd_vm_03_grp
       gather_facts: false
       tasks:
         - name: "Use the `fetch a linux distro name/version` role"
           include_role:
             name: './roles/fetch-a-linux-distro-name-and-version'
           vars:
             register: fetchALinuxDistroNameAndVersionRoleOutput
     
         - name: 'Display the message that is got from the `fetch a linux distro name/version` role'
           ansible.builtin.debug:
             msg: "{{ fetchALinuxDistroNameAndVersionRoleOutput.msg }}"
     
     ```
4) _Create a repo in your GitHub account and commit code above_
   
   [The code](https://github.com/poddubetskyi/irc168976-home-tasks/tree/hw05-iaac-tools-ansible/05%20IaaC%20tools.%20Ansible)

Optional:

1) use ansible_user and ansible_password for ssh connection and store passwords for each VM in encrypred way (add vault password to README.md in this case)

   **Not done**

#### Some Ansible commands to display some information about created inventory file or launch created playbook

1) Display some information about created inventory file:
   ```bash
   ansible-inventory --inventory-file irc168976-hw05-iaac-tools-ansible-inventory.ini --list
   ```
2) Launch created playbook:
   ```bash
   ansible-playbook --inventory ./irc168976-hw05-iaac-tools-ansible-inventory.ini ./irc168976-hw05-iaac-tools-ansible-playbook.yaml
   ```
