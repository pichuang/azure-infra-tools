#! /usr/bin/env python3
# -*- coding: utf-8 -*-

"""
az-vm-maintenance.py

This script is designed to manage Azure Virtual Machine maintenance tasks. It provides functionalities to start, stop, and check the status of virtual machines within a specified resource group.

Functions:
    - start_vm: Starts a specified virtual machine.
    - stop_vm: Stops a specified virtual machine.
    - check_vm_status: Checks the current status of a specified virtual machine.
    - main: Main function to parse arguments and execute the appropriate action.

Usage:
    python az-vm-maintenance.py --action <start|stop|status> --vm-name <VM_NAME> --resource-group <RESOURCE_GROUP>

Dependencies:
    - azure-mgmt-compute: Required for managing Azure VMs.
    - azure-mgmt-resource: Required for managing Azure resources.

Ensure that you have the necessary Azure credentials configured in your environment before running this script.
"""

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

# Initialize credential
credential = DefaultAzureCredential()

def read_csv_file(csv_file: str) -> pd.DataFrame:
    """Read a CSV file and return its contents as a DataFrame.

    Args:
        csv_file (str): The path to the CSV file.

    Returns:
        pd.DataFrame: The contents of the CSV file as a DataFrame.

    Raises:
        ValueError: If the CSV file path is not set.
    """
    if csv_file is None:
        raise ValueError("CSV file path is not set. Please check the environment variable 'VM_PROJECT_CSV'.")
    result = pd.read_csv(csv_file, comment='#', skip_blank_lines=True)
    return result

def format_subscription_name(subscription_name: str) -> str:
    """Retrieve the subscription ID for a given subscription name.

    This function checks if the provided subscription name matches any
    existing subscription's display name or ID and returns the corresponding
    subscription ID.

    Args:
        subscription_name (str): The name or ID of the subscription.

    Returns:
        str: The subscription ID if found.

    Raises:
        ValueError: If the subscription name or ID is not found.
    """
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

def list_vm_details(vm_data: pd.DataFrame) -> pd.DataFrame:
    """List details of virtual machines from the provided DataFrame.

    This function iterates over each row in the DataFrame, retrieves
    the subscription ID, resource group, and VM name, and updates the
    DataFrame with the OS disk, data disk, and location of each VM.

    Args:
        vm_data (pd.DataFrame): DataFrame containing VM details.

    Returns:
        pd.DataFrame: Updated DataFrame with additional VM details.
    """

    for index in vm_data.index:
        subscription_id = format_subscription_name(
            vm_data.loc[index]['SubscriptionIdorName']
        )
        resource_group = vm_data.loc[index]['ResourceGroupName']
        vm_name = vm_data.loc[index]['VMName']

        vm_data.loc[index, 'OSDisk'] = find_os_disk(
            subscription_id, resource_group, vm_name
        )
        vm_data.loc[index, 'DataDisk'] = find_data_disk(
            subscription_id, resource_group, vm_name
        )
        vm_data.loc[index, 'Location'] = find_vm_location(
            subscription_id, resource_group, vm_name
        )
    return vm_data

def find_vm_location(subscription: str, resource_group: str, vm_name: str) -> str:
    """Retrieve the location of a virtual machine.

    Args:
        subscription (str): The subscription ID.
        resource_group (str): The resource group name.
        vm_name (str): The virtual machine name.

    Returns:
        str: The location of the virtual machine.
    """

    az_client = ComputeManagementClient(credential=credential, subscription_id=subscription)
    vm = az_client.virtual_machines.get(resource_group, vm_name)
    return vm.location

def find_os_disk(subscription: str, resource_group: str, vm_name: str) -> str:
    """Retrieve the OS disk name of a specified virtual machine.

    Args:
        subscription (str): The subscription ID.
        resource_group (str): The resource group name.
        vm_name (str): The virtual machine name.

    Returns:
        str: The name of the OS disk.
    """
    az_client = ComputeManagementClient(credential=credential, subscription_id=subscription)
    vm = az_client.virtual_machines.get(resource_group, vm_name)
    os_disk_name = vm.storage_profile.os_disk.name
    return os_disk_name

