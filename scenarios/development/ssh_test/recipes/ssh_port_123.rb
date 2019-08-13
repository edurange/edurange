script "port 123" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  sed -i s/"Port 22"/"Port 123"/g /etc/ssh/sshd_config
  if [ -f /etc/init.d/ssh ]
  then
  service ssh reload
  fi
  if [ ! -f /etc/init.d/ssh ]
  then
  service sshd reload
  fi
  touch /tmp/recipe-port-123-done
  EOH
  not_if "test -e /tmp/recipe-port-123-done"
end