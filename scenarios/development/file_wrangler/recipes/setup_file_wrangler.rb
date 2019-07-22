script "setup_file_wrangler" do
    interpreter "bash"
    user "root"
    cwd "/tmp"
    code <<-EOH
    cd /tmp
    git clone https://github.com/edurange/scenario-file-wrangler
    cd /tmp/scenario-file-wrangler
    ./setup
    rm -r /tmp/file-wrangler
    touch /tmp/.installed
    EOH
    not_if "test -e /tmp/.installed"
end
