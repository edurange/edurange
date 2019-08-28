script "only_10_0_208_64" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  touch only_4-done
  echo 'ALL: ALL' > /etc/hosts.deny
  echo 'ALL: localhost' > /etc/hosts.allow
  echo 'sshd: 10.0.208.64' > /etc/hosts.allow
  EOH
  not_if "test -e /tmp/only_4-done"
end