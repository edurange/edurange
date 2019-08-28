script "block_all_but_ack" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  touch block_ackconfig-done
  #Accept only ACK packets
  iptables -A INPUT -p tcp --tcp-flags ALL ACK -j ACCEPT
  #Drop everything else
  iptables -A INPUT -j DROP
  EOH
  not_if "test -e /tmp/block_ackconfig-done"
end