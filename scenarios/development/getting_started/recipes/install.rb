script "install_getting_started" do
    interpreter "bash"
    user "root"
    cwd "/tmp"
    code <<-EOH
    cd /tmp
    git clone https://github.com/edurange/scenario-getting-started.git 
    cd /tmp/scenario-getting-started
    ./install
    rm -r /tmp/scenario-getting-started
    touch /tmp/.installed
    EOH
    not_if "test -e /tmp/.installed" 
end
