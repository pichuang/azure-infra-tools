#!/bin/bash

ENV_FILE="0-az-vm-protect.env"
#
# Load Environment Variables
#
if [ ! -f ${ENV_FILE} ]
then
  export $(cat ${ENV_FILE} | xargs)
fi

set -a && source ${ENV_FILE} && set +a

#
# Debug Mode
#
if [ ${DEBUG_MODE} == "true" ]
then
  # Show debug echo messages
  export PS4='+\e[01;32m[${BASH_SOURCE}:${FUNCNAME[0]}:${LINENO}]\e[00m'
  set -x
fi

# Print the current timestamp and purpose of the script
echo "-----------------------------------------------------------------------"
echo "Azure VM Protection Script - $(date)"
echo "-----------------------------------------------------------------------"

# Initialize arrays
subscriptions=()
resource_groups=()
vm_names=()
os_disks=()
data_disks=()

#
# Read CSV File
#
# Ignore lines starting with '#'
# Ignore first line
# Ignore empty lines
#
read_csv_file() {
  while IFS=',' read -r subscription resource_group vm_name
  do
    subscriptions+=("$subscription")
    resource_groups+=("$resource_group")
    vm_names+=("$vm_name")
  done < <(tail -n +2 "${VM_PROJECT_CSV}" | grep -v '^#' | grep -v '^[[:space:]]*$')
}

read_csv_file

# Function to display arrays in a table format
display_table() {
  {
    printf "%s,%s,%s,%s,%s\n" "Subscription" "Resource Group" "VM Name" "OS Disk" "Data Disk"
    for i in "${!subscriptions[@]}"; do
      printf "%s,%s,%s," "${subscriptions[i]}" "${resource_groups[i]}" "${vm_names[i]}"
      # find os disk for the VM
      os_disk=$(az vm show --name "${vm_names[i]}" --resource-group "${resource_groups[i]}" --subscription "${subscriptions[i]}" --query "storageProfile.osDisk.name" -o tsv)
      # find data disks for the VM
      data_disk=$(az vm show --name "${vm_names[i]}" --resource-group "${resource_groups[i]}" --subscription "${subscriptions[i]}" --query "storageProfile.dataDisks[*].name" -o tsv)

      # Check if os_disk is empty
      if [ -z "${os_disk}" ]; then
        echo "Error: OS disk not found for VM ${vm_names[i]}"
        continue
      fi

      # if data disks are not empty, display them in the same row
      if [ -n "${data_disk}" ]; then
        os_disks+=("${os_disk}")
        printf "xxxxx ${os_disks}"
        data_disks+=("${data_disk}")
        printf "%s,%s\n" "${os_disk}" "${data_disk}"
      else
        os_disks+=("${os_disk}")
        printf "%s\n" "${os_disk}"
      fi
    done
  } | column -t -s ','
}

# Call the function to display the table
display_table

# Function to Show Snapshot
show_vm_snapshot() {
    local subscription="$1"
    local resource_group="$2"
    local vm_name="$3"
    echo "-----------------------------------------------------------------------"
    echo "Showing snapshot for ${vm_name} in ${resource_group} in ${subscription}"

    az snapshot show --name ${vm_name} --resource-group ${resource_group} --subscription ${subscription}
}

create_vm_snapshot() {
    local subscription="$1"
    local resource_group="$2"
    local vm_name="$3"
    local disk_name="$4"

    snapshot_name="${vm_name}-${disk_name}-${VM_SNAPSHOT_POSTFIX}"
    source_id=$(az disk show --name ${disk_name} --resource-group ${resource_group} --subscription ${subscription} --query "id" -o tsv)

    echo "-----------------------------------------------------------------------"
    echo "Creating snapshot ${snapshot_name} for disk ${disk_name} of VM ${vm_name} in ${resource_group} in ${subscription}"
    echo "Source ID: ${source_id}"

    az snapshot create \
        --name ${snapshot_name} \
        --source ${source_id} \
        --resource-group ${resource_group} \
        --subscription ${subscription} \
        --public-network-access Disabled \
        --network-access-policy DenyAll \
        --incremental true
}


echo "OS Disks: ${os_disks[@]}"
echo "Data Disks: ${data_disks[@]}"


# for i in "${!subscriptions[@]}"; do
#   create_vm_snapshot "${subscriptions[i]}" "${resource_groups[i]}" "${vm_names[i]}" "${os_disks[i]}"
# done
