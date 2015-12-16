######## DATABASE SERVER ########

package { 'epel-release':
    ensure => installed,
}

package { 'net-snmp':
    ensure => installed,
}

package { 'git':
    ensure => installed,
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

service { 'snmpd':
    enable      => true,
    ensure      => running,
}

class { '::mysql::server':
  root_password           => $::mysql_root_pass,
  remove_default_accounts => true,
  restart => true,
  override_options => {
  mysqld => { bind_address => "${::libre_db_bind_addr}"}
},
}

mysql::db { $::libre_db_name:
  user     => $::libre_db_user,
  password => $::libre_db_pass,
  host     => '%',
  grant    => ['ALL'],
  #sql      => '/opt/librenms/build.sql',
  #import_timeout => 900,
}
# 
service { 'mariadb.service':
    enable      => true,
    ensure      => running,
}
