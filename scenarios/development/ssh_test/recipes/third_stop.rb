script "third_stop_script" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
 code <<-EOH
message=$(cat << "EOF"

 ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄        ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌      ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
 ▀▀▀▀█░█▀▀▀▀ ▐░▌       ▐░▌ ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌     ▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌
     ▐░▌     ▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌               ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌
     ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌     ▐░█▄▄▄▄▄▄▄▄▄      ▐░▌     ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌
     ▐░▌     ▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌▐░▌       ▐░▌     ▐░░░░░░░░░░░▌     ▐░▌     ▐░▌       ▐░▌▐░░░░░░░░░░░▌
     ▐░▌     ▐░█▀▀▀▀▀▀▀█░▌     ▐░▌     ▐░█▀▀▀▀█░█▀▀ ▐░▌       ▐░▌      ▀▀▀▀▀▀▀▀▀█░▌     ▐░▌     ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀ 
     ▐░▌     ▐░▌       ▐░▌     ▐░▌     ▐░▌     ▐░▌  ▐░▌       ▐░▌               ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌          
     ▐░▌     ▐░▌       ▐░▌ ▄▄▄▄█░█▄▄▄▄ ▐░▌      ▐░▌ ▐░█▄▄▄▄▄▄▄█░▌      ▄▄▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░▌          
     ▐░▌     ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░▌      ▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌▐░▌          
      ▀       ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀        ▀▀▀▀▀▀▀▀▀▀▀       ▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀           
                                                                                                                          

****************************************************************************************************

Someone incepted the password for the next stop in one of these directories.
It sure would take a long time to look through all of them. There has to be a better way...

Even once you have the credentials (which are correct), you might have trouble logging into the 
Forth Stop. Perhaps they are blocking your IP?

Helpful commands: grep, find, cat, man, nmap

****************************************************************************************************

EOF
)
while read player; do
  player=$(echo -n $player)
  cd /home/$player

  echo "$message" > message
  chmod 404 message
  echo 'cat message' >> .bashrc

  echo $(edurange-get-var user $player secret_third_stop) > flag
  chown $player:$player flag
  chmod 400 flag

  # create & authorize ssh public key. delete players password
  echo -e "$(edurange-get-var user $player third_stop_private_key)" > id_rsa
  chmod 400 id_rsa
  ssh-keygen -y -f id_rsa > id_rsa.pub -N ''
  mkdir -p .ssh
  cat id_rsa.pub > .ssh/authorized_keys
  rm id_rsa id_rsa.pub
  passwd -d $player

  # do directories
  for i in {1..100}; do
    mkdir dir$i
    cd dir$i
    mySeedNumber=$$`date +%N`; # seed will be the pid + nanoseconds
    myRandomString=$( echo $mySeedNumber | md5sum | md5sum );
    # create our actual random string
    myRandomResult="${myRandomString:2:100}"
    echo $myRandomResult > file.txt
    cd ..
    chown -R $player:$player dir$i
  done
  cd dir`shuf -i 1-100 -n 1` 
  echo "the password is $(edurange-get-var user $player fourth_stop_password), and the ip address is 10.0.0.16" > file.txt
  chmod 400 file.txt
  chown $player:$player file.txt

done </root/edurange/players
 EOH
end
