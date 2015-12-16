######## NMS SERVER ########

exec { 'change-hostname':
  command      => "hostnamectl set-hostname ${::libre_http_fqdn}; systemctl restart systemd-hostnamed",
  path         => '/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
  #refreshonly => true,
}

user { 'librenms':
  comment => 'Libre NMS',
  home    => '/opt/librenms',
  ensure  => present,
  system => true,
  #shell  => '/bin/bash',
}

user { 'apache':
  ensure  => present,
  groups => 'librenms',
}

vcsrepo { '/opt/librenms':
  ensure   => present,
  provider => git,
  source   => 'https://github.com/librenms/librenms.git',
  owner => 'librenms',
  group => 'librenms',
}

package { 'php':
    ensure => installed,
}

package { 'php-cli':
    ensure => installed,
}

package { 'php-gd':
    ensure => installed,
}

package { 'php-mysql':
    ensure => installed,
}

package { 'php-snmp':
    ensure => installed,
}

package { 'php-pear':
    ensure => installed,
}

package { 'php-curl':
    ensure => installed,
}

package { 'httpd':
    ensure => installed,
}

package { 'graphviz':
    ensure => installed,
}

package { 'graphviz-php':
    ensure => installed,
}

package { 'ImageMagick':
    ensure => installed,
}

package { 'jwhois':
    ensure => installed,
}

package { 'nmap':
    ensure => installed,
}

package { 'mtr':
    ensure => installed,
}

package { 'rrdtool':
    ensure => installed,
}

package { 'MySQL-python':
    ensure => installed,
}

package { 'net-snmp-utils':
    ensure => installed,
}

package { 'net-snmp':
    ensure => installed,
}

package { 'cronie':
    ensure => installed,
}

package { 'php-mcrypt':
    ensure => installed,
}

package { 'fping':
    ensure => installed,
}

include pear

pear::package { "Net_IPv4-1.3.4": }
pear::package { "Net_IPv6-1.2.2b2": }

file { '/opt/librenms/logs':
    ensure => directory,
    owner => "apache",
    group => "apache",
}
file { '/opt/librenms/rrd':
    ensure => directory,
    owner  => "librenms",
    group  => "librenms",
    mode => '775',
}

$apache_config = @("END"/L)
    <VirtualHost *:80>
      DocumentRoot /opt/librenms/html/
      ServerName  ${::libre_http_fqdn}
      CustomLog /opt/librenms/logs/access_log combined
      ErrorLog /opt/librenms/logs/error_log
      AllowEncodedSlashes NoDecode
      <Directory '/opt/librenms/html/'>
        AllowOverride All
        Options FollowSymLinks MultiViews
      Require all granted
      </Directory>
    </VirtualHost>
    | END

file { 'apache NMS config file':
    ensure => file,
    path => '/etc/httpd/conf.d/librenms.conf',
    content => $apache_config,
}

service { 'httpd':
  enable      => true,
  ensure      => running,
}

service { 'firewalld':
  enable      => false,
  ensure      => stopped,
}

$snmp_config = @("END"/L)
    com2sec local     localhost        ${::snmp_comm_string}
    group MyROGroup  any        local
    view all    included  .1                               80
    access MyROGroup ""      any       noauth    0      all    none    none
    syslocation ${::libre_snmp_location}
    syscontact ${::libre_snmp_contact}
    dontLogTCPWrappersConnects yes
    disk / 100000
    load 12 14 14
    | END

file { '/etc/snmp/snmpd.conf':
    ensure => file,
    content => $snmp_config,
    notify  => Service['snmpd'],
}

service { 'snmpd':
    enable      => true,
    ensure      => running,
}

# Above this point takes care of the installation up until
# the user can go to http://hostname/install.php
# Everything below here will automate the remaining installation.

$config = '$config'

