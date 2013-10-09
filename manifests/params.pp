#These are per-OS parameters and should be considered static
class ceph::params {

  case $::osfamily {
    'RedHat': {
      $service_cinder_volume      = 'openstack-cinder-volume'
      $service_cinder_volume_opts = '/etc/sysconfig/openstack-cinder-volume'
      $service_glance_api         = 'openstack-glance-api'
      $service_glance_registry    = 'openstack-glance-registry'
      $service_nova_compute       = 'openstack-nova-compute'
      $radosgw_keyring_path       = '/etc/ceph/keyring.radosgw.gateway'
      $radosgw_auth_key           = 'client.radosgw.gateway'
      $radosgw_service            = 'ceph-radosgw'
      $radosgw_packages           = ["httpd", "mod_fastcgi", 'ceph-radosgw', 'radosgw-agent']
      # "zzzz" prefix is needed, becayse rgw.conf should be loaded last to avoid conflicts with OS dashboard 
      $radosgw_vhost_file         = '/etc/httpd/conf.d/zzzz_rgw.conf'
      $apache2_ssl                = '/etc/httpd/ssl/'
      $apache_service             = 'httpd'
      $apache_package             = 'httpd'
      $apache_conf                = '/etc/httpd/conf/httpd.conf'
      $apache_ports_conf          = '/etc/httpd/conf.d/ports.conf'

    }
    'Debian': {
      $service_cinder_volume      = 'cinder-volume'
      $service_cinder_volume_opts = '/etc/init/cinder-volume.conf'
      $servic_glance_api          = 'glance-api'
      $service_glance_registry    = 'glance-registry'
      $service_nova_compute       = 'nova-compute'
      $radosgw_keyring_path       = '/etc/ceph/keyring.radosgw.gateway'
      $radosgw_auth_key           = 'client.radosgw.gateway'
      $radosgw_service            = 'ceph-radosgw'
      $radosgw_packages           = ["apache2", "mod_fastcgi", 'ceph-radosgw', 'radosgw-agent']
      $radosgw_vhost_file         = '/etc/apache2/sites-available/rgw.conf'
      $apache2_ssl                = '/etc/apache2/ssl/'
      $apache_service             = 'apache2'
      $apache_package             = 'apache2'
      $apache_conf                = '/etc/apache2/httpd.conf'
      $apache_ports_conf          = ''


      package { ['ceph','ceph-deploy', 'pushy', ]:
        ensure => latest,
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
}
