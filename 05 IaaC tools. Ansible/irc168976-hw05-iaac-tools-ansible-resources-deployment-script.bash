#!/usr/bin/env bash
# irc168976-hw05-iaac-tools-ansible-resources-deployment-script.bash
declare -A resourcesList=()

# [Find a Linux AMI](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html)
# [Amazon EC2 AMI Locator](https://cloud-images.ubuntu.com/locator/ec2/)
controlInstanceImageID='ami-076bdd070268f9b8d'
controlInstanceHWType='t2.micro'
managedInstanceImageID="${controlInstanceImageID}"
managedInstanceHWType="${controlInstanceHWType}"

displayHorizontalRuler (){
  printf '\n'
  printf '_%.0s' {1..80}
  printf '\n\n\n'
}

make_cleanup_script_file_path_and_name(){
  cleanUpScriptFileName="${0##*/}"
  cleanUpScriptFilePath="${0%/*}"
  # this condition is true only when the executable filename is invoked
  # by name only without any path, relative or absolute
  if [[ "${cleanUpScriptFileName}" == "${cleanUpScriptFilePath}" ]] ; then
    cleanUpScriptFilePath=
  else
    cleanUpScriptFilePath="${cleanUpScriptFilePath}/"
  fi
  cleanUpScriptFileName="${cleanUpScriptFileName/deployment/cleanup}"
  printf '%s' "${cleanUpScriptFilePath}${cleanUpScriptFileName}"
}

make_and_show_clean_up_script_contents(){

  displayHorizontalRuler

  printf '\nThe script to clean created resources up:\n'
  
tee "$(make_cleanup_script_file_path_and_name)" <<CLEAN_UP_SCRIPT_CONTENTS
#!/usr/bin/env bash
# irc168976-hw05-iaac-tools-ansible-resources-cleanup-script.bash
# Clean up
aws ec2 terminate-instances --instance-ids '${resourcesList['ansibleCtrlInstance']}' '${resourcesList['ansibleMngdInstanceTheFirst']}' '${resourcesList['ansibleMngdInstanceTheSecond']}' '${resourcesList['ansibleMngdInstanceTheThird']}'

# Wait while all the instances become the 'terminated' state
printf 'Waiting for all instances termination'
while notTerminated=\$(aws ec2 describe-instances --instance-ids '${resourcesList['ansibleCtrlInstance']}' '${resourcesList['ansibleMngdInstanceTheFirst']}' '${resourcesList['ansibleMngdInstanceTheSecond']}' '${resourcesList['ansibleMngdInstanceTheThird']}' --output text --query 'Reservations[*].Instances[*].State.Name' --filter 'Name=instance-state-name,Values=pending,running,shutting-down,stopping,stopped' | tr --delete '\n') && \\
[[ -n \${notTerminated} ]] ; do
printf '.'
sleep 15
done
printf '\nAll instances have been terminated\n'
#
# Delete subnets
## Delete control instance subnet
aws ec2 delete-subnet --subnet-id '${resourcesList['ansibleCtrlVMSubnet']}'
## Delete Managed instances subnet
aws ec2 delete-subnet --subnet-id '${resourcesList['ansibleMngdVMsSubnet']}'
#
## Delete route table:
aws ec2 delete-route-table --route-table-id '${resourcesList['ansibleVPCControlSubnetRouteTable']}'
#
aws ec2 delete-route-table --route-table-id '${resourcesList['ansibleVPCManagedSubnetRouteTable']}'
#
# Detach internet gateway from VPC
aws ec2 detach-internet-gateway --internet-gateway-id '${resourcesList['ansibleInetGW']}' --vpc-id '${resourcesList['ansibleVPCID']}'
#
# Delete internet gateway
aws ec2 delete-internet-gateway --internet-gateway-id "${resourcesList['ansibleInetGW']}"

for sgid in '${resourcesList['ansibleMngdInstanceSG']}' '${resourcesList['ansibleCtrlInstanceSG']}' ; do
while read sgr ; do
revokeSubcmd='revoke-security-group-ingress'
isEgress=\$(aws ec2 describe-security-group-rules --security-group-rule-ids "\${sgr}" --output text --query 'SecurityGroupRules[*].IsEgress')
if [[ "\${isEgress,,}" == 'true' ]] ; then
revokeSubcmd='revoke-security-group-egress'
fi
aws ec2 \${revokeSubcmd} --group-id "\${sgid}" --security-group-rule-ids "\${sgr}"
done < <(aws ec2 describe-security-group-rules --filter "Name=group-id,Values=\${sgid}" --output text --query 'SecurityGroupRules[*].SecurityGroupRuleId' | tr '\t ' '\n')
done

## Delete security groups
aws ec2 delete-security-group --group-id '${resourcesList['ansibleMngdInstanceSG']}'
aws ec2 delete-security-group --group-id '${resourcesList['ansibleCtrlInstanceSG']}'

#
# Delete VPC
aws ec2 delete-vpc --vpc-id "${resourcesList['ansibleVPCID']}"
#
# Remove control instance ssh public keys from local user known_hosts file
ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${resourcesList['ansibleCtrlInstancePublicIPValue']}"
#
# Remove the control instance ssh connection settings from local user ssh 'config' file
while lNumber=\$(grep --max-count 1 --no-filename --fixed-strings --line-number \
  '# irc168976-hw05 Ansible Control Instance (node)' ../.ssh/config | \
  cut --delimiter=':' --fields 1 ) && [[ -n "\${lNumber}" ]] ; do
  sed -i "\${lNumber},\$((\${lNumber}+6)) d" ../.ssh/config
done

CLEAN_UP_SCRIPT_CONTENTS

if [[ -f "$(make_cleanup_script_file_path_and_name)" ]] ; then
  chmod u+x "$(make_cleanup_script_file_path_and_name)"
fi

}

