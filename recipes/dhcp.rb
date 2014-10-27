log ">>> Setup DHCP server"

log "[1] Install DHCP server"
package "dhcp" do
  action :install
end

# log "[2] Setup DHCP server"
#   template "" do
# end
