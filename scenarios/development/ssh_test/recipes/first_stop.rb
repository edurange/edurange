script "message" do
  interpreter "bash"
  user "root"
  code <<-EOH
message=$(cat << "EOF"

███████╗██╗██████╗ ███████╗████████╗    ███████╗████████╗ ██████╗ ██████╗ 
██╔════╝██║██╔══██╗██╔════╝╚══██╔══╝    ██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
█████╗  ██║██████╔╝███████╗   ██║       ███████╗   ██║   ██║   ██║██████╔╝
██╔══╝  ██║██╔══██╗╚════██║   ██║       ╚════██║   ██║   ██║   ██║██╔═══╝ 
██║     ██║██║  ██║███████║   ██║       ███████║   ██║   ╚██████╔╝██║     
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝       ╚══════╝   ╚═╝    ╚═════╝ ╚═╝     
**************************************************************************************************

You found it. Well done. The next dream machine lies just a few addresses higher on your subnet.

Helpful commands: ifconfig, nmap, ssh, man

**************************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player
  echo "$message" > message
  chmod 404 message
  echo 'cat message' >> .bashrc

  echo $(edurange-get-var user $player secret_first_stop) > flag
  chown $player:$player flag
  chmod 400 flag
done </root/edurange/players
EOH
end