create_vpc_and_subnets(){
  # Step 1: Create a VPC and subnets
  ## Create a VPC 10.0.0.0/27
  printf 'Creating a VPC 10.0.0.0/27...\n'
  if ! resourcesList['ansibleVPCID']=$(aws ec2 create-vpc \
        --cidr-block 10.0.0.0/27 \
        --tag-specifications 'ResourceType=vpc,Tags={Key=Name,Value=irc168976-hw05-ansible-vpc}' \
        --query Vpc.VpcId --output text)
  then printf 'A VPC 10.0.0.0/27 creation Failed\n' >&2 ; return 1 ; fi
  printf 'Success!\n\n'
  ## create a subnet 10.0.0.0/28
  printf 'Creating a subnet 10.0.0.0/28...\n'
  if ! resourcesList['ansibleCtrlVMSubnet']=$(aws ec2 create-subnet \
        --vpc-id "${resourcesList['ansibleVPCID']}" \
        --tag-specifications 'ResourceType=subnet,Tags={Key=Name,Value=irc168976-hw05-ansible-ctrl-vm-subnet}' \
        --cidr-block 10.0.0.0/28 --query Subnet.SubnetId --output text)
  then printf 'A subnet 10.0.0.0/28 creation failed\n' >&2 ; return 2 ; fi
  printf 'Success!\n\n'
  ## create a subnet 10.0.0.16/28
  printf 'Creating a subnet 10.0.0.16/28...\n'
  if ! resourcesList['ansibleMngdVMsSubnet']=$(aws ec2 create-subnet \
        --vpc-id "${resourcesList['ansibleVPCID']}" \
        --tag-specifications 'ResourceType=subnet,Tags={Key=Name,Value=irc168976-hw05-ansible-mngd-vm-subnet}' \
        --cidr-block 10.0.0.16/28 --query Subnet.SubnetId --output text)
  then printf 'A subnet 10.0.0.16/28 creation failed\n' >&2 ; return 3 ; fi
  printf 'Success!\n\n'
}

create_internet_gateway(){
  # Step 2: Make the control subnet public
  ## Create an internet gateway using the following create-internet-gateway command
  printf 'Creating an internet gateway...\n'
  if ! resourcesList['ansibleInetGW']=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags={Key=Name,Value=irc168976-hw05-ansible-inet-gw-4-ctrl-subnet}' --query InternetGateway.InternetGatewayId --output text)
  then printf 'An internet gateway creation failed\n' >&2 ; return 4 ; fi
  printf 'Success!\n\n'
}

attach_internet_gateway_to_vpc(){
  ## attach the internet gateway to your VPC
  printf 'Attaching created internet gateway to the VPC...\n'
  if ! aws ec2 attach-internet-gateway --vpc-id ${resourcesList['ansibleVPCID']} --internet-gateway-id ${resourcesList['ansibleInetGW']}
  then printf 'The process of attacment of the internet gateway to the VPC failed\n' >&2 ; return 5 ; fi
  printf 'Success!\n\n'
}

