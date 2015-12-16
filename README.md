# LibreNMS_Auto_Install
This uses Puppet to automatically install LibreNMS.

# Installation
```
git clone https://github.com/clay584/LibreNMS_Auto_Install.git
cd LibreNMS_Auto_Install
sudo -s
./install_librenms.sh
```

# Testing
This has only been tested on Centos 7.  It is not fully idempotent, but it is close.  I am still working on making it fully idempotent.
