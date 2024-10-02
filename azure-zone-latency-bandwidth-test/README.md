# Azure Zone Latency/Bandwidth Test

This script is designed to test latency and bandwidth between virtual machines (VMs) in different availability zones within an Azure region. It automates the creation of resource groups, virtual networks, network security groups, and VMs, and then runs latency and bandwidth tests using `iperf3` and `sockperf`.

## Prerequisites

- Python 3.9 or higher
- Azure CLI
- Azure SDK for Python
- `paramiko` library for SSH connections

## Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/your-repo/azure-zone-latency-test.git
    cd azure-zone-latency-test
    ```

2. Install the required Python packages:
    ```sh
    pip install -r requirements.txt
    ```

3. Ensure you are logged in to Azure CLI:
    ```sh
    az login
    ```

## Usage

### Command Line Arguments

- `--tenant`: Azure Tenant ID or Name (optional)
- `--subscription`: Azure Subscription ID (required)
- `--resource-group-name`: Resource Group Name (required)
- `--vm-type`: VM Type (default: `Standard_D8lds_v5`)
- `--location`: Azure Region (default: `southeastasia`)
- `--enable-accelerated-networking`: Enable Accelerated Networking (default: `True`)
- `--admin-username`: Admin username for the VM (default: `repairman`)
- `--admin-password`: Admin password for the VM (default: `f5Q7tjAa2XheJE8NqDRnMP`)
- `--network-cidr`: Network CIDR (default: `192.168.100.0/24`)
- `--force-delete`: Force delete the resource group (optional)
- `--run`: Run latency and bandwidth tests directly (optional)
- `--show-info`: Show VM info (IP, username, password) (optional)
- `--skip-bandwidth-test`: Skip bandwidth tests (optional)
- `--skip-latency-test`: Skip latency tests (optional)

### Examples

1. **Create Resources and Run Tests:**
    ```sh
    ./azure-zone-latency-bandwidth-test.py --subscription <your-subscription-id> --resource-group-name rg-zone-test
    ```

2. **Show VM Information:**
    ```sh
    ./azure-zone-latency-bandwidth-test.py --subscription <your-subscription-id> --resource-group-name rg-zone-test --show-info
    ```

3. **Force Delete Resource Group:**
    ```sh
    ./azure-zone-latency-bandwidth-test.py --subscription <your-subscription-id> --resource-group-name rg-zone-test --force-delete
    ```

4. **Run Only Latency Tests:**
    ```sh
    ./azure-zone-latency-bandwidth-test.py --subscription <your-subscription-id> --resource-group-name rg-zone-test --skip-bandwidth-test
    ```

5. **Run Only Bandwidth Tests:**
    ```sh
    ./azure-zone-latency-bandwidth-test.py --subscription <your-subscription-id> --resource-group-name rg-zone-test --skip-latency-test
    ```

## Output

The script will log the following information:
- Creation status of resource groups, virtual networks, network security groups, and VMs.
- Public and private IP addresses of the VMs.
- Results of latency and bandwidth tests between the VMs.

## Notes

- Ensure that the provided admin username and password meet Azure's security requirements.
- The script assumes that the `iperf3` and `sockperf` tools are available on the VMs. The script will attempt to install these tools if they are not already present.
- The script uses `paramiko` for SSH connections to the VMs. Ensure that the VMs' network security groups allow SSH access.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.