create_route_table_and_routes(){
  #
  ## Create a custom route table for your VPC
  printf 'Creating a custom route table for control subnet...\n'
  if ! resourcesList['ansibleVPCControlSubnetRouteTable']=$(aws ec2 create-route-table --vpc-id ${resourcesList['ansibleVPCID']} --tag-specifications 'ResourceType=route-table,Tags={Key=Name,Value=irc168976-hw05-ansible-vpc-ctrl-subnet-route-table}' --query RouteTable.RouteTableId --output text)
  then printf 'A custom route table for control subnet creation failed\n' >&2 ; return 6 ; fi
  printf 'Success!\n\n'
  #
  ## Create a route in the route table that points all traffic (0.0.0.0/0) to the internet gateway using the following create-route command
  printf 'Creating a route for all traffic in control subnet route table...\n'
  if ! aws ec2 create-route --route-table-id "${resourcesList['ansibleVPCControlSubnetRouteTable']}" --destination-cidr-block '0.0.0.0/0' --gateway-id "${resourcesList['ansibleInetGW']}"
  then printf 'Creation of a route for all traffic in control subnet route table failed\n' >&2 ; return 7 ; fi
  printf 'Success!\n\n'
  #
  ## associate created route table with a subnet in your VPC so that traffic from that subnet is routed to the internet gateway
  printf 'Associating the control route table with the control subnet...\n'
  if ! aws ec2 associate-route-table --subnet-id ${resourcesList['ansibleCtrlVMSubnet']} --route-table-id "${resourcesList['ansibleVPCControlSubnetRouteTable']}"
  then printf 'The association of the control route table with the control subnet failed\n' >&2 ; return 8 ; fi
  printf 'Success!\n\n'
  #
  #
  # Create a route table for the managed subnet
  printf 'Creating a route for all traffic in managed subnet route table...\n'
  if ! resourcesList['ansibleVPCManagedSubnetRouteTable']=$(aws ec2 create-route-table --vpc-id ${resourcesList['ansibleVPCID']} --tag-specifications 'ResourceType=route-table,Tags={Key=Name,Value=irc168976-hw05-ansible-vpc-mngd-subnet-route-table}' --query RouteTable.RouteTableId --output text)
  then printf 'Creation of a route for all traffic in managed subnet route table failed\n' >&2 ; return 9 ; fi
  printf 'Success!\n\n'
  #
  ## associate created route table with the managed subnet in VPC so that traffic from that subnet is routed to the NAT instance after launching it and adding the default route
  printf 'Associating the managed route table with the manged subnet...\n'
  if ! aws ec2 associate-route-table --subnet-id ${resourcesList['ansibleMngdVMsSubnet']} --route-table-id "${resourcesList['ansibleVPCManagedSubnetRouteTable']}"
  then printf 'The association of the control route table with the control subnet failed\n' >&2 ; return 10 ; fi
  printf 'Success!\n\n'
  #
}

