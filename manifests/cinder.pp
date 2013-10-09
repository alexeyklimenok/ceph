#ceph::cinder will setup cinder parts if detected on the system
class ceph::cinder (
  $volume_driver      = $::ceph::volume_driver,
  $rbd_pool           = $::ceph::rbd_pool,
  $glance_api_version = $::ceph::glance_api_version,
  $rbd_user           = $::ceph::rbd_user,
  $rbd_secret_uuid    = $::ceph::rbd_secret_uuid,
) {

    Cinder_config<||> ~> Service["${::ceph::params::service_cinder_volume}" ]
    File_line<||> ~> Service["${::ceph::params::service_cinder_volume}"]

    cinder_config {
      'DEFAULT/volume_driver':           value => $volume_driver;
      'DEFAULT/rbd_pool':                value => $rbd_pool;
      'DEFAULT/glance_api_version':      value => $glance_api_version;
      'DEFAULT/rbd_user':                value => $rbd_user;
      'DEFAULT/rbd_secret_uuid':         value => $rbd_secret_uuid;
    }
     file { "${::ceph::params::service_cinder_volume_opts}":
      ensure => 'present',
    } -> file_line { 'cinder-volume.conf':
      path => "${::ceph::params::service_cinder_volume_opts}",
      line => "export CEPH_ARGS=\"--id $rbd_user\"",
    }

    exec {"create pool $rbd_pool":
      command	=> "rados -k /etc/ceph/ceph.client.tmp.keyring mkpool $rbd_pool",
      unless    => "rados -k /etc/ceph/ceph.client.tmp.keyring lspools | grep -q $rbd_pool"
    }

    exec {"Create client.$rbd_user key for cinder":
      command	=> "ceph -k /etc/ceph/ceph.client.tmp.keyring auth get client.$rbd_user > /etc/ceph/ceph.client.$rbd_user.keyring",
      unless	=> "test -f /etc/ceph/ceph.client.$rbd_user.keyring"
    }

    if ! defined(Class['cinder::volume']) {
      service { "${::ceph::params::service_cinder_volume}":
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => [Exec["Create client.$rbd_user key for cinder"],Exec["create pool $rbd_pool"]]
      }
    }
}
