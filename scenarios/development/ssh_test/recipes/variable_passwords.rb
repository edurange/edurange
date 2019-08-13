script "change_user_passwords_to_password_variable" do
  interpreter "bash"
  user "root"
  code <<-EOH
for f in `find /home -maxdepth 1 -type d`; do
  if [ $f != "/home" ]; then
    user=(${f##*/home/})
    file=/run/edurange/variables/$user
    if [ -f $file ]; then
      varl=`cat $file | grep -e ^password:`
      var=(${varl##*:})
      if ! [ -z "$var" ]; then
        echo "$user:$var" | chpasswd 
      fi
    fi
  fi
done
EOH
end
