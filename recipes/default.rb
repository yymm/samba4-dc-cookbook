#
# Cookbook Name:: samba4
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

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

log "[3] Install Samba4 Essential"
%w{perl gcc libblkid-devel gnutls-devel readline-devel python-devel gdb pkgconfig krb5-workstation zlib-devel setroubleshoot-server libaio-devel setroubleshoot-plugins policycoreutils-python libsemanage-python setools-libs popt-devel libpcap-devel sqlite-devel libidn-devel libxml2-devel libacl-devel libsepol-devel libattr-devel keyutils-libs-devel cyrus-sasl-devel cups-devel bind-utils libxslt docbook-style-xsl}.each do |pkg|
  package pkg do
    action :install
  end
end

log "[4] Install Samba4 via official site(take a little while...)"
bash "Install Samba4" do
  not_if "ls -l /usr/local | grep samba"
  cwd "/tmp"
  code <<-EOH
    wget http://www.samba.org/samba/ftp/stable/samba-4.1.12.tar.gz
	tar zxvf samba-4.1.12.tar.gz
	cd samba-4.1.12
    ./configure
	make
	make install
	echo "export PATH=$PATH:/usr/local/samba/bin:/usr/local/samba/sbin" >> /home/vagrant/.bash_profile
	source /home/vagrant/.bash_profile
  EOH
end

log "[5] Rewrite /etc/resolv.conf"
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

log "[6] Setup a domain controller on Samba4"
bash "Setup dc" do
  # TODO: File.exist
  not_if "ls -l /usr/local/samba/etc | grep smb.conf"
  code "/usr/local/samba/bin/samba-tool domain provision --use-rfc2307 --realm=#{realm} --domain=#{domain} --server-role=dc --adminpass=#{adminpass} --function-level=2008_R2"
end

log "[7] Setup kerberos conf"
bash "Setup kerberos" do
  not_if "ls -l /etc | grep krb5.conf"
  code "ln -sf /usr/local/samba/private/krb5.conf /etc/krb5.conf"
end

log "[8] Set samba4 init script"
template "/etc/init.d/samba4" do
  source "samba4.erb"
  owner "root"
  group "root"
  mode 0755
end

log "[9] Start samba4"
bash "Start samba4" do
  code "systemctl start samba4"
end

log "[10] Change password policy"
bash "Change password policy" do
  code "/usr/local/samba/bin/samba-tool domain passwordsettings set --complexity=off --min-pwd-age=0 --min-pwd-length=0"
end

log "[11] Install DHCP server"
package "dhcp" do
  action :install
end
