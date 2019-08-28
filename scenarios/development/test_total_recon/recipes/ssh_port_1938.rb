script "ssh_port_1938" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  sed -i s/"Port 22"/"Port 1938"/g /etc/ssh/sshd_config
  if [ -f /etc/init.d/ssh ]
  then
  service ssh reload
  fi
  if [ ! -f /etc/init.d/ssh ]
  then
  service sshd reload
  fi
  EOH
end