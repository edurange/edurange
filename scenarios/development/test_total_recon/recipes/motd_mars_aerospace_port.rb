script "motd_mars_aerospace_port" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  wget https://raw.githubusercontent.com/jacqueque/test_total_recon/master/motd_mars_aerospace_port -O /etc/motd
  for each_home in $(ls /home/)
    do cat /etc/motd > /home/$each_home/instructions.txt
  done

  touch /etc/mars_only
  wget https://github.com/edurange/scenario-total-recon/raw/master/mars_only -O /etc/mars_only
  echo "cat ~/instructions.txt" >> /etc/bash.bashrc

  EOH
end
