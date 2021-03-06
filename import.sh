DP_HOST=$1
DP_PORT=$2
DP_ADMIN=$3
DP_PASS=$4
DOMAIN=$5
SCP_HOST=$6
SCP_USER=$7
SCP_PASS=$8
NUM_ARGS=$#

BACKUP_FILENAME=${DP_HOST}-${DOMAIN}-export.zip

## Create deployment policies in Target DataPower
## Create import package in Target DataPower
## Import configuration to Target DataPower
INFILE=${DP_HOST}-${DOMAIN}-import.cmd
OUTFILE=${DP_HOST}-${DOMAIN}-import.txt

display_usage() {
    echo -e "\nUsage:\n $0 dp_host_or_ip dp_ssh_port dp_admin dp_pass dp_domain scp_host scp_user scp_pass\n"
}

main() {
  # check whether user had supplied -h or --help . If yes display usage
  if [[ ( ${NUM_ARGS} == "--help") ||  ${NUM_ARGS} == "-h" ]]; then
    display_usage
    exit 0
  fi
  # if wrong number of  arguments supplied, display usage
  if [[ ${NUM_ARGS} -ne 8 ]]; then
    display_usage
    exit 1
  fi
  import
}

import() {

## Generate cmd and execute
cat<<EOF >$INFILE
${DP_ADMIN}
${DP_PASS}

switch $DOMAIN;
co;
deployment-policy "WP_Deployment_Policy"
  filter */default/access/snmp
  filter */default/config/deployment
  filter */default/mgmt/rest-mgmt
  filter */default/mgmt/ssh
  filter */default/mgmt/telnet
  filter */default/mgmt/web-mgmt
  filter */default/mgmt/xml-mgmt
  filter */default/network/dns
  filter */default/network/host-alias
  filter */default/network/interface
  filter */default/network/link-aggregation
  filter */default/network/network
  filter */default/network/nfs-client
  filter */default/network/nfs-dynamic-mounts
  filter */default/network/nfs-static-mount
  filter */default/network/ntp-service
  filter */default/network/smtp-server-connection
  filter */default/network/vlan
  filter */default/system/system
exit;

import-package "WP_Import_Package"
  source-url "temporary:///${BACKUP_FILENAME}"
  import-format ZIP
  overwrite-files
  overwrite-objects
  deployment-policy WP_Deployment_Policy
  local-ip-rewrite
  no auto-execute
exit;
write mem;
y

copy scp://${SCP_USER}@${SCP_HOST}/${BACKUP_FILENAME} temporary:///${BACKUP_FILENAME};
${SCP_PASS}
import-execute WP_Import_Package
write mem;
y
del temporary:///${BACKUP_FILENAME};

no import-package "WP_Import_Package";
no deployment-policy "WP_Deployment_Policy"
write mem;
y
EOF
ssh -p $DP_PORT -T $DP_HOST < $INFILE > $OUTFILE
cat $OUTFILE
## End
}

main
