#ceph will install ceph parts
class ceph (
      #General settings
      $mon_nodes_names			= $::hostname,  	# By default we assume that we deploy CEPH mon service only this one server
      $mon_nodes_ips                    = $::ipaddress_eth0,    # By default we will use IP of eth0 interface
      $osd_nodes_names			= $::hostname,		# By default we assume that we deploy CEPH osd service only this one server
      $rgw_nodes_names			= 'false',
      $ceph_pools                       = [ 'volumes', 'images' ],
      $osd_devices                      = split($::osd_devices_list, " "),
      $controller_node_address,
      $filestore_xattr_use_omap         = 'true',
      #TODO generate random fsid with the following bash command:
      #uuidgen 
      $fsid				= '88696b6b-0c59-4f05-a8e4-ca99f5aa2d10',
      $mon_bootstrap_key                = "AQB2f0FSAAAAABAA5lztoScdwLkHuibnUrN7dg==",
      $osd_bootstrap_key                = "AQDH90lSUHcqCRAATTtJgp/71DZW81LneNqhJw==",
      $radosgw_key                      = "AQCWWkRSEIQcGBAAtnWO6FRpVhd6brTZhiU3zQ==",
      $client_admin_key                 = "AQBhYElSMCwxJxAAGRuFRYJ8YDZro0Tv+h9X6g==",
      #ceph.conf Global settings
      $auth_supported                   = 'cephx',
      $osd_journal_size                 = '2048',
      $osd_mkfs_type                    = 'xfs',
      $osd_pool_default_size            = '2',
      $osd_pool_default_min_size        = '1',
      #TODO: calculate PG numbers
      $osd_pool_default_pg_num          = '100',
      $osd_pool_default_pgp_num         = '100',
      $cluster_network                  = "${::storage_network_range}",
      $public_network                   = "${::management_network_range}",
      #RadosGW settings
      $host                             = $::hostname,
      $keyring_path                     = '/etc/ceph/keyring.radosgw.gateway',
      $rgw_socket_path                  = '/tmp/radosgw.sock',
      $log_file                         = '/var/log/ceph/radosgw.log',
      $user                             = 'www-data',
      $rgw_keystone_url                 = "http://${cluster_node_address}:35357",
      $rgw_keystone_admin_token         = 'nova',
      $rgw_keystone_token_cache_size    = '10',
      $rgw_keystone_accepted_roles      = 'admin, Member, swiftoperator',
      $rgw_keystone_revocation_interval = '60',
      $rgw_data                         = '/var/lib/ceph/rados',
      $rgw_dns_name                     = $::hostname,
      $rgw_print_continue               = 'false',
      $rgw_listen_port                  = '8080',
      $nss_db_path                      = '/etc/ceph/nss',
      #Cinder settings
      $volume_driver                    = 'cinder.volume.drivers.rbd.RBDDriver',
      $rbd_pool                         = 'volumes',
      $glance_api_version               = '2',
      $rbd_user                         = 'admin',
      #TODO: generate rbd_secret_uuid
      $rbd_secret_uuid                  = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
      #Glance settings
      $default_store                    = 'swift',
      $swift_store_auth_address         = "http://${controller_node_address}:5000/v2.0/",
      $swift_store_tenant               = "services",
      $swift_store_user                 = "swift",
      $swift_store_key                  = "swiftpassword",
      $swift_store_container            = "glance",
      $swift_store_create_container_on_put = "True",
      #Keystone settings
      $rgw_pub_ip                       = "${controller_node_address}",
      $rgw_adm_ip                       = "${controller_node_address}",
      $rgw_int_ip                       = "${controller_node_address}",
) {

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
         cwd  => '/root',
  }

  include 'ceph::params'
  include 'ceph::selinux'

  stage {'install_ceph':}

  stage {'deploy_mon':
    require => Stage['install_ceph'],
    before  => Stage['deploy_osd']
  } 

  stage {'deploy_osd':
    require => Stage['install_ceph'],
  }
  stage {'deploy_radosgw':
    require => Stage['install_ceph']
  }

  stage {'os_integrate':
    require => Stage['install_ceph']
  }

  class install_ceph {
    if $::ceph_conf == "false" {
      $ceph_base = ['ceph', 'redhat-lsb-core','ceph-deploy', 'pushy', 'rubygem-json', 'python-ceph', 'librados2', 'librbd1']
      package { $ceph_base:
        ensure => latest,
      } ->
      file {"/etc/ceph/ceph.client.tmp.keyring":
        content   => "[client.admin]
          key = $::ceph::client_admin_key
          caps mon = \"allow *\"
          caps osd = \"allow *\"
          caps mds = \"allow\"\n",
        ensure  => present,
        require => Package[$ceph_base]
      } ->
      ceph_conf {
        'global/mon initial members':                              value => join($mon_nodes_names," ,");
        'global/mon host':                                         value => join($mon_nodes_ips, ","); 
        'global/auth supported':                                   value => $auth_supported;
        'global/fsid':                                             value => $fsid;
        'global/filestore xattr use omap':                         value => $filestore_xattr_use_omap;
        'global/osd journal size':                                 value => $osd_journal_size;
        'client.radosgw.gateway/host':				   value => $::fqdn;
        'client.radosgw.gateway/keyring':                          value => $keyring_path;
        'client.radosgw.gateway/rgw socket path':                  value => $rgw_socket_path;
        'client.radosgw.gateway/log file':                         value => $log_file;
        'client.radosgw.gateway/rgw print continue':               value => 'false';
        'client.radosgw.gateway/rgw keystone url':                 value => $rgw_keystone_url;
        'client.radosgw.gateway/rgw keystone admin token':         value => $rgw_keystone_admin_token;
        'client.radosgw.gateway/rgw keystone accepted roles':      value => $rgw_keystone_accepted_roles;
        'client.radosgw.gateway/rgw keystone token cache size':    value => $rgw_keystone_token_cache_size;
        'client.radosgw.gateway/rgw keystone revocation interval': value => $rgw_keystone_revocation_interval;
        'client.radosgw.gateway/rgw dns name':                     value => $rgw_dns_name;
      }
    }
  }
  class {'install_ceph':
    stage => 'install_ceph'
  }

  if member($mon_nodes_names,$::hostname) {
    class {'::ceph::mon':
      mon_bootstrap_key => $mon_bootstrap_key,
      osd_bootstrap_key => $osd_bootstrap_key,
      client_admin_key  => $client_admin_key,
      stage		=> 'deploy_mon'
    }
  }
  if member($osd_nodes_names,$::hostname) {
    class {'::ceph::osd':
      osd_devices	=> $osd_devices,
      osd_bootstrap_key => $osd_bootstrap_key,
      mon_nodes_names   => $mon_nodes_names,
      stage		=> 'deploy_osd'
      }
    }

  if member($rgw_nodes_names,$::hostname) {
    class {"::ceph::radosgw":
      stage             => 'deploy_radosgw',
      rgw_listen_port   => $rgw_listen_port
    }
  }

  case $::role {
    'cinder': {
      class {'ceph::cinder':
        stage             => 'os_integrate'
      }
    }
    'controller': {
      class {'ceph::glance':
        stage             => 'os_integrate'
      }
      class {'ceph::cinder':
        stage             => 'os_integrate'
      }
      class {'ceph::keystone':}
    }
    'compute': {
      class {'ceph::nova_compute':
        stage             => 'os_integrate'
      }
    }
  }
}
