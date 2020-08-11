#!/usr/bin/with-contenv bashio
# ==============================================================================
# Community bashio::io Add-ons: Homebridge
# Configures the Avahi daemon
# ==============================================================================
# shellcheck disable=SC1091

readonly AVAHI_CONFIG='/etc/avahi/avahi-daemon.conf'
declare interfaces
declare hostname

# Determine interface to use for Avahi
if bashio::config.has_value 'avahi_interfaces'; then
    interfaces=$(bashio::config 'avahi_interfaces')
else
    interfaces=$(ip route show default \
        | awk -vORS=, '/default/ {print $5}' \
        | sed 's/,$/\n/'
    )
    bashio::log.debug "Detected Avahi interfaces: ${interfaces}"
fi
sed -i "s/#allow-interfaces=.*/allow-interfaces=hassio,${interfaces}/" \
    "${AVAHI_CONFIG}"

# Find the hostname
if bashio::config.has_value 'avahi_hostname'; then
    hostname=$(bashio::config 'avahi_hostname')
else
    hostname=$(bashio::info.hostname)
    bashio::log.debug "Detected Avahi hostname: ${hostname}"
fi
sed -i "s/host-name=.*/host-name=${hostname}/" "${AVAHI_CONFIG}"

# Set the domainname
if bashio::config.has_value 'avahi_domainname'; then
    sed -i "s/domain-name=.*/domain-name=$(bashio::config 'avahi_domainname')/" \
        "${AVAHI_CONFIG}"
fi

# Disable IPV6?
if bashio::config.false 'enable_ipv6'; then
    sed -i "s/use-ipv6=.*/use-ipv6=no/" "${AVAHI_CONFIG}"
    sed -i "s/publish-aaaa-on-ipv4=.*/publish-aaaa-on-ipv4=no/" "${AVAHI_CONFIG}"
    sed -i "s/publish-a-on-ipv6=.*/publish-a-on-ipv6=no/" "${AVAHI_CONFIG}"
    bashio::log.debug 'Disabled IPV6 in the Avahi daemon'
fi

# Remove some problematic Avahi service files
rm -f /etc/avahi/services/*
