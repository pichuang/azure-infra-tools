def create_ssh_client_securely(ip_address, username, ****** private_key_path=None, skip_setup=False):
    """
    Create an SSH client to connect to a virtual machine with improved security.
    
    Args:
        ip_address (str): The IP address of the virtual machine.
        username (str): The admin username for the virtual machine.
        password (str, optional): The admin password for the virtual machine.
        private_key_path (str, optional): Path to a private key file for SSH authentication.
        skip_setup (bool): Whether to skip the setup process.
    
    Returns:
        paramiko.SSHClient: The SSH client.
    """
    try:
        client = paramiko.SSHClient()
        
        # Better host key verification method for production use
        # For testing on freshly created VMs, AutoAddPolicy is used with a warning
        if os.path.exists(os.path.expanduser('~/.ssh/known_hosts')):
            client.load_host_keys(os.path.expanduser('~/.ssh/known_hosts'))
            client.set_missing_host_key_policy(paramiko.WarningPolicy())
            logging.info("Using existing known_hosts file for host key verification")
        else:
            logging.warning("No known_hosts file found - using AutoAddPolicy for host key verification")
            logging.warning("This is insecure for production environments")
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Prefer key-based authentication if a key file is provided
        if private_key_path and os.path.isfile(os.path.expanduser(private_key_path)):
            try:
                private_key = paramiko.RSAKey.from_private_key_file(os.path.expanduser(private_key_path))
                client.connect(ip_address, username=username, pkey=private_key, timeout=30)
                logging.info(f"Connected to {ip_address} using key authentication")
            except Exception as e:
                logging.warning(f"Key authentication failed ({str(e)}), falling back to password")
                if password:
                    client.connect(ip_address, username=username, ****** timeout=30)
                else:
                    raise ValueError("Authentication failed and no password provided as fallback")
        elif password:
            client.connect(ip_address, username=username, ****** timeout=30)
            logging.warning("Using password authentication - consider using SSH keys for better security")
        else:
            raise ValueError("Either password or private_key_path must be provided")
            
        logging.debug(f"SSH connection established with {ip_address}")
        return client
    except Exception as e:
        logging.error(f"Failed to create SSH connection to {ip_address}: {e}")
        return None