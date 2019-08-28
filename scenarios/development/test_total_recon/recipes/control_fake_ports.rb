script "control_fake_ports" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  touch fake_ports-done
  nohup nc -lk 1999 &>/dev/null &
  nohup nc -lk 103 &>/dev/null &
  nohup nc -lk 233 &>/dev/null &
  nohup nc -lk 409 &>/dev/null &
  nohup nc -lk 666 &>/dev/null &
  nohup nc -lk 1783 &>/dev/null &
  nohup nc -lk 3333 &>/dev/null &
  nohup nc -lk 1509 &>/dev/null &
  nohup nc -lk 2010 &>/dev/null &
  EOH
  not_if "test -e /tmp/fake_ports-done"
end
