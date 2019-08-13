script "nat_motd" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF"
                   ___                                          ___                       
                  (   )        .-.                             (   )   .-.                
    .--.     .--.  | | .-.    ( __)___ .-.  .--.    .--.   .-.. | |_  ( __).--. ___ .-.   
  /  _  \\  /  _  \\ | |/   \\   (''"(   )   \\/    \\  /    \\ /    (   __)(''"/    (   )   \\  
 . .' `. ;. .' `. ;|  .-. .    | | |  .-. |  .-. ;|  .-. ' .-,  | |    | |  .-. |  .-. .  
 | '   | || '   | || |  | |    | | | |  | |  |(___|  | | | |  . | | ___| | |  | | |  | |  
 _\\_`.(____\\_`.(___| |  | |    | | | |  | |  |    |  |/  | |  | | |(   | | |  | | |  | |  
(   ). '.(   ). '. | |  | |    | | | |  | |  | ___|  ' _.| |  | | | | || | |  | | |  | |  
 | |  `\\ || |  `\\ || |  | |    | | | |  | |  '(   |  .'.-| |  ' | ' | || | '  | | |  | |  
 ; '._,' '; '._,' '| |  | |    | | | |  | '  `-' |'  `-' | `-'  ' `-' ;| '  `-' | |  | |  
  '.___.'  '.___.'(___)(___)  (___(___)(___`.__,'  `.__.'| \\__.' `.__.(___`.__.(___)(___) 
                                                         | |                              
                                                        (___)                             

*************************************************************************************************************
Welcome to SSH Inception. The goal is to answer all questions by exploring the local network at 10.0.0.0/27
Your are currently at the NAT Instance your journey will begin when you login into the following address.

Unless otherwise noted, you will be using the same password that brought you here.

To begin: ssh 10.0.0.5

For every instance you login to you will be greeted with instructions. Each machine will give you a list of 
useful commands to solve each challenge. Use man pages to help find useful options for commands. For example
if the instructions say to use the command 'ssh' entering 'man ssh' will print the man page.

This message is located in your home folder in a file called 'message'.

*************************************************************************************************************

EOF
)

while read player; do
  player=$(echo -n $player)
  cd /home/$player
  echo "$message" > message
  chmod 404 message
  echo 'cat message' >> .bashrc
done </root/edurange/players
  EOH
end