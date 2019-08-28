script "block_all" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  touch block_all-done
  # Block all tcp requests to 80 and 443
  #iptables -A INPUT -s 10.0.244.144 -j ACCEPT
  iptables -A INPUT -s 10.0.0.4 -j DROP
  iptables -A INPUT -s 10.0.0.17 -j DROP
  iptables -A INPUT -s 10.0.0.55 -j DROP
  iptables -A INPUT -s 10.0.0.10 -j DROP
  iptables -A INPUT -s 10.0.200.33 -j DROP
  iptables -A INPUT -s 10.0.208.64 -j DROP
  iptables -A INPUT -s 10.0.24.5 -j DROP
  EOH
  not_if "test -e /tmp/block_all-done"
end