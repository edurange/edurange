script "load_disable_firewall" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  touch disable_firewall-done
  mkdir /root/tools
  wget https://github.com/edurange/scenario-total-recon/raw/master/allow_all.sh -O /root/tools/disable_firewall.sh
  EOH
  not_if "test -e /tmp/disable_firewall-done"
end