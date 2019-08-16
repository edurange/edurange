script "instanthistory" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
sudo yum-config-manager --enable epel
sudo yum -y install redis

nohup sudo redis-server /etc/redis.conf &

wget https://github.com/edurange/instant-history/raw/master/tranquility/tranquility
chmod +x tranquility
nohup sudo ./tranquility &

#iptables -A INPUT -s 10.0.0.13 -j DROP //possibly open port 80 here? 

  EOH
end