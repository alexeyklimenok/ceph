#ceph::mon will install the ceph-mon
class ceph::mon ($mon_bootstrap_key, $osd_bootstrap_key, $client_admin_key) {
  firewall {'010 ceph-mon allow':
    chain  => 'INPUT',
    dport  => 6789,
    proto  => 'tcp',
    action => accept,
  }

  define create_pools {
    if $::rados_pools != "false" {
      $pools_array = parsejson($::rados_pools)
      if !member($pools_array,$name) {
        exec { "$name":
          command => "rados mkpool $name"
        }
      }
    }
  }

  case $::mon_status {
    "not initialized": {
      file {"generate osd bootstrap key":
        path    => "/var/lib/ceph/bootstrap-osd/ceph.keyring",
        ensure  => present,
        content => template('ceph/osd_bootstrap_key.erb')
      } -> file {"generate mon bootstrap key":
        path    => "/etc/ceph/ceph.mon.keyring",
        ensure  => present,
        content => template('ceph/mon_bootstrap_key.erb')
      } -> file { 'create mon dir':
        path    => "/var/lib/ceph/mon/ceph-$::hostname",
        ensure  => directory
      } -> file { 'create mon done':
        path    => "/var/lib/ceph/mon/ceph-$::hostname/done",
        ensure  => present
      } -> file { 'create mon sysvinit':
        path    => "/var/lib/ceph/mon/ceph-$::hostname/sysvinit",
        ensure  => present
      } -> file { 'create mon tmp dir':
        path    => "/var/lib/ceph/tmp/",
        ensure  => directory
      } -> file { 'create keyring link':
        path    => "/var/lib/ceph/tmp/ceph-$::hostname.mon.keyring",
        ensure => link,
        target => '/etc/ceph/ceph.mon.keyring'
      } -> exec { 'ceph-deploy mon create':
        command   => "ceph-mon --cluster ceph --mkfs -i $::hostname --keyring /var/lib/ceph/tmp/ceph-$::hostname.mon.keyring",
        cwd       => '/etc/ceph',
      } -> exec { 'start ceph mon service':
        command   => "/sbin/service ceph start mon.$::hostname",
      }
    }
    "initialized": {
      exec { 'start ceph mon service':
        command   => "/sbin/service ceph start mon.$::hostname",
      }
    }
    "synced":{
      exec {"reset client.admin key":
        command     => "ceph -k /etc/ceph/ceph.client.admin.keyring auth add client.admin -i /etc/ceph/ceph.client.tmp.keyring",
        unless      => "ceph -k /etc/ceph/ceph.client.tmp.keyring auth get-key client.admin 2>/dev/null",
      } ->
      exec {"update client.admin.keyring":
        command     => "ceph -k /etc/ceph/ceph.client.tmp.keyring  auth get-or-create client.admin > /etc/ceph/ceph.client.admin.keyring",
        unless      => "grep -q $client_admin_key /etc/ceph/ceph.client.admin.keyring",
      } ->
      exec {"add osd bootstrap key to keyring":
        command     => "ceph -k /etc/ceph/ceph.client.admin.keyring auth add client.bootstrap-osd -i /var/lib/ceph/bootstrap-osd/ceph.keyring",
        unless      => "ceph -k /etc/ceph/ceph.client.admin.keyring auth get client.bootstrap-osd 2>/dev/null",
      }
      if is_array($::ceph::rgw_nodes_names){

        ini_setting { "ceph-create-radosgw-keyring-on $::hostname":
          path    => $::ceph::params::radosgw_keyring_path, 
          section => $::ceph::params::radosgw_auth_key,
          setting => 'key',
          value   => $::ceph::radosgw_key,
          ensure  => present,
        } ->
        exec { "ceph-add-capabilities-to-radosgw-key-on $::hostname":
          command => "ceph-authtool -n ${::ceph::params::radosgw_auth_key} --cap osd 'allow rwx' --cap mon 'allow rw' ${::ceph::params::radosgw_keyring_path}",
        } ->
        exec { "ceph-add-radosgw-to-ceph-keyring-on $::hostname":
          command => "ceph -k /etc/ceph/ceph.client.admin.keyring auth add ${::ceph::params::radosgw_auth_key} -i ${::ceph::params::keyring_path}",
          require => [Exec["reset client.admin key"],Exec["update client.admin.keyring"]]
        } 

        create_pools {[
          ".rgw",
          ".rgw.control",
          ".rgw.gc",
          ".log",
          ".intent-log",
          ".usage",
          ".users",
          ".users.email",
          ".users.swift",
          ".users.uid",
          ".rgw.buckets"]:
          require => [Exec["reset client.admin key"],Exec["update client.admin.keyring"]]
        }
        
      }
    }
  }
}
