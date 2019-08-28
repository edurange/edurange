script "fifth_stop_script" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
 code <<-EOH
getout=$(cat << "EOF"
  ▄████ ▓█████▄▄▄█████▓    ▒█████   █    ██ ▄▄▄█████▓ ▐██▌  ▐██▌  ▐██▌  ▐██▌  ▐██▌ 
 ██▒ ▀█▒▓█   ▀▓  ██▒ ▓▒   ▒██▒  ██▒ ██  ▓██▒▓  ██▒ ▓▒ ▐██▌  ▐██▌  ▐██▌  ▐██▌  ▐██▌ 
▒██░▄▄▄░▒███  ▒ ▓██░ ▒░   ▒██░  ██▒▓██  ▒██░▒ ▓██░ ▒░ ▐██▌  ▐██▌  ▐██▌  ▐██▌  ▐██▌ 
░▓█  ██▓▒▓█  ▄░ ▓██▓ ░    ▒██   ██░▓▓█  ░██░░ ▓██▓ ░  ▓██▒  ▓██▒  ▓██▒  ▓██▒  ▓██▒ 
░▒▓███▀▒░▒████▒ ▒██▒ ░    ░ ████▓▒░▒▒█████▓   ▒██▒ ░  ▒▄▄   ▒▄▄   ▒▄▄   ▒▄▄   ▒▄▄  
 ░▒   ▒ ░░ ▒░ ░ ▒ ░░      ░ ▒░▒░▒░ ░▒▓▒ ▒ ▒   ▒ ░░    ░▀▀▒  ░▀▀▒  ░▀▀▒  ░▀▀▒  ░▀▀▒ 
  ░   ░  ░ ░  ░   ░         ░ ▒ ▒░ ░░▒░ ░ ░     ░     ░  ░  ░  ░  ░  ░  ░  ░  ░  ░ 
░ ░   ░    ░    ░         ░ ░ ░ ▒   ░░░ ░ ░   ░          ░     ░     ░     ░     ░ 
      ░    ░  ░               ░ ░     ░               ░     ░     ░     ░     ░    

EOF
)

echo "$getout" > /tmp/getout
chmod 404 /tmp/getout

message=$(cat << "EOF"

  ██████  ▄▄▄     ▄▄▄█████▓ ▄▄▄       ███▄    █   ██████     ██▓███   ▄▄▄       ██▓    ▄▄▄       ▄████▄  ▓█████ 
▒██    ▒ ▒████▄   ▓  ██▒ ▓▒▒████▄     ██ ▀█   █ ▒██    ▒    ▓██░  ██▒▒████▄    ▓██▒   ▒████▄    ▒██▀ ▀█  ▓█   ▀ 
░ ▓██▄   ▒██  ▀█▄ ▒ ▓██░ ▒░▒██  ▀█▄  ▓██  ▀█ ██▒░ ▓██▄      ▓██░ ██▓▒▒██  ▀█▄  ▒██░   ▒██  ▀█▄  ▒▓█    ▄ ▒███   
  ▒   ██▒░██▄▄▄▄██░ ▓██▓ ░ ░██▄▄▄▄██ ▓██▒  ▐▌██▒  ▒   ██▒   ▒██▄█▓▒ ▒░██▄▄▄▄██ ▒██░   ░██▄▄▄▄██ ▒▓▓▄ ▄██▒▒▓█  ▄ 
▒██████▒▒ ▓█   ▓██▒ ▒██▒ ░  ▓█   ▓██▒▒██░   ▓██░▒██████▒▒   ▒██▒ ░  ░ ▓█   ▓██▒░██████▒▓█   ▓██▒▒ ▓███▀ ░░▒████▒
▒ ▒▓▒ ▒ ░ ▒▒   ▓▒█░ ▒ ░░    ▒▒   ▓▒█░░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░   ▒▓▒░ ░  ░ ▒▒   ▓▒█░░ ▒░▓  ░▒▒   ▓▒█░░ ░▒ ▒  ░░░ ▒░ ░
░ ░▒  ░ ░  ▒   ▒▒ ░   ░      ▒   ▒▒ ░░ ░░   ░ ▒░░ ░▒  ░ ░   ░▒ ░       ▒   ▒▒ ░░ ░ ▒  ░ ▒   ▒▒ ░  ░  ▒    ░ ░  ░
░  ░  ░    ░   ▒    ░        ░   ▒      ░   ░ ░ ░  ░  ░     ░░         ░   ▒     ░ ░    ░   ▒   ░           ░   
      ░        ░  ░              ░  ░         ░       ░                    ░  ░    ░  ░     ░  ░░ ░         ░  ░
░ 

EOF
)

while read player; do
  player=$(echo -n $player)
  cd /home/$player

  echo "$message" > message
  chmod 404 message
  echo 'cat message' >> .bashrc

  # change password
  password=$(edurange-get-var user $player satans_palace_password)
  echo -e "${password}\\n${password}" | passwd $player

  str=$(edurange-get-var user $player master_string)
  msg="CONGRATS!!! You have outwitted Satans Palace, and are thus crowned a SSH INCEPTION MASTER.
  If anyone should be as silly as to ask for proof, tell them: ${str}" 

  echo "${msg}" | base64 > final_flag

  chown $player:$player *
  chmod 400 *

  echo 'cat /tmp/getout' >> .bashrc
  echo 'exit' >> .bashrc
done </root/edurange/players
  EOH
end
