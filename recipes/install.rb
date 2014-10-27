log ">>> Install Samba4.1.12"

log "[1] Install Samba4 Essential"
%w{perl gcc libblkid-devel gnutls-devel readline-devel python-devel gdb pkgconfig krb5-workstation zlib-devel setroubleshoot-server libaio-devel setroubleshoot-plugins policycoreutils-python libsemanage-python setools-libs popt-devel libpcap-devel sqlite-devel libidn-devel libxml2-devel libacl-devel libsepol-devel libattr-devel keyutils-libs-devel cyrus-sasl-devel cups-devel bind-utils libxslt docbook-style-xsl}.each do |pkg|
  package pkg do
    action :install
  end
end

log "[2] Install Samba4 via official site(take a little while...)"
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
