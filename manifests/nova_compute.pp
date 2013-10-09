#ceph::nova_compute will configure the nova_compure parts if present
class ceph::nova_compute (
  $rbd_secret_uuid = $::ceph::rbd_secret_uuid,
  $volume_driver   = $::ceph::volume_driver,
  $rbd_pool        = $::ceph::rbd_pool,
  $rbd_user        = $::ceph::rbd_user
) {
  file { 'generate secret xml template':
    #TODO: use mktemp
    path    => '/tmp/secret.xml',
    content => template('ceph/secret.erb')
  }

  nova_config {
        'DEFAULT/volume_driver':     value => $volume_driver;
        'DEFAULT/rbd_pool':          value => $rbd_pool;
        'DEFAULT/rbd_user':          value => $rbd_user;
        'DEFAULT/rbd_secret_uuid':   value => $rbd_secret_uuid;
  }

  file { 'Create client.admin key for compute':
      path    => "/etc/ceph/ceph.client.admin.keyring",
      ensure  => link,
      target => "/etc/ceph/ceph.client.tmp.keyring"
  } ->
  exec { 'define secret':
    #TODO: clean this command up
    command => 'virsh secret-set-value --secret $( \
        virsh secret-define --file /tmp/secret.xml | \
        egrep -o "[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}") \
        --base64 $(ceph auth get-key client.admin)',
    require => File['/tmp/secret.xml'],
    unless  => "virsh secret-get-value $rbd_secret_uuid | grep -q `ceph auth get-key client.admin`",
    returns => [0,1],
 }
 if ! defined('nova::compute') {
   service {"${::ceph::params::service_nova_compute}":
     ensure     => "running",
     enable     => true,
     hasstatus  => true,
     hasrestart => true,
     subscribe  => Exec['Set value']
   }
 }
}
