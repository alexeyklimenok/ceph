#ceph:glance will configure glance parts if present on the system
class ceph::glance {

  glance_api_config {
    'DEFAULT/default_store':				value => $::ceph::default_store;
    'DEFAULT/swift_store_auth_address':			value => $::ceph::swift_store_auth_address;
    'DEFAULT/swift_store_user':				value => "${::ceph::swift_store_tenant}:${::ceph::swift_store_user}";
    'DEFAULT/swift_store_key':				value => $::ceph::swift_store_key;
    'DEFAULT/swift_store_container':			value => $::ceph::swift_store_container;
    'DEFAULT/swift_store_create_container_on_put':	value => $::ceph::swift_store_create_container_on_put;
  }~> Service["${::ceph::params::service_glance_api}"]
  service { "${::ceph::params::service_glance_api}":
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
  exec { 'Create client.admin key for glance':
      command => 'ceph -k /etc/ceph/ceph.client.tmp.keyring auth get client.admin > /etc/ceph/ceph.client.admin.keyring',
      unless  => 'test -f /etc/ceph/ceph.client.admin.keyring',
      notify  => Service["${::ceph::params::service_glance_api}"],
  }
}
