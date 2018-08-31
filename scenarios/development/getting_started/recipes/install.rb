script "install_getting_started" do
    interpreter "bash"
    user "root"
    cwd "/tmp"
    code <<-EOH
    cd /tmp
    git clone https://github.com/edurange/scenario-getting-started.git 
    cd /tmp/scenario-getting-started
    ./install
    EOH
end
