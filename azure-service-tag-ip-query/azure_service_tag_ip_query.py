"""
Query Azure Service Tag Public IP List
"""
#!/usr/bin/env python3

import sys
import argparse
import json
import csv
from azure.identity import DefaultAzureCredential
from azure.mgmt.network import NetworkManagementClient

# Default values
SERVICE_TAG="AzureCloud.taiwannorth"
SUBSCRIPTION_ID="587f8045-973f-43b7-965c-d368921946a2"
LOCATION="japaneast"

parser = argparse.ArgumentParser(description="Query Azure Service Tag Public IP List")
parser.add_argument('--output', choices=['csv', 'json'], default='csv', help='Format: csv or json (default is csv)') # pylint: disable=line-too-long
parser.add_argument('--service-tag', default=SERVICE_TAG, help='Service Tag Name (default: AzureFrontDoor.Frontend)') # pylint: disable=line-too-long
parser.add_argument('--location', default=LOCATION, help='Azure region (default: japaneast)')
parser.add_argument('--subscription-id', default=SUBSCRIPTION_ID, help='Azure Subscription ID')
parser.add_argument('--list-tags', action='store_true', help='List all of Service Tag Name')
args = parser.parse_args()

if args.list_tags:
    try:
        network_client = NetworkManagementClient(DefaultAzureCredential(), args.subscription_id)
        tag_info = network_client.service_tags.list(args.location)
        print("All Service Tag Names in the region:")
        for tag in tag_info.values:
            print(tag.name)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
    sys.exit(0)

service_tag = args.service_tag
location = args.location
if not location:
    print("Location is required!")
    sys.exit(1)

credential = DefaultAzureCredential()
subscription_id = args.subscription_id
if not subscription_id:
    print("Subscription ID is required!")
    sys.exit(1)

network_client = NetworkManagementClient(credential, subscription_id)

try:
    tag_info = network_client.service_tags.list(location)
    FOUND = False
    ip_list = []
    for tag in tag_info.values:
        if tag.name.lower() == service_tag.lower():
            FOUND = True
            if hasattr(tag.properties, 'address_prefixes'):
                ip_list = tag.properties.address_prefixes
            else:
                print("Could not find address_prefixes property, please check the debug output above")
            break
    if not FOUND:
        print(f"Could not find Service Tag: {service_tag} in region {location}")
        sys.exit(1)

    if args.output == 'json':
        print(json.dumps(ip_list, ensure_ascii=False, indent=2))
    else:
        writer = csv.writer(sys.stdout)
        writer.writerow([service_tag])
        for ip in ip_list:
            writer.writerow([ip])

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
