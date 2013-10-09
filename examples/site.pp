# Global settings
Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

# Each list should contain the server hostname (hostname -s) 
$mon_nodes_names			= ['ceph-node-02','ceph-node-03']
$mon_nodes_ips				= ['10.20.0.122','10.20.0.123']
$osd_nodes_names			= ['ceph-node-01','ceph-node-02']
$rgw_nodes_names			= ['controller-1']
# IP of controller node where we will add keystone role,endpoint,etc
# or virtual IP in case of HA deployment
$controller_node_address		= '10.20.0.131'
#Apache listen port for RadosGW
$rgw_listen_port			= "8080"

# Keystone tenant that will be used by RadosGW
$swift_store_tenant  = "services"
# Keystone user that will be used by RadosGW
$swift_store_user    = "swift"
# Keystone RadosGW user password
$swift_store_key     = "swiftpassword"

# uuids for the following variables can be generated
# using uuidgen bash command

# Libvirt secret uuid
$rbd_secret_uuid			= 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455'
# Ceph cluster filesystem id which is stored in ceph.conf
$fsid					= '88696b6b-0c59-4f05-a8e4-ca99f5aa2d10'
# key used for first start of monitor service
$mon_bootstrap_key			= "AQB2f0FSAAAAABAA5lztoScdwLkHuibnUrN7dg=="
# key used for first start of osd service
$osd_bootstrap_key			= "AQDH90lSUHcqCRAATTtJgp/71DZW81LneNqhJw=="
# key that replaces default random generated client.admin
$client_admin_key			= "AQBhYElSMCwxJxAAGRuFRYJ8YDZro0Tv+h9X6g=="
# key used by rados gateway service to access mon and osd services
$radosgw_key				= "AQCWWkRSEIQcGBAAtnWO6FRpVhd6brTZhiU3zQ=="
# Keystone admin token, which will be used by RadosGW service
$rgw_keystone_admin_token		= "Gfmnn4lk"
# drive name that will be used on OSD nodes for CEPH
$osd_devices				= "sda"

node 'default' {
  class {'ceph':
      #General settings
      mon_nodes_names                  => $mon_nodes_names,
      mon_nodes_ips                    => $mon_nodes_ips,
      osd_nodes_names                  => $osd_nodes_names,
      rgw_nodes_names                  => $rgw_nodes_names,
      osd_devices                      => $osd_devices,
      controller_node_address          => $controller_node_address,
      #uuids/keys
      fsid                             => $fsid, 
      mon_bootstrap_key                => $mon_bootstrap_key,
      osd_bootstrap_key                => $osd_bootstrap_key,
      client_admin_key                 => $client_admin_key,
      radosgw_key                      => $radosgw_key,
      #ceph.conf Global settings
      osd_pool_default_size            => '2',
      osd_pool_default_min_size        => '1',
      #TODO: calculate PG numbers
      osd_pool_default_pg_num          => '100',
      osd_pool_default_pgp_num         => '100',
      #RadosGW settings
      host                             => $::hostname,
      keyring_path                     => '/etc/ceph/keyring.radosgw.gateway',
      rgw_socket_path                  => '/tmp/radosgw.sock',
      log_file                         => '/var/log/ceph/radosgw.log',
      rgw_keystone_url                 => "http://${controller_node_address}:35357",
      rgw_keystone_admin_token         => $rgw_keystone_admin_token,
      rgw_keystone_token_cache_size    => '10',
      rgw_keystone_accepted_roles      => undef, #TODO: find a default value for this
      rgw_keystone_revocation_interval => '60',
      rgw_listen_port                  => $rgw_listen_port,
      #Cinder settings
      volume_driver                    => 'cinder.volume.drivers.rbd.RBDDriver',
      rbd_pool                         => 'volumes',
      glance_api_version               => '2',
      rbd_user                         => 'admin',
      #TODO: generate rbd_secret_uuid
      rbd_secret_uuid                  => $rbd_secret_uuid,
      #Glance settings
      swift_store_auth_address         => "http://${controller_node_address}:5000/v2.0/",
      swift_store_tenant               => $swift_store_tenant,
      swift_store_user                 => $swift_user_name,
      swift_store_key                  => $swift_store_key,
      swift_store_container            => "glance",
      #Keystone settings
      rgw_pub_ip                       => "${controller_node_address}",
      rgw_adm_ip                       => "${controller_node_address}",
      rgw_int_ip                       => "${controller_node_address}",
  }
}
