#ceph::keystone will configure keystone with ceph parts
class ceph::keystone (
  $pub_ip = $::ceph::rgw_pub_ip,
  $adm_ip = $::ceph::rgw_adm_ip,
  $int_ip = $::ceph::rgw_int_ip,
  $directory = '/etc/ceph/nss',
  $swift_store_tenant = $::ceph::swift_store_tenant,
  $swift_store_user   = $::ceph::swift_store_user,
  $swift_store_key    = $::ceph::swift_store_key,
  $rgw_listen_port    = $::ceph::rgw_listen_port,
) {
  if str2bool($::keystone_conf) {
#    package { 'libnss3-tools' :
#      ensure => 'latest'
#    }
#    file { "${directory}":
#      ensure  => "directory",
#      require => Package['ceph'],
#    }
#    exec {"creating OpenSSL certificates":
#      command => "openssl x509 -in /etc/keystone/ssl/certs/ca.pem -pubkey  \
#      | certutil -d ${directory} -A -n ca -t 'TCu,Cu,Tuw' && openssl x509  \
#      -in /etc/keystone/ssl/certs/signing_cert.pem -pubkey | certutil -A -d \
#      ${directory} -n signing_cert -t 'P,P,P'",
#      require => [File["${directory}"], Package['libnss3-tools']]
#    } ->
#    exec {"copy OpenSSL certificates":
#      command => "scp -r /etc/ceph/nss/* ${rados_GW}:/etc/ceph/nss/ && ssh ${rados_GW} '/etc/init.d/radosgw restart'",
#    }
    keystone_service { 'swift':
      ensure      => present,
      type        => 'object-store',
      description => 'Openstack Object-Store Service',
      notify      => Service['openstack-keystone'],
    }
    
    keystone_endpoint { "swift":
      ensure       => present,
      region       => "RegionOne",
      public_url   => "http://${pub_ip}:${rgw_listen_port}/swift/v1",
      admin_url    => "http://${adm_ip}:${rgw_listen_port}/swift/v1",
      internal_url => "http://${int_ip}:${rgw_listen_port}/swift/v1",
      notify       => Service['openstack-keystone'],
    }

    keystone_user { $swift_store_user:
      ensure   => present,
      password => $swift_store_key,
      email    => "${swift_store_user}@localhost",
      tenant   => $swift_store_tenant,
    } ->
   
    keystone_user_role { "${swift_store_user}@${swift_store_tenant}":
      ensure  => present,
      roles   => 'admin',
    }
 
 
    service { 'openstack-keystone':
      enable => true,
      ensure => 'running',
    }
  }
}
