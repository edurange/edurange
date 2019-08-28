script "starting_line_script" do
  interpreter "bash"
  user "root"
  code <<-EOH
message=$(cat << "EOF"
 ___   _____  _____  ___   _____  _  _   _  ___       _      _  _   _  ___   
(  _`\\(_   _)(  _  )|  _`\\(_   _)(_)( ) ( )(  _`\\    ( )    (_)( ) ( )(  _`\\ 
| (_(_) | |  | (_) || (_) ) | |  | || `\\| || ( (_)   | |    | || `\\| || (_(_)
`\\__ \\  | |  |  _  || ,  /  | |  | || , ` || |___    | |  _ | || , ` ||  _)_ 
( )_) | | |  | | | || |\\ \\  | |  | || |`\\ || (_, )   | |_( )| || |`\\ || (_( )
`\\____) (_)  (_) (_)(_) (_) (_)  (_)(_) (_)(____/'   (____/'(_)(_) (_)(____/'

****************************************************************************************************

"It's a week the first level down. Six months the second level down, and... the third level..."

Go a level deeper. You will find the next host at 10.0.0.7. The trick is that the ssh port has been 
changed to 123. Good luck!

Helpful commands: ssh, help, man

****************************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player
  echo "$message" > message
  chmod 404 message 
  echo 'cat message' >> .bashrc

  echo $(edurange-get-var user $player secret_starting_line) > flag
  chown $player:$player flag
  chmod 400 flag

done </root/edurange/players
  EOH
end