$libre_config = @("END"/L)
  <?php

  ## Have a look in includes/defaults.inc.php for examples of settings you can set here. DO NOT EDIT defaults.inc.php!

  ### Database config
  $config['db_host'] = "${::libre_db_host}";
  $config['db_user'] = "${::libre_db_user}";
  $config['db_pass'] = "${::libre_db_pass}";
  $config['db_name'] = "${::libre_db_name}";
  $config['db']['extension'] = 'mysqli';// mysql or mysqli

  ### Memcached config - We use this to store realtime usage
  $config['memcached']['enable']  = FALSE;
  $config['memcached']['host']    = 'localhost';
  $config['memcached']['port']    = 11211;

  // This is the user LibreNMS will run as
  //Please ensure this user is created and has the correct permissions to your install
  $config['user'] = 'librenms';

  ### Locations - it is recommended to keep the default
  #$config['install_dir']  = "/opt/librenms";

  ### This should *only* be set if you want to *force* a particular hostname/port
  ### It will prevent the web interface being usable form any other hostname
  #$config['base_url']        = "http://librenms.company.com";

  ### Enable this to use rrdcached. Be sure rrd_dir is within the rrdcached dir
  ### and that your web server has permission to talk to rrdcached.
  #$config['rrdcached']    = "unix:/var/run/rrdcached.sock";

  ### Default community
  $config['snmp']['community'] = array("${::snmp_comm_string}");

  ### Authentication Model
  $config['auth_mechanism'] = "mysql"; # default, other options: ldap, http-auth
  #$config['http_auth_guest'] = "guest"; # remember to configure this user if you use http-auth

  ### List of RFC1918 networks to allow scanning-based discovery
  #$config['nets'][] = "10.0.0.0/8";
  #$config['nets'][] = "172.16.0.0/12";
  #$config['nets'][] = "192.168.0.0/16";

  # following is necessary for poller-wrapper
  # poller-wrapper is released public domain
  $config['poller-wrapper']['alerter'] = FALSE;
  # Uncomment the next line to disable daily updates
  #$config['update'] = 0;

  # Uncomment to submit callback stats via proxy
  #$config['callback_proxy'] = "hostname:port";

  $config['fping'] = "/usr/sbin/fping";
  | END

file { '/opt/librenms/config.php':
  ensure => file,
  owner => 'apache',
  group => 'librenms',
  mode => '750',
  content => $libre_config
}

exec { 'initialize_the_database':
    command     => 'php /opt/librenms/build-base.php',
    path        => '/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
    cwd         => '/opt/librenms',
    require     => File['/opt/librenms/config.php'],
}

# Create the admin user - priv should be 10

exec { 'create_admin_user':
  command      => "php /opt/librenms/adduser.php ${::libre_web_user} ${::libre_web_pass} 10 ${::libre_web_email}",
  path         => '/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
  cwd          => '/opt/librenms',
  require     => Exec['initialize_the_database'],
}
## SELinux configuration#

package { 'policycoreutils-python':
    ensure => installed,
}

if $::selinux == false {
  notice("The SELinux mode is currently set to ${::selinux}...skipping SELinux modifications.")
} else {

  exec { 'SELinux_logs':
      command      => "semanage fcontext -a -t httpd_sys_content_t '/opt/librenms/logs(/.*)?'",
      path         => '/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
      #refreshonly => true,
  }
  exec { 'SELinux_logs2':
      command      => "semanage fcontext -a -t httpd_sys_rw_content_t '/opt/librenms/logs(/.*)?'",
      path         => '/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
      #refreshonly => true,
  }
  exec { 'SELinux_logs3':
      command      => 'restorecon -RFvv /opt/librenms/logs/',
      path         => '/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
      notify       => Service['httpd']
      #refreshonly => true,
  }
}

exec { 'add_localhost_into_monitoring':
    command      => 'php /opt/librenms/addhost.php localhost public v2c',
    path        => '/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
    require     => Exec['create_admin_user'],
    #refreshonly => true,
}

# exec { 'wait_before_service_discovery':
#     command      => 'sleep 10',
#     path        => '/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
#     require     => Exec['add_localhost_into_monitoring'],
# }

# exec { 'localhost_service_discovery':
#     command     => 'php /opt/librenms/discovery.php -h all',
#     path        => '/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin',
#     require     => Exec['wait_before_service_discovery'],
#     cwd         => '/opt/librenms'
#     #refreshonly => true,
# }

file { '/etc/cron.d/librenms':
    ensure => file,
    source => '/opt/librenms/librenms.nonroot.cron',
}
