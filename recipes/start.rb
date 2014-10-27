log ">>> Start samba"

log "[1] Stop firewalld"
service "firewalld" do
  action :stop
end

log "[2] localtime to JST"
bash "localtime to JST" do
  not_if "cat /etc/localtime | grep JST"
  code <<-EOH
    rm /etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
  EOH
end
log "[2] Rewrite /etc/resolv.conf"
template "/etc/resolv.conf" do
  source "resolv.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

realm = node['samba']['realm']
domain = node['samba']['domain']
ip = node['samba']['hostip']
adminpass = node['samba']['adminpass']

log "[3] Setup a domain controller on Samba4"
bash "Setup dc" do
  # TODO: File.exist
  not_if "ls -l /usr/local/samba/etc | grep smb.conf"
  code "/usr/local/samba/bin/samba-tool domain provision --use-rfc2307 --realm=#{realm} --domain=#{domain} --server-role=dc --adminpass=#{adminpass} --function-level=2008_R2"
end

log "[4] Setup kerberos conf"
bash "Setup kerberos" do
  not_if "ls -l /etc | grep krb5.conf"
  code "ln -sf /usr/local/samba/private/krb5.conf /etc/krb5.conf"
end

log "[5] Set samba4 init script"
template "/etc/init.d/samba4" do
  source "samba4.erb"
  owner "root"
  group "root"
  mode 0755
end

log "[6] Start samba4"
bash "Start samba4" do
  code "systemctl start samba4"
end