add_default_route_for_managed_subnet(){
  # create the default route for the managed subnet
  printf 'Creating a route for all traffic in managed subnet route table...\n'
  if ! aws ec2 create-route --route-table-id "${resourcesList['ansibleVPCManagedSubnetRouteTable']}" --destination-cidr-block '0.0.0.0/0' --instance-id "${resourcesList['ansibleCtrlInstance']}"
  then printf 'Creation of a route for all traffic in managed subnet route table failed\n' >&2 ; return 25 ; fi
  printf 'Success!\n\n'
}
#
create_security_groups_and_ingress_rules(){
  # Create security group for control instance placement subnet
  printf 'Creating security group for control instance placement subnet...\n'
  if ! resourcesList['ansibleCtrlInstanceSG']=$(aws ec2 create-security-group --description 'irc168976 hw05 Ansible control instance SG' --group-name 'irc168976-hw05-ansible-ctrl-vm-sg' --vpc-id "${resourcesList['ansibleVPCID']}" --query 'GroupId' --output text)
  then printf 'The association of the control route table with the control subnet failed\n' >&2 ; return 11 ; fi
  printf 'Success!\n\n'

  # Create security group for managed instances placement subnet
  printf 'Creating security group for managed instance placement subnet...\n'
  if ! resourcesList['ansibleMngdInstanceSG']=$(aws ec2 create-security-group --description 'irc168976 hw05 Ansible managed instances SG' --group-name 'irc168976-hw05-ansible-mngd-vm-sg' --vpc-id "${resourcesList['ansibleVPCID']}" --query 'GroupId' --output text)
  then printf 'The association of the managed route table with the control subnet failed\n' >&2 ; return 12 ; fi
  printf 'Success!\n\n'
  
  # Enable inbound traffic on TCP port 22 (SSH) from my IP in Ansible control instance security group
  printf 'Enabling inbound traffic on TCP port 22 (SSH) from my IP in Ansible control instance security group...\n'
  if ! aws ec2 authorize-security-group-ingress --group-id "${resourcesList['ansibleCtrlInstanceSG']}" --protocol tcp --port 22 --cidr "$(curl --silent https://checkip.amazonaws.com/ | tr --delete '\r\n')/32"
  then printf 'Enabling inbound traffic on TCP port 22 (SSH) from my IP in Ansible control instance security group failed\n' >&2 ; return 13 ; fi
  printf 'Success!\n\n'

  # Enable outgoing traffic on TCP port 80,443 in Ansible control instance security group
  printf 'Enabling outgoing traffic on TCP port 80,443 in Ansible control instance security group...\n'
  if ! aws ec2 authorize-security-group-egress --group-id "${resourcesList['ansibleCtrlInstanceSG']}" --ip-permissions 'FromPort=80,IpProtocol=tcp,IpRanges={CidrIp=0.0.0.0/0,Description="Allow any destination address"},ToPort=80' 'FromPort=443,IpProtocol=tcp,IpRanges={CidrIp=0.0.0.0/0,Description="Allow any destination address"},ToPort=443'
  then printf 'Enabling outgoing traffic on TCP port 80,443 in Ansible control instance security group failed\n' >&2 ; return 14 ; fi
  printf 'Success!\n\n'
  
  # Enable outgoing traffic on TCP port 80,443 in Ansible managed instances security group
  printf 'Enabling outgoing traffic on TCP port 80,443 in Ansible managed instances security group...\n'
  if ! aws ec2 authorize-security-group-egress --group-id "${resourcesList['ansibleMngdInstanceSG']}" --ip-permissions 'FromPort=80,IpProtocol=tcp,IpRanges={CidrIp=0.0.0.0/0,Description="Allow any destination address"},ToPort=80' 'FromPort=443,IpProtocol=tcp,IpRanges={CidrIp=0.0.0.0/0,Description="Allow any destination address"},ToPort=443'
  then printf 'Enabling outgoing traffic on TCP port 80,443 in Ansible managed instances security group failed\n' >&2 ; return 15 ; fi
  printf 'Success!\n\n'

  # Enable outgoing traffic on TCP port 22 in Ansible control instance security group to managed instance security group
  printf 'Enabling outgoing traffic on TCP port 22 in Ansible control instance security group to managed instance security group...\n'
  if ! aws ec2 authorize-security-group-egress --group-id "${resourcesList['ansibleCtrlInstanceSG']}" --protocol tcp --port 22 --source-group "${resourcesList['ansibleMngdInstanceSG']}"
  then printf 'Enabling outgoing traffic on TCP port 22 in Ansible control instance security group to managed instance security group failed\n' >&2 ; return 16 ; fi
  printf 'Success!\n\n'

  # Enable inbound traffic on TCP port 22 (SSH) from Ansible control instance secirity group in Ansible managed instances security group
  printf 'Enabling inbound traffic on TCP port 22 (SSH) from Ansible control instance secirity group in Ansible managed instances security group...\n'
  if ! aws ec2 authorize-security-group-ingress --group-id "${resourcesList['ansibleMngdInstanceSG']}" --protocol tcp --port 22 --source-group "${resourcesList['ansibleCtrlInstanceSG']}"
  then printf 'Enabling inbound traffic on TCP port 22 (SSH) from Ansible control instance secirity group in Ansible managed instances security group failed\n' >&2 ; return 17 ; fi
  printf 'Success!\n\n'

  # Enable inbound traffic on TCP port 80 from Ansible managed instances security group in Ansible control instance secirity group
  printf 'Enabling inbound traffic on TCP port 80 from Ansible managed instances security group in Ansible control instance secirity group...\n'
  if ! aws ec2 authorize-security-group-ingress --group-id "${resourcesList['ansibleCtrlInstanceSG']}" --protocol tcp --port 80 --source-group "${resourcesList['ansibleMngdInstanceSG']}"
  then printf 'Enabling inbound traffic on TCP port 80 from Ansible managed instances security group in Ansible control instance secirity group failed\n' >&2 ; return 18 ; fi
  printf 'Success!\n\n'

  # Enable inbound traffic on TCP port 443 from Ansible managed instances security group in Ansible control instance secirity group
  printf 'Enabling outgoing traffic on TCP port 80,443 in Ansible control instance security group...\n'
  if ! aws ec2 authorize-security-group-ingress --group-id "${resourcesList['ansibleCtrlInstanceSG']}" --protocol tcp --port 443 --source-group "${resourcesList['ansibleMngdInstanceSG']}"
  then printf 'Enabling outgoing traffic on TCP port 80,443 in Ansible control instance security group failed\n' >&2 ; return 19 ; fi
  printf 'Success!\n\n'

}

