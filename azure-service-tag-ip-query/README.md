# Azure Service Tag IP Query Tool

This tool allows you to query the public IP address list for any Azure Service Tag in a specified region and subscription. It also supports listing all available Service Tag names in a region.

## Features
- Query all public IPs for a given Azure Service Tag
- Output results in CSV or JSON format
- List all Service Tag names in a region

## Prerequisites
- Python 3.9+
- Azure SDK for Python (`azure-identity`, `azure-mgmt-network`)
- Azure account with permission to query network resources

## Installation
```sh
pip install azure-identity azure-mgmt-network
```

## Usage

### Query IPs for a Service Tag
```sh
python azure_service_tag_ip_query.py --service-tag AzureFrontDoor.Frontend --location japaneast --subscription-id <your-subscription-id> --output csv
```
- `--service-tag`: The Service Tag name (default: AzureFrontDoor.Frontend)
- `--location`: Azure region (default: japaneast)
- `--subscription-id`: Your Azure Subscription ID
- `--output`: Output format, `csv` or `json` (default: csv)

### List All Service Tag Names
```sh
python azure_service_tag_ip_query.py --list-tags --location japaneast --subscription-id <your-subscription-id>
```

## Example Output
#### CSV
```
ip_prefix
13.107.246.40/32
13.107.213.40/32
...
```
#### JSON
```
[
  "13.107.246.40/32",
  "13.107.213.40/32",
  ...
]
```

## License
MIT
