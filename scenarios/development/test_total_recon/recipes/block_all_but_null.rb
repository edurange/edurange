script "block_all_but_null" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  cd /tmp
  touch block_nullconfig-done
  # IF new connections are not SYN packets, drop them
  #iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
  #Send reset for incoming fragments
  iptables -A INPUT -f -j REJECT --reject-with tcp-reset
  #Send reset for all NULL Packets
  #iptables -A INPUT -p tcp --tcp-flags ALL NONE -j REJECT --reject-with tcp-reset
  #Send reset for XMAS packets
  iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j REJECT --reject-with tcp-reset
  iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j REJECT --reject-with tcp-reset
  iptables -A INPUT -p tcp --tcp-flags ALL ALL -j REJECT --reject-with tcp-reset
  # Send reset for FIN packets
  iptables -A INPUT -p tcp --tcp-flags ALL FIN -j REJECT --reject-with tcp-reset
  EOH
  not_if "test -e /tmp/block_nullconfig-done"
end