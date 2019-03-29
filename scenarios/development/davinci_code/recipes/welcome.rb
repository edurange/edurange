script "welcome_script" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
message=$(cat << "EOF"

########     ###       ##     ## #### ##    ##  ######  #### 
##     ##   ## ##      ##     ##  ##  ###   ## ##    ##  ##  
##     ##  ##   ##     ##     ##  ##  ####  ## ##        ##  
##     ## ##     ##    ##     ##  ##  ## ## ## ##        ##  
##     ## #########     ##   ##   ##  ##  #### ##        ##  
##     ## ##     ##      ## ##    ##  ##   ### ##    ##  ##  
########  ##     ##       ###    #### ##    ##  ######  #### 

 ######   #######  ########  ######## 
##    ## ##     ## ##     ## ##       
##       ##     ## ##     ## ##       
##       ##     ## ##     ## ######   
##       ##     ## ##     ## ##       
##    ## ##     ## ##     ## ##       
 ######   #######  ########  ########                                                                  

*******************************************************************************************
Welcome to DaVinci_Code. The goal is to solve the cryptic messages that lay ahead.

Each checkpoint can be unlocked by executing the appropriate unlock_scene program.
The flag found in each scene will unlock the next. Unlock the first scene with 'flag0'.


At each checkpoint you will be greeted with instructions as well as a list of useful 
commands to solve each challenge. Use man pages to help find useful options for commands.
For example if the instructions say to use the command 'cat' entering 'man cat' will 
display the man page. (Sadly, it doesn't produce a chimera).

Each welcome message can be found in the appropriate directory in a file called 'message'.


Helpful commands: ls, cat, less

*******************************************************************************************

EOF
)

while read player; do
  player=$(echo -n $player)
  cd /home/$player
  chmod 770 /home/$player
  
  echo "$message" > message
  chmod 404 message
  echo 'cat message' >> .bashrc

  echo "tryme" > flag0
  chmod 704 flag0

done </root/edurange/players
  EOH
end
