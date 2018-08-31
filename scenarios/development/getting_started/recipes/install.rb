script "install_treasure_hunt" do
    interpreter "bash"
    user "root"
    cwd "/tmp"
    code <<-EOH
    git clone https://github.com/edurange/scenario-getting-started.git /tmp/scenario-getting-started
    cd /tmp/scenario-getting-started
    ./install
    EOH
end