def find_data_disk(subscription: str, resource_group: str, vm_name: str) -> str:
    """Retrieve the data disk name of a specified virtual machine.

    Args:
        subscription (str): The subscription ID.
        resource_group (str): The resource group name.
        vm_name (str): The virtual machine name.

    Returns:
        str: The name of the data disk, or None if no data disk is found.
    """
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
    """Retrieve the ID of a specified disk.

    Args:
        subscription (str): The subscription ID.
        resource_group (str): The resource group name.
        disk_name (str): The name of the disk.

    Returns:
        str: The ID of the disk.
    """
    az_client = ComputeManagementClient(credential=credential, subscription_id=subscription)
    disk = az_client.disks.get(resource_group, disk_name)
    return disk.id

def snapshot_disk(subscription: str, resource_group: str, vm_name: str, disk_name: str, location: str) -> None:
    """Create a snapshot of a specified disk for a virtual machine.

    Args:
        subscription (str): The subscription ID.
        resource_group (str): The resource group name.
        vm_name (str): The virtual machine name.
        disk_name (str): The name of the disk to snapshot.
        location (str): The location of the virtual machine.

    Returns:
        None
    """
    snapshot_name = f"{vm_name}-{disk_name}-{VM_SNAPSHOT_POSTFIX}"
    print(f"{f'Create snapshot {snapshot_name} of disk {disk_name} of VM {vm_name} in resource group {resource_group}':=^50s}")
    az_client = ComputeManagementClient(
        credential=credential,
        subscription_id=subscription
    )

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

    do_snapshot = az_client.snapshots.begin_create_or_update(
        resource_group, snapshot_name, snapshot_parameters
    )
    do_snapshot.wait()
    print(f"{f'Snapshot {snapshot_name} of disk {disk_name} of VM {vm_name} in resource group {resource_group} created':=^50s}")

def backup_protection_check_vm(subscription: str, resource_group: str, vm_name: str) -> None:
    """Check if the VM has backup protection enabled

    Azure CLI command:
    az backup protection check-vm \
        --resource-group ${VM_RESOUCE_GROUP_NAME} \
        --vm ${VM_NAME}
    """
    pass

def backup_protection_enable_vm(subscription: str, resource_group: str, vm_name: str) -> None:
    """Enable backup protection for a VM."""
    pass

def main() -> None:
    """Parse command-line arguments and execute the appropriate VM maintenance action."""

    parser = argparse.ArgumentParser(description="Azure VM Maintenance", epilog="Example: az-vm-matinenance.py --check")
    parser.add_argument("--show-csv", action="store_true", help=" Only show CSV file content, do not perform any action")
    parser.add_argument("--check", action="store_true", help="Check more VM details, no snapshot")
    parser.add_argument("--snapshot", action="store_true", help="Snapshot VM disks")
    parser.add_argument("--backup", action="store_true", help="Backup VM disks to Azure Backup vault (development)")

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)
    args = parser.parse_args()

    if args.show_csv:
        #
        # Read CSV file
        #
        pd_data = read_csv_file(VM_PROJECT_CSV)

    if args.check:
        #
        # Read CSV file
        #
        pd_data = read_csv_file(VM_PROJECT_CSV)

        #
        # List VM details
        #
        pd_data = list_vm_details(pd_data)
        print(pd_data)

    if args.snapshot:
        #
        # Read CSV file
        #
        pd_data = read_csv_file(VM_PROJECT_CSV)

        #
        # List VM details
        #
        pd_data = list_vm_details(pd_data)
        print(pd_data)

        #
        # Ask for confirmation
        #
        confirm = input("Are you sure you want to snapshot the above disks? (Y/n): ")
        if confirm != 'Y':
            print("Snapshot operation cancelled.")
            sys.exit(1)

        #
        # Snapshot the disk of each VM
        #
        for index in pd_data.index:
            #
            # Get the subscription ID, resource group, VM name, OS disk, and location
            #
            subscription_id = format_subscription_name(
                pd_data.loc[index]['SubscriptionIdorName']
            )
            resource_group = pd_data.loc[index]['ResourceGroupName']
            vm_name = pd_data.loc[index]['VMName']
            os_disk = pd_data.loc[index]['OSDisk']
            location = pd_data.loc[index]['Location']

            # Snapshot the OS disk
            snapshot_disk(subscription_id, resource_group, vm_name, os_disk, location)

            # Snapshot the data disk
            if pd_data.loc[index]['DataDisk']:
                data_disk = pd_data.loc[index]['DataDisk']
                snapshot_disk(subscription_id, resource_group, vm_name, data_disk, location)

    if args.backup:
        return "Backup operation is not implemented yet."


if __name__ == "__main__":
    main()
