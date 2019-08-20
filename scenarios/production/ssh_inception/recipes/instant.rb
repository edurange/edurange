script "instant" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
sudo yum-config-manager --enable epel
sudo yum -y install redis

nohup sudo redis-server /etc/redis.conf & 

wget https://github.com/edurange/instant-history/raw/master/tranquility/tranquility
chmod +x tranquility
nohup ./tranquility & disown

  EOH
end