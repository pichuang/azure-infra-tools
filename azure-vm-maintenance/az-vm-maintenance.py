#! /usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import sys
from dotenv import dotenv_values
import pandas as pd
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.compute.models import Snapshot, DiskCreateOption, CreationData, NetworkAccessPolicy
from azure.mgmt.subscription import SubscriptionClient
from azure.mgmt.recoveryservicesbackup import RecoveryServicesBackupClient
from azure.identity import DefaultAzureCredential
from azure.core.exceptions import HttpResponseError, ResourceNotFoundError

# Read dotenv file
config = dotenv_values("0-az-vm-protect.env")
VM_PROJECT_CSV = config['VM_PROJECT_CSV']
VM_SNAPSHOT_POSTFIX = config['VM_SNAPSHOT_POSTFIX']
VAULT_RESOURCE_GROUP_NAME = config['VAULT_RESOURCE_GROUP_NAME']
VAULT_NAME = config['VAULT_NAME']
VAULT_BACKUP_POLICY = config['VAULT_BACKUP_POLICY']

# Initialize data
pd_data = pd.DataFrame()

# Initialize credential
credential = DefaultAzureCredential()

def read_csv_file(csv_file: str) -> pd.DataFrame:
    """Read CSV file and store data."""
    if csv_file is None:
        raise ValueError("CSV file path is not set. Please check the environment variable 'VM_PROJECT_CSV'.")
    result = pd.read_csv(csv_file, comment='#', skip_blank_lines=True)
    return result

def format_subscription_name(subscription_name: str) -> str:
    """Convert subscription name to subscription ID."""
    try:
        # Get the subscription ID
        subscription_client = SubscriptionClient(credential)
        subscription_list = subscription_client.subscriptions.list()

        # Convert the subscription list to a list
        for subscription_entry in subscription_list:
            # Check if the subscription name matches the input name
            if subscription_entry.display_name == subscription_name:
                return subscription_entry.subscription_id
            elif subscription_entry.subscription_id == subscription_name:
                return subscription_entry.subscription_id
        # If no match is found, raise an error
        raise ValueError(f"Subscription name or ID '{subscription_name}' not found.")
    except HttpResponseError as e:
        print(f"Error retrieving subscription ID for '{subscription_name}': {e}")
        # Log the error details for further analysis
        print(f"Code: {e.error.code}, Message: {e.error.message}")
        raise

def list_vm_details(pd_data: pd.DataFrame) -> pd.DataFrame:

    for index in pd_data.index:
        pd_data.loc[index, 'OSDisk'] = find_os_disk(format_subscription_name(pd_data.loc[index]['SubscriptionIdorName']), pd_data.loc[index]['ResourceGroupName'], pd_data.loc[index]['VMName'])
        pd_data.loc[index, 'DataDisk'] = find_data_disk(format_subscription_name(pd_data.loc[index]['SubscriptionIdorName']), pd_data.loc[index]['ResourceGroupName'], pd_data.loc[index]['VMName'])
        pd_data.loc[index, 'Location'] = find_vm_location(format_subscription_name(pd_data.loc[index]['SubscriptionIdorName']), pd_data.loc[index]['ResourceGroupName'], pd_data.loc[index]['VMName'])
    return pd_data

def find_vm_location(subscription: str, resource_group: str, vm_name: str) -> str:

    az_client = ComputeManagementClient(credential=credential, subscription_id=subscription)
    vm = az_client.virtual_machines.get(resource_group, vm_name)
    return vm.location

def find_os_disk(subscription: str, resource_group: str, vm_name: str) -> str:

    az_client = ComputeManagementClient(credential=credential, subscription_id=subscription)
    vm = az_client.virtual_machines.get(resource_group, vm_name)
    os_disk_name = vm.storage_profile.os_disk.name
    return os_disk_name

def find_data_disk(subscription: str, resource_group: str, vm_name: str) -> str:

    az_client = ComputeManagementClient(credential=credential, subscription_id=subscription)
    vm = az_client.virtual_machines.get(resource_group, vm_name)

    # check if the data disk is empty
    if vm.storage_profile.data_disks:
        #XXX: only get the first data disk
        data_disk_name = vm.storage_profile.data_disks[0].name
    else:
        data_disk_name = None

    return data_disk_name

def find_disk_id(subscription: str, resource_group: str, disk_name: str) -> str:
    az_client = ComputeManagementClient(credential=credential, subscription_id=subscription)
    disk = az_client.disks.get(resource_group, disk_name)
    return disk.id

def snapshot_disk(subscription: str, resource_group: str, vm_name: str, disk_name: str, location: str) -> None:
    """Create a snapshot of the specified disk."""
    snapshot_name = f"{vm_name}-{disk_name}-{VM_SNAPSHOT_POSTFIX}"
    print("{:=^50s}".format(f"Create snapshot '{snapshot_name}' of disk '{disk_name}' of VM '{vm_name}' in resource group '{resource_group}'"))
    az_client = ComputeManagementClient(credential=credential, subscription_id=subscription)

    # https://learn.microsoft.com/en-us/python/api/azure-mgmt-compute/azure.mgmt.compute.v2019_07_01.models.creationdata?view=azure-python
    creation_parameters = CreationData(
        create_option=DiskCreateOption.COPY,
        source_resource_id=find_disk_id(subscription, resource_group, disk_name)
    )

    snapshot_parameters = Snapshot(
        location=location,
        creation_data=creation_parameters,
        # Disable network access to the snapshot
        # https://learn.microsoft.com/en-us/python/api/azure-mgmt-compute/azure.mgmt.compute.v2020_05_01.models.networkaccesspolicy?view=azure-python
        network_access_policy=NetworkAccessPolicy.DENY_ALL,
        incremental=True
    )

    do_snapshot = az_client.snapshots.begin_create_or_update(resource_group, snapshot_name, snapshot_parameters)
    do_snapshot.wait()
    print("{:=^50s}".format(f"Snapshot '{snapshot_name}' of disk '{disk_name}' of VM '{vm_name}' in resource group '{resource_group}' created"))

# def is_vault_exists(subscription_id: str, resource_group: str, vault_name: str) -> bool:
#     """Check if the specified exists using Azure SDK."""
#     vault_client = RecoveryServicesBackupClient(credential=credential, subscription_id=subscription_id)
    
#     try:
#         vault_client.vaults.get(resource_group, vault_name)
#         vault_client.GetTieringCostOperationResultOperations()
#         return True
#     except ResourceNotFoundError:
#         return False


def backup_disk(subscription: str, resource_group: str, vm_name: str, disk_name: str, location: str) -> None:
    """Backup the specified disk to Azure Backup vault."""
    pass


def main() -> None:
    """Main function to execute the script."""

    parser = argparse.ArgumentParser(description="Azure VM Maintenance", epilog="Example: az-vm-matinenance.py --check")
    parser.add_argument("--show-csv", action="store_true", help=" Only show CSV file content, do not perform any action")
    parser.add_argument("--check", action="store_true", help="Check more VM details, no snapshot")
    parser.add_argument("--snapshot", action="store_true", help="Snapshot VM disks")
    # parser.add_argument("--backup", action="store_true", help="Backup VM disks to Azure Backup vault (development)")

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)
    args = parser.parse_args()

    if args.show_csv:
        # Read CSV file
        pd_data = read_csv_file(VM_PROJECT_CSV)
        print(pd_data)

    if args.check:
        # Read CSV file
        pd_data = read_csv_file(VM_PROJECT_CSV)
        # List VM details
        pd_data = list_vm_details(pd_data)
        print(pd_data)

    if args.snapshot:
        # Read CSV file
        pd_data = read_csv_file(VM_PROJECT_CSV)
        # List VM details
        pd_data = list_vm_details(pd_data)
        print(pd_data)

        # Ask for confirmation
        confirm = input("Are you sure you want to snapshot the above disks? (Y/n): ")
        if confirm != 'Y':
            print("Snapshot operation cancelled.")
            sys.exit(1)

        # Snapshot the disk
        for index in pd_data.index:
            snapshot_disk(format_subscription_name(pd_data.loc[index]['SubscriptionIdorName']), pd_data.loc[index]['ResourceGroupName'], pd_data.loc[index]['VMName'], pd_data.loc[index]['OSDisk'], pd_data.loc[index]['Location'])
            if pd_data.loc[index]['DataDisk']:
                snapshot_disk(format_subscription_name(pd_data.loc[index]['SubscriptionIdorName']), pd_data.loc[index]['ResourceGroupName'], pd_data.loc[index]['VMName'], pd_data.loc[index]['DataDisk'], pd_data.loc[index]['Location'])

    # if args.backup:
    #     #XXX Can not check if the vault exists

    #     # Backup all disks of all VMs
    #     for index in pd_data.index:
    #         pass


if __name__ == "__main__":
    main()
