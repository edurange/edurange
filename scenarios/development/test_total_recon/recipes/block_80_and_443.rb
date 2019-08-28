script "block_80_and_443" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  touch block_80_443-done
  # Block all tcp requests to 80 and 443
  iptables -A INPUT -p tcp --destination-port 443 -j DROP
  iptables -I INPUT -p tcp --destination-port 80 -j DROP
  EOH
  not_if "test -e /tmp/block_80_443-done"
end