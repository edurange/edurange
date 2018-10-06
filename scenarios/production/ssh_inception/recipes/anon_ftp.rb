script "anon_ftp" do
  interpreter "bash"
  flags "-x"
  user "root"
  cwd "/tmp"

  code <<-EOH
  apt-get install vsftpd
  service vsftpd stop
  mkdir /var/ftp
  chown -hR ftp:ftp /var/ftp
  chmod 555 /var/ftp
  pass=$(edurange-get-var instance fifth_stop_password_key)
echo -e "ip: 10.0.0.17
decryption_password: ${pass}" > /var/ftp/hint
chmod 444 /var/ftp/hint
  echo -e "listen=YES
" > /etc/vsftpd.conf
  echo -e "local_enable=YES
" >> /etc/vsftpd.conf
  echo -e "anonymous_enable=YES
" >> /etc/vsftpd.conf
  echo -e "write_enable=NO
" >> /etc/vsftpd.conf
  echo -e "anon_root=/var/ftp
" >> /etc/vsftpd.conf
  service vsftpd start
  touch /tmp/test-file

  if [ -f /etc/init.d/ssh ]
  then
  service ssh stop
  fi
  if [ ! -f /etc/init.d/ssh ]
  then
  service sshd stop
  fi
  EOH
end
