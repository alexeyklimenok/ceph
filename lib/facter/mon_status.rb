require 'facter'
require 'rubygems'
require 'json'

Facter.add(:mon_status) do
  setcode do
    hostname = `hostname -s`.strip
    if FileTest.exists?("/var/lib/ceph/mon/ceph-#{hostname}/keyring")
      ceph_mon_status = []
      cmd = Facter::Util::Resolution.exec("ceph daemon mon.`hostname -s` mon_status 2>/dev/null")

      if cmd
         ceph_mon_status = JSON.parse(Facter::Util::Resolution.exec("ceph daemon mon.`hostname -s` mon_status 2>/dev/null"))
      end

      if ceph_mon_status.empty?
        ceph_mon_status = "initialized"
      else
        ceph_mon_status = ceph_mon_status["quorum"]
        if ceph_mon_status.empty?
          ceph_mon_status = "not synced"
        else
          ceph_mon_status = "synced"
        end
      end
    else
      ceph_mon_status = "not initialized"
    end
  end
end
