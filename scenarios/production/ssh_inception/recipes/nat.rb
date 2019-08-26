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

Welcome to SSH Inception! The goal is to explore the local network at 10.0.0.0/27. 


On this network there are 7 instances whose IP addresses are currently hidden from you on the EDURange
website; your goal is to access each instance using the 'ssh' command. 

On each of these 7 instances, if you list the contents of the home directory (~) --by simply using the 'ls' 
command-- you will see at least two files: 'flag' and 'message'.

The 'flag' file contains a string you will use to answer the corresponding questions on the EDURange website.

The 'message' file is the message that is displayed immediately after logging in; this message contains hints 
helpful for identifying and solving challenges to get to the next instance. 

The bottom of the message contains a helpful commands section; the commands here are useful, if not 
necessary, for solving the challenges. Reading the manual pages for each command will: 1) explain how to use 
the command, and 2) offer even more hints for identifying and solving challenges.

To get to the linux manual page for any command, simply type 'man' followed by the command name. For example,
to see the manual page for the command 'ssh', entering 'man ssh' will print the manual page.

If you want to redisplay the 'message' file at any point while on that instance just enter ‘cat ~/message’ 
into the terminal.


You are currently at the NAT (Network Address Translation) gateway of you journey; this is where the public
IP address translates to the private IP addresses on this local network. If your connection to EDURange 
breaks while playing, you will need to reconnect to the NAT instance first to regain access to the local 
network (like you just did!). 

Unless otherwise noted, you will be using the same credentials (username, password) you used to access the
NAT Instance.

Let's Start Playing!!! Have fun!

Information you need to access StartingLine:

command: 'ssh' 
IP adress: '10.0.0.5' 
password: not changed

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