  for each_home in $(ls /home/)
    do cat /etc/motd > /home/$each_home/instructions.txt
  done