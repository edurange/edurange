script "install_strace" do

  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  touch /tmp/foo
  EOH

  not_if "test -e /tmp/foo"

end