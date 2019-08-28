script "nmap_to_sudoers" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  touch nmap_sudo-done
  for each_home in $(ls /home/)
    do echo "$each_home ALL=(root)NOPASSWD:/usr/bin/nmap" >> /etc/sudoers
  done
  EOH
  not_if "test -e /tmp/nmap_sudo-done"
end