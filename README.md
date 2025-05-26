
# DNS Switcher Bash Script
A lightweight, interactive bash script to manage and switch between multiple DNS providers on Linux systems. Built for users who often tinker with their networking settings and want a quick way to manage /etc/resolv.conf with backup and restore support.
# Features

- Change your system's DNS to a saved provider.

- View available DNS providers from a config file.

- Add new DNS providers easily.

- Remove DNS providers.

- Backup and restore your original /etc/resolv.conf.

- Input validation for DNS IP addresses.

- Uses a human-readable configuration file (dns_servers.conf).
##  Usage

###  Prerequisites

-   **Linux system** with root access.
    
-   `bash` shell.
    
-   Make the script executable:
    
    ```bash
    chmod +x main.sh
    ```
-   Make the script executable:
    
    ```bash
    chmod +x main.sh
    ``` 
    

----------

###  Running the Script

Run the script as root:
```bash
sudo ./bash.sh
```

## Config File Format

The `dns_servers.conf` file should be structured like this:
```ini
Google: 
nameserver1=8.8.8.8  
nameserver2=8.8.4.4

Cloudflare: 
nameserver1=1.1.1.1  
nameserver2=1.0.0.1

Quad9: 
nameserver1=9.9.9.9
``` 

-   Each provider ends with a colon (`:`).
    
-   Each DNS IP must follow the format `nameserverX=IP`.
---
##  Backup & Restore 

On first run, if no backup of `/etc/resolv.conf` is found, the script will offer to create one:

  

```bash
/etc/resolv.conf.bak
```

You can restore it any time via the menu (option 5) or manually.


## Notes
* Only works on systems using `resolv.conf` (not NetworkManager-controlled systems without adjustments).

* The script must be run as root.

* No support yet for IPv6.
* This idea came to me after seeing my friend's [repository](https://github.com/ykazemim/shecan-dns-config), which is a PowerShell-based DNS switcher for Windows. That got me thinking — why not create something similar for Linux? It was also a great opportunity to learn Bash scripting along the way.
##  License

  

MIT License — free to use, modify, and share.
