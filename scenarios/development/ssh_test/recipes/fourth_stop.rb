script "fourth_stop" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH

message=$(cat << "EOF"

 /$$$$$$$$                              /$$     /$$              /$$$$$$   /$$                        
| $$_____/                             | $$    | $$             /$$__  $$ | $$                        
| $$     /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$  | $$$$$$$       | $$  \\__//$$$$$$    /$$$$$$   /$$$$$$ 
| $$$$$ /$$__  $$| $$  | $$ /$$__  $$|_  $$_/  | $$__  $$      |  $$$$$$|_  $$_/   /$$__  $$ /$$__  $$
| $$__/| $$  \\ $$| $$  | $$| $$  \\__/  | $$    | $$  \\ $$       \\____  $$ | $$    | $$  \\ $$| $$  \\ $$
| $$   | $$  | $$| $$  | $$| $$        | $$ /$$| $$  | $$       /$$  \\ $$ | $$ /$$| $$  | $$| $$  | $$
| $$   |  $$$$$$/|  $$$$$$/| $$        |  $$$$/| $$  | $$      |  $$$$$$/ |  $$$$/|  $$$$$$/| $$$$$$$/
|__/    \\______/  \\______/ |__/         \\____/ |__/  |__/       \\______/   \\____/  \\______/ | $$____/ 
                                                                                            | $$      
                                                                                            | $$      
                                                                                            |__/      


****************************************************************************************************

There is loose ftp server on the network. Find some useful credentials there to to help
decrypt your next password. Read the ftp man page!

(The file on the ftp server will give you credentials to use when running decryptpass. The files
in this directory will not help you get to the ftp server.)

Helpful commands: nmap, ftp - ls, man

****************************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player

  echo "$message" > message
  chmod 404 message
  echo 'cat message' >> .bashrc

  # change password
  password=$(edurange-get-var user $player fourth_stop_password)
  echo -e "${password}\\n${password}" | passwd $player
  
  # encrypt fifth stop password
  password=$(edurange-get-var user $player fifth_stop_password)
  echo $password > passfile
  openssl aes-256-cbc -e -pass pass:$(edurange-get-var instance fifth_stop_password_key) -in passfile -out encryptedpassword 
  chown $player:$player encryptedpassword
  chmod 400 encryptedpassword
  rm passfile

  echo -e "#!/bin/bash
openssl aes-256-cbc -d -in encryptedpassword -out password
if [ $? > 0 ]; then
  chmod 400 password
  cat password
fi" > decryptpass
  chmod 505 decryptpass

  echo $(edurange-get-var user $player secret_fourth_stop) > flag
  chown $player:$player flag
  chmod 400 flag
done </root/edurange/players

# block traffic from ThirdStop. players must find a way around this
iptables -A INPUT -s 10.0.0.13 -j DROP
EOH
end
