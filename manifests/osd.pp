#Ceph::osd will prepare and online devices in $::ceph::osd_devices
class ceph::osd ($osd_devices,$mon_nodes_names,$osd_bootstrap_key) {

  firewall {'010 ceph-osd allow':
    chain  => 'INPUT',
    dport  => 6800-6810,
    proto  => 'tcp',
    action => accept,
  }

  if $::osd_status == "down" {
    if member($mon_nodes_names,$::hostname) {
      case $::mon_status {
        "synced": {
          exec { 'clean and prepare osd disk':
            command => "sgdisk --zap-all -- /dev/${osd_devices} && partprobe /dev/${osd_devices} && ceph-disk-prepare --cluster ceph -- /dev/${osd_devices}",
            logoutput => on_failure
          } 
        }
      }
    } else {

      file {"osd bootstrap key":
        path    => "/var/lib/ceph/bootstrap-osd/ceph.keyring",
        ensure  => present,
        content => template('ceph/osd_bootstrap_key.erb')
      } ->
      exec { 'clean and prepare osd disk':
        command => "sgdisk --zap-all -- /dev/${osd_devices} && partprobe /dev/${osd_devices} && ceph-disk-prepare --cluster ceph -- /dev/${osd_devices}",
        logoutput => on_failure,
        require  => File['osd bootstrap key']
      }
    }
  }
}
