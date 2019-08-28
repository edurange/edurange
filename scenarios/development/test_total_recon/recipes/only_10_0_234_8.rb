script "only_10_0_234_8" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  touch only_5-done
  echo "ALL: ALL" > /etc/hosts.deny
  echo "ALL: localhost" > /etc/hosts.allow
  echo "sshd: 10.0.234.8" > /etc/hosts.allow
  EOH
  not_if "test -e /tmp/only_5-done"
end