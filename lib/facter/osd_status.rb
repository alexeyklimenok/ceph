require 'facter'
require 'rubygems'
require 'json'

Facter.add(:osd_status) do
  setcode do
    if !Dir.glob('/var/lib/ceph/osd/*/active').empty?
      osd_status = "active"
    else
      osd_status = "down"
    end
  end
end
