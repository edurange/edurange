script "put_flags" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
cd /
mkdir flags
chmod 770 flags
while read player; do
  player=$(echo -n $player)
  cd /flags
  mkdir $player
  cd /flags/$player

  for i in `seq 1 9`; do
    echo $(edurange-get-var user $player flag$i) > flag$i
    chmod 400 flag$i
  done 
done </root/edurange/players

EOH
end
