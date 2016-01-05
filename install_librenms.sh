#!/bin/bash

. ~/.bashrc

DIR=$(dirname $(readlink -f $0))

echo "***"
echo "*** Installing prerequisites for LibreNMS installation script..."
echo "***"
sleep 5

# Import Puppetlabs GPG Key
rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
# Install Puppet Repo
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum history sync
# Install puppet
yum install puppet-agent -y
# Install puppet mysql module
puppet module install puppetlabs-mysql
# Install puppet VCS module
puppet module install puppetlabs-vcsrepo
# Install puppet pear module
puppet module install rafaelfc-pear

echo "*******************************************************************************************"
echo "*******************************************************************************************"
echo "*******************************************************************************************"
echo "***"
echo "*** This script will install LibreNMS.  Please answer the following questions..."
echo "***"
echo "*******************************************************************************************"
echo "*******************************************************************************************"
echo "*******************************************************************************************"
echo
while true
do
    read -p "Do you want to install the database on this server? (yes/no):" install_db
    echo
    if [ "$install_db" == "yes" ] || [ "$install_db" == "no" ] ; then
        break
    fi
done

while true
do
    read -p "Do you want to install the NMS on this server? (yes/no):" install_nms
    echo
    if [ "$install_nms" == "yes" ] || [ "$install_nms" == "no" ] ; then
        break
    fi
done

if [ "$install_db" == "yes" ] ; then

    read -p "Enter the MySQL bind address (localhost if DB and NMS the on same server, 0.0.0.0 if NMS will be on a different server):" libre_db_bind_addr

    export FACTER_LIBRE_DB_BIND_ADDR=$libre_db_bind_addr

    while true
    do
        read -s -p "Enter the MySQL root password for this installation:" mysql_root_pass
        echo
        read -s -p "Enter the MySQL root password for this installation (again):" mysql_root_pass2
        echo
        [ "$mysql_root_pass" = "$mysql_root_pass2" ] && break
        echo "Passwords don't match. Please try again."
    done
    export FACTER_MYSQL_ROOT_PASS=$mysql_root_pass

    read -p "Enter the LibreNMS database name:" libre_db_name

    export FACTER_LIBRE_DB_NAME=$libre_db_name

    read -p "Enter the LibreNMS MySQL username:" libre_db_user

    export FACTER_LIBRE_DB_USER=$libre_db_user

    while true
    do
        read -s -p "Enter the LibreNMS MySQL password:" libre_db_pass
        echo
        read -s -p "Enter the LibreNMS MySQL password (again):" libre_db_pass2
        echo
        [ "$libre_db_pass" = "$libre_db_pass2" ] && break
        echo "Passwords don't match. Please try again."
    done
    export FACTER_LIBRE_DB_PASS=$libre_db_pass

    puppet apply $DIR/libre_db_only.pp

    echo "*******************************************************************************************"
    echo "*******************************************************************************************"
    echo "*******************************************************************************************"
    echo "***"
    echo "*** MySQL database should now installed."
    echo "***"
    echo "*******************************************************************************************"
    echo "*******************************************************************************************"
    echo "*******************************************************************************************"

fi

if [ "$install_nms" == "yes" ] ; then

    if [ "$install_db" == "yes" ] ; then
        echo "database is being installed locally. Moving on..."
        export FACTER_LIBRE_DB_HOST='localhost'
    else
        read -p "Enter the LibreNMS database hostname (enter 'localhost' if the DB and NMS will be on the same server:" libre_db_host

        export FACTER_LIBRE_DB_HOST=$libre_db_host

        read -p "Enter the LibreNMS database name:" libre_db_name

        export FACTER_LIBRE_DB_NAME=$libre_db_name

        read -p "Enter the LibreNMS MySQL username:" libre_db_user

        export FACTER_LIBRE_DB_USER=$libre_db_user

        while true
        do
            read -s -p "Enter the LibreNMS MySQL password:" libre_db_pass
            echo
            read -s -p "Enter the LibreNMS MySQL password (again):" libre_db_pass2
            echo
            [ "$libre_db_pass" = "$libre_db_pass2" ] && break
            echo "Passwords don't match. Please try again."
        done

        export FACTER_LIBRE_DB_PASS=$libre_db_pass
    fi

    read -p "Enter the fully qualified domain name of the LibreNMS server (ie = libre.domain.com):" libre_http_fqdn

    export FACTER_LIBRE_HTTP_FQDN=$libre_http_fqdn

    while true
    do
        read -s -p "Enter your SNMP community string for your environment.  If you have multiple strings, specify the most common one:" snmp_comm_string
        echo
        read -s -p "Enter your SNMP community string for your environment.  If you have multiple strings, specify the most common one (again):" snmp_comm_string2
        echo
        [ "$snmp_comm_string" = "$snmp_comm_string2" ] && break
        echo "Passwords don't match. Please try again."
    done

    export FACTER_SNMP_COMM_STRING=$snmp_comm_string

    read -p "Enter the SNMP Sys Location:" libre_snmp_location

    export FACTER_LIBRE_SNMP_LOCATION=$libre_snmp_location

    read -p "Enter the SNMP Sys Contact:" libre_snmp_contact

    export FACTER_LIBRE_SNMP_CONTACT=$libre_snmp_contact

    read -p "Enter the LibreNMS Web administrator username:" libre_web_user

    export FACTER_LIBRE_WEB_USER=$libre_web_user

    while true
    do
        read -s -p "Enter the LibreNMS Web administrator's password:" libre_web_pass
        echo
        read -s -p "Enter the LibreNMS Web administrator's password (again):" libre_web_pass2
        echo
        [ "$libre_web_pass" = "$libre_web_pass2" ] && break
        echo "Passwords don't match. Please try again."
    done

    export FACTER_LIBRE_WEB_PASS=$libre_web_pass

    read -p "Enter the LibreNMS Web administrator's email address:" libre_web_email

    export FACTER_LIBRE_WEB_EMAIL=$libre_web_email

    puppet apply $DIR/libre_nms_only.pp

    echo "*******************************************************************************************"
    echo "*******************************************************************************************"
    echo "*******************************************************************************************"
    echo "***"
    echo "*** LibreNMS should be installed.  Please go to http://${libre_http_fqdn}"
    echo "***"
    echo "*******************************************************************************************"
    echo "*******************************************************************************************"
    echo "*******************************************************************************************"

fi