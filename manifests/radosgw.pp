class ceph::radosgw ($rgw_listen_port = '8080'){

  package { $::ceph::params::radosgw_packages:
    ensure => installed
  }

  file { "$::ceph::params::radosgw_vhost_file":
    content => template('ceph/rgw.conf.erb'),
    notify  => Service[$::ceph::params::apache_service],
    require => Package[$::ceph::params::radosgw_packages],
  }

  file {["${::ceph::params::apache2_ssl}", '/var/lib/ceph/radosgw/ceph-radosgw.gateway', '/var/lib/ceph/radosgw', '/etc/ceph/nss']:
  ensure => "directory",
  mode   => 755,
  }
  
  file { "/var/www/s3gw.fcgi":
    content => template('ceph/s3gw.fcgi.erb'),
    require => Package[$::ceph::params::radosgw_packages],
    mode    => "+x",
  } ->
  file { "/etc/httpd/conf.d/fcgid.conf":
    ensure  => "absent"
  } ->
  exec { "fastcgi.conf":
    command => "sed -e 's/^FastCgiWrapper/#FastCgiWrapper/g;' -i /etc/httpd/conf.d/fastcgi.conf",
    onlyif  => "grep -q \"^FastCgiWrapper\" /etc/httpd/conf.d/fastcgi.conf"
  } ->

  file_line { 'RGW define NameVirtualHost':
    path => "$::ceph::params::apache_ports_conf",
    line => "NameVirtualHost *:$rgw_listen_port"
  }

  file_line { 'RGW define Apache listen port':
    path => "$::ceph::params::apache_ports_conf",
    line => "Listen 0.0.0.0:$rgw_listen_port"
  }

  file_line { 'httpd.conf ServerName':
    path => "$::ceph::params::apache_conf",
    line => "ServerName $::fqdn",
  }

  File_line<||> ~> Service[$::ceph::params::apache_service]

  exec { "add .rgw.buckets pool to Ceph Object Storage daemon":
    command => "radosgw-admin -k /etc/ceph/ceph.client.tmp.keyring pool add --pool .rgw.buckets",
    unless  => "radosgw-admin -k /etc/ceph/ceph.client.tmp.keyring pools list | grep -q .rgw.buckets"
  } 

  ini_setting { "ceph-create-radosgw-keyring-on $::hostname":
          path    => $::ceph::params::radosgw_keyring_path,
          section => $::ceph::params::radosgw_auth_key,
          setting => 'key',
          value   => $::ceph::radosgw_key,
          ensure  => present,
  } ->

  file {["${::ceph::params::radosgw_keyring_path}","/var/log/ceph/radosgw.log"]:
          ensure => 'file',
          group  => 'apache',
          owner  => 'apache',
          require => Ini_setting["ceph-create-radosgw-keyring-on $::hostname"]
        }

  service { "$::ceph::params::apache_service":
    enable => true,
    ensure => "running",
  } ->

  service {"$::ceph::params::radosgw_service":
    enable => true,
    ensure => running
  }
}
