require 'facter'
require 'rubygems'
require 'json'
require 'socket'

Facter.add(:rados_pools) do
  setcode do

    if FileTest.exists?("/etc/ceph/ceph.conf")

      #MON port
      port = 6789

      # Getting mon nodes IPs
      File.open('/etc/ceph/ceph.conf').each do |line|
        if line =~ /^mon host/
          option, ips = line.split("=")
          $nodes = ips.split(",")
        end
      end
    end

    
    # Checking 6789 port on each mon node
    $down=0
    $nodes.each do |ip|
      ip = ip.strip
      TCPSocket.new(ip, port) rescue $down+=1
    end

    if $down.to_i >= ($nodes.length / 2).to_i
      rados_pools = false
    else
      keyring = ""
      pool_arr = []    
      cmd = ""
      if FileTest.exists?("/etc/ceph/ceph.client.admin.keyring")
        keyring = "/etc/ceph/ceph.client.admin.keyring"
      elsif FileTest.exists?("/etc/ceph/ceph.client.tmp.keyring")
        keyring = "/etc/ceph/ceph.client.tmp.keyring"
      end

     if keyring.empty?
       cmd = "rados lspools"
     else
       cmd = "rados lspools -k #{keyring}"
     end

     list = %x(#{cmd})
     list.each do |pool|
       pool_arr.push(pool.chomp!)
     end
     if pool_arr.empty?
      rados_pools = false
     else
      rados_pools = pool_arr.to_json
     end
    end
  end
end
