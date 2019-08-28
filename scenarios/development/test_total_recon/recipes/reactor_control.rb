script "reactor_control" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  touch install_control-done
  for each_home in $(ls /home/)
    do
      #make reactor and .secret directories
      cd /home/$each_home
      mkdir reactor
      mkdir reactor/.secret
      cd reactor/.secret
      echo 5 > countdown
      echo $each_home > user
      echo "OFF" > ../reactor_state
      chown $each_home ../reactor_state
      chmod 444 ../reactor_state
      chmod 722 countdown
      chmod 744 user
      wget https://github.com/edurange/scenario-total-recon/raw/master/control_script -O ./control_script
      chmod 700 control_script
  done
  cd /tmp
  #put a file in /etc/cron.d to run each local control script as root
  echo "* * * * * root for a_home  in \\$(ls /home/); do /home/\\$a_home/reactor/.secret/control_script \\$a_home; done" > /etc/cron.d/each_home_control
  mkdir /look-in-here
  mv /bin/chmod /look-in-here/chmod
  echo "echo 5 > ~/reactor/.secret/countdown;if [ -e ~/BOOM ]; then rm -f ~/BOOM;fi" >> /etc/bash.bashrc
  echo "alias chmod='chmod;echo It looks like someone moved chmod... I wonder where it is...'" >> /etc/bash.bashrc
  EOH
  not_if "test -e /tmp/install_control-done"
end