run_control_instance (){
  #
  # Run control instance
  # [aws ec2 run-instances](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/run-instances.html)
  # [`--user-data`: Run commands on your Linux instance at launch](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
  # --user-data file://my_script.txt

  printf 'Running control instance...\n'
  if ! resourcesList['ansibleCtrlInstance']=$(aws ec2 run-instances --image-id "${controlInstanceImageID}" --count 1 --block-device-mappings 'DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true,VolumeSize=8,Encrypted=false}' --instance-type "${controlInstanceHWType}" --key-name 'irc168976-hw05-iaac-tools-ansible-ctrl-vm-ed25519-key' --security-group-ids "${resourcesList['ansibleCtrlInstanceSG']}" --subnet-id "${resourcesList['ansibleCtrlVMSubnet']}" --private-ip-address '10.0.0.4' --associate-public-ip-address --query 'Instances[*].InstanceId' --output text --tag-specifications 'ResourceType=instance,Tags={Key=Name,Value=irc168976-hw05-ansible-ctrl-vm}' --user-data file://irc168976-hw05-iaac-tools-ansible-ctrl-instance-startup-script.bash)
  then printf 'Running control instance failed\n' >&2 ; return 20 ; fi
  printf 'Success!\n\n'
}

run_managed_instances(){
  #
  # Run managed instances
  #
  ## The first
  printf 'Running the first managed instance...\n'
  if ! resourcesList['ansibleMngdInstanceTheFirst']=$(aws ec2 run-instances --image-id "${managedInstanceImageID}" --count 1 --block-device-mappings 'DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true,VolumeSize=8,Encrypted=false}' --instance-type "${managedInstanceHWType}" --key-name 'irc168976-hw05-iaac-tools-ansible-mngd-vm-01-ed25519-key' --security-group-ids "${resourcesList['ansibleMngdInstanceSG']}" --subnet-id "${resourcesList['ansibleMngdVMsSubnet']}" --private-ip-address '10.0.0.20' --query 'Instances[*].InstanceId' --output text --tag-specifications 'ResourceType=instance,Tags={Key=Name,Value=irc168976-hw05-ansible-mngd-vm-01}')
  then printf 'Running the first managed instance failed\n' >&2 ; return 21 ; fi
  printf 'Success!\n\n'
  #
  ## The second
  printf 'Running the second managed instance...\n'
  if ! resourcesList['ansibleMngdInstanceTheSecond']=$(aws ec2 run-instances --image-id "${managedInstanceImageID}" --count 1 --block-device-mappings 'DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true,VolumeSize=8,Encrypted=false}' --instance-type "${managedInstanceHWType}" --key-name 'irc168976-hw05-iaac-tools-ansible-mngd-vm-02-ed25519-key' --security-group-ids "${resourcesList['ansibleMngdInstanceSG']}" --subnet-id "${resourcesList['ansibleMngdVMsSubnet']}" --private-ip-address '10.0.0.21' --query 'Instances[*].InstanceId' --output text --tag-specifications 'ResourceType=instance,Tags={Key=Name,Value=irc168976-hw05-ansible-mngd-vm-02}')
  then printf 'Running the second managed instance failed\n' >&2 ; return 22 ; fi
  printf 'Success!\n\n'
  #
  ## The third
  printf 'Running the third managed instance...\n'
  if ! resourcesList['ansibleMngdInstanceTheThird']=$(aws ec2 run-instances --image-id "${managedInstanceImageID}" --count 1 --block-device-mappings 'DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true,VolumeSize=8,Encrypted=false}' --instance-type "${managedInstanceHWType}" --key-name 'irc168976-hw05-iaac-tools-ansible-mngd-vm-03-ed25519-key' --security-group-ids "${resourcesList['ansibleMngdInstanceSG']}" --subnet-id "${resourcesList['ansibleMngdVMsSubnet']}" --private-ip-address '10.0.0.22' --query 'Instances[*].InstanceId' --output text --tag-specifications 'ResourceType=instance,Tags={Key=Name,Value=irc168976-hw05-ansible-mngd-vm-03}')
  then printf 'Running the third managed instance failed\n' >&2 ; return 23 ; fi
  printf 'Success!\n\n'
}

wait_control_instance_to_get_running_state(){
  printf 'Waiting for the control instance to enter the running state.'
  # wait while instance become in the running state
  while status=$(aws ec2 describe-instances --filter "Name=instance-id,Values=${resourcesList['ansibleCtrlInstance']}" --query "Reservations[*].Instances[*].State.Name" --output text) && [[ "${status}" != 'running' ]] ; do
    sleep 15
    printf '.'
  done
  if [[ "${status}" == 'running' ]] ; then
    printf '\nAnsible control instance has become running state\n'
    return 0
  else
    printf 'The process of becoming the Ansible control instance into running state failed \n' >&2
    return 1
  fi
}

clear_control_instance_source_dest_check_attribute(){
  # Turn off source-dest check to make instance a NAT gateway
  printf 'Turning off source-dest check to make instance a NAT gateway...\n'
  if ! aws ec2 modify-instance-attribute --instance-id "${resourcesList['ansibleCtrlInstance']}" --source-dest-check 'Value=false'
  then printf 'Turning off source-dest check failed\n' >&2 ; return 24 ; fi
  printf 'Success!\n\n'
}

configure_nat_function_on_control_instance(){

  clear_control_instance_source_dest_check_attribute && \
  add_default_route_for_managed_subnet

}

get_control_instance_ip_and_set_up_local_ssh_config() {
  # Getting control instance IP address:
  timeout=$(date --date="+2 minute" '+%s')
  printf 'Getting control instance IP address...\n'
  while lastRemainder=$((${timeout} - $(date '+%s'))) && [[ ${lastRemainder} -ge 0 ]] && \
    resourcesList['ansibleCtrlInstancePublicIPValue']=$(aws ec2 describe-instances --filter "Name=instance-id,Values=${resourcesList['ansibleCtrlInstance']}" --query "Reservations[*].Instances[*].PublicIpAddress" --output text) && \
    [[ ! ${resourcesList['ansibleCtrlInstancePublicIPValue']} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] ; do
    printf '.'
    sleep 5
  done

  printf '\n'

  if [[ ! ${resourcesList['ansibleCtrlInstancePublicIPValue']} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] ; then printf 'Looks like the operation of Getting control instance IP address failed\n' >&2 ; fi

## Add SSH control instance connect configuration into SSH local user config file
cat <<IRC168976_HW05_CONTROL_INSTANCE_CONNECTION_SETTINGS >> ~/.ssh/config.new
# irc168976-hw05 Ansible Control Instance (node)
Host irc168976-hw05-iaac-tools-ansible-ctrl-instance
HostName ${resourcesList['ansibleCtrlInstancePublicIPValue']}
User ubuntu
Port 22
IdentityFile ~/.ssh/irc168976-hw05-iaac-tools-ansible-ctrl-vm-ed25519-key
IdentitiesOnly yes

IRC168976_HW05_CONTROL_INSTANCE_CONNECTION_SETTINGS

  cat ~/.ssh/config >> ~/.ssh/config.new

  mv -v ~/.ssh/config.new ~/.ssh/config

  # Getting ssh server public keys from control instance and place them into local user known_hosts file
  timeout=$(date --date="+2 minute" '+%s')
  printf 'Getting ssh server public keys from control instance and placing them into local user known_hosts file...\n'
  while lastRemainder=$((${timeout} - $(date '+%s'))) && [[ ${lastRemainder} -ge 0 ]] && \
    [[ $(ssh-keyscan -v -t ed25519 -p 22 \
            "${resourcesList['ansibleCtrlInstancePublicIPValue']}" | \
            tee --append ~/.ssh/known_hosts | \
          grep --count --fixed-strings "${resourcesList['ansibleCtrlInstancePublicIPValue']}" ) -le 0 ]]; do
    printf '.'
    sleep 5
  done
  if [[ ${lastRemainder} -le 0 ]] ; then printf 'Looks like the operation of Getting ssh server public keys from control instance and placing them into local user known_hosts file failed\n' >&2 ; fi
}

copy_managed_instances_ssh_private_keys_to_control_instance(){
  ifsBackup=${IFS}
  while IFS=; read keyFileName ; do
    # Setting the mode for original key file
    chmod -v =0600 "${keyFileName}"
    # Copying ssh private keys to control instance to acces managed nodes from it
    # preserving file attributes and mode while copying
    printf 'Copying file `%s`...\n' "${keyFileName}"
    if ! scp -p "${keyFileName}" "irc168976-hw05-iaac-tools-ansible-ctrl-instance:/home/ubuntu/.ssh/"
    then
      printf 'The operation of copying the file `%s` failed\n' "${keyFileName}"
    else
      printf 'Success!\n'
    fi
  done < <(find "${HOME}/.ssh/" -type f -iname 'irc168976-hw05-iaac-tools-ansible-mngd-vm-0*-ed25519-key')
  IFS=${ifsBackup}
}

add_managed_instances_ssh_server_public_keys_to_control_instance(){
  # create control instance ssh settings file
  touch ctrl_instance_ssh_config.prepend
  # managed instance IPs list
  managedInstanceIPsList=()
  
  managedInstanceIDsList=( \
    ${resourcesList['ansibleMngdInstanceTheFirst']} \
    ${resourcesList['ansibleMngdInstanceTheSecond']} \
    ${resourcesList['ansibleMngdInstanceTheThird']} \
  )

  for instanceId in ${managedInstanceIDsList[@]} ; do
    timeout=$(date --date="+1 minute" '+%s')
    # get info about the IP address and key name of the instance
    while read managedInstanceIP managedInstanceKeyFileName < \
          <(aws ec2 describe-instances --instance-ids "${instanceId}" \
              --query 'Reservations[*].Instances[*].{keyName:KeyName,intIp:PrivateIpAddress}' --output text) && \
              [[ $(( ${timeout} - $(date '+%s') )) -ge 0 ]] ; do
      if [[ -n "${managedInstanceIP}" && \
            -n "${managedInstanceKeyFileName}" ]] ; then break ; fi
      sleep 5
    done
    managedInstanceAliasForSSHConfig="${managedInstanceKeyFileName/#irc168976-hw05-iaac-tools-/}"
    managedInstanceAliasForSSHConfig="${managedInstanceAliasForSSHConfig/%-ed25519-key/}"
# append control instance ssh settings fragment with particular managed instance connection settings to control instance ssh settings file
cat <<SSH_MANAGED_INSTANCE_CONNECTION_SETTINGS >> ctrl_instance_ssh_config.prepend
# irc168976-hw05 Ansible Managed Instance (node) ${managedInstanceAliasForSSHConfig} 
Host ${managedInstanceAliasForSSHConfig}
HostName ${managedInstanceIP}
User ubuntu
Port 22
IdentityFile ~/.ssh/${managedInstanceKeyFileName}
IdentitiesOnly yes
SSH_MANAGED_INSTANCE_CONNECTION_SETTINGS
    managedInstanceIPsList+=("${managedInstanceIP}")
  done

  # launch remote command on control instance to add a managed instance ssh server public keys to remote user ssh known_hosts file 
  # wait until public keys will be got from all three managed instances
  ssh irc168976-hw05-iaac-tools-ansible-ctrl-instance 'retries=0 ; while [[ ${retries} -le 6 && $(ssh-keyscan -t ed25519 -p 22 '"${managedInstanceIPsList[@]}"' | tee /home/ubuntu/.ssh/known_hosts | grep --fixed-strings --count "$(printf '\''%s\n'\'' '"${managedInstanceIPsList[@]}"' )") -lt 3 ]] ; do sleep 10 ; retries=$(( retries + 1 )) ; done'

  #
  # Copy Control instance SSH settings file to control instance
  if [[ -f ctrl_instance_ssh_config.prepend ]] ; then
    scp -p "ctrl_instance_ssh_config.prepend" "irc168976-hw05-iaac-tools-ansible-ctrl-instance:/home/ubuntu/.ssh/" && \
    ssh irc168976-hw05-iaac-tools-ansible-ctrl-instance \
          'cd /home/ubuntu/.ssh/ && if [[ -f config ]] ; then cat config >> ctrl_instance_ssh_config.prepend ; fi && mv -v ctrl_instance_ssh_config.prepend config' && \
        rm -v ctrl_instance_ssh_config.prepend
  fi
  # --query 'Reservations[*].Instances[*].KeyName,Reservations[*].Instances[*].PrivateIpAddress'
  #  done

}


copy_ansible_inventory_and_artifacts_to_the_control_instance(){
  objectNamesToCopy=(\
    'irc168976-hw05-iaac-tools-ansible-inventory.ini' \
    'irc168976-hw05-iaac-tools-ansible-playbook.yaml' \
    'roles' \
  )
  if ssh irc168976-hw05-iaac-tools-ansible-ctrl-instance 'mkdir -p "${HOME}/hw05-ansible/"' ; then   
    for anObjectName in "${objectNamesToCopy[@]}" ; do
      copyRecursively=
      if [[ -e "${anObjectName}" ]] ; then
        if [[ -d "${anObjectName}" ]] ; then
          copyRecursively='-r'
        fi
      else
        printf 'WARNING in (%s): the file or folder with the name\n`%s`\n does not exist\n' \
                "${FUNCNAME[0]}" "${anObjectName}" >&2
        continue
      fi
      scp ${copyRecursively} "${anObjectName}" 'irc168976-hw05-iaac-tools-ansible-ctrl-instance:/home/ubuntu/hw05-ansible/'
    done
  else
    printf 'WARNING in (%s): an error occured when trying to create the directory `hw05-ansible` on the control instance\n' \
            "${FUNCNAME[0]}" >&2
    return 1
  fi
  return 0
}

launch_ansible_playbook (){

  displayHorizontalRuler

  printf 'Wait up to two minutes until `ansible-playbook` will be found in the ${PATH}'
  retries=0
  while [[ ${retries} -le 12 ]] && \
            ! ssh irc168976-hw05-iaac-tools-ansible-ctrl-instance 'which ansible-playbook' ; do
    retries=$(( retries + 1 ))
    printf '.'
    sleep 10
  done

  printf '\n'

  printf 'Display ansible inventory file information that is copied to the control instance\n'

  ssh irc168976-hw05-iaac-tools-ansible-ctrl-instance \
      'cd ./hw05-ansible/ && ansible-inventory --inventory-file irc168976-hw05-iaac-tools-ansible-inventory.ini --list'

  if ! ssh irc168976-hw05-iaac-tools-ansible-ctrl-instance \
      'cd ./hw05-ansible/ && ansible-playbook --inventory ./irc168976-hw05-iaac-tools-ansible-inventory.ini ./irc168976-hw05-iaac-tools-ansible-playbook.yaml' ; then

    printf 'WARNING in (%s): an error occured when trying to launch ansible playbook on the control instance\n' \
            "${FUNCNAME[0]}" >&2

    return 1
  fi

  return 0

}

show_summary_information (){

  displayHorizontalRuler

  printf 'To connect to Ansible control instance use the following command:\n'
  printf '\n\tssh -v irc168976-hw05-iaac-tools-ansible-ctrl-instance\n'

  displayHorizontalRuler

  printf 'The list of created resources:\n'
  declare -p resourcesList

}

propose_to_clean_up_resources(){

  displayHorizontalRuler

  if [[ -f "$(make_cleanup_script_file_path_and_name)" ]] ; then
    printf 'Looks like the ansible playbook has been run successfully\n'
    printf 'so there is no future need in the deployed resources.\n'
    while true; do
      printf 'Would you like to clean up deployed resources? (y/n) '
      read -n 1 -r answer
      case ${answer} in 
        [yY] ) printf '\nStarting the cleanup process\n'
          "$(make_cleanup_script_file_path_and_name)"
          break;;
        [nN] ) printf '\nYou can clean up the resources later by launching the script with the following name:\n`%s`\n' \
                      "$(make_cleanup_script_file_path_and_name)"
          break;;
        * ) printf '\nInvalid response\n';;
      esac
    done
  fi
}

main () {
  create_vpc_and_subnets && \
  create_internet_gateway && \
  attach_internet_gateway_to_vpc && \
  create_route_table_and_routes && \
  create_security_groups_and_ingress_rules && \
  run_control_instance && \
  run_managed_instances && \
  wait_control_instance_to_get_running_state && \
  get_control_instance_ip_and_set_up_local_ssh_config && \
  configure_nat_function_on_control_instance && \
  copy_managed_instances_ssh_private_keys_to_control_instance && \
  add_managed_instances_ssh_server_public_keys_to_control_instance && \
  copy_ansible_inventory_and_artifacts_to_the_control_instance && \
  launch_ansible_playbook
  theDeploymentResult=${?}

  show_summary_information

  make_and_show_clean_up_script_contents
  if [[ "${theDeploymentResult}" -eq 0 ]] ; then
    propose_to_clean_up_resources
  fi
}

set -o xtrace
set -o verbose

main