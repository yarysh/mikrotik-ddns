:global publicIP

:local getCurrentIP do={
    :return [/ip cloud get public-address]
}

:local updateDNS do={
    :local baseURL "https://api.cloudflare.com/client/v4"
    :local domain ""
    :local recordID ""
    :local zoneID ""
    :local token ""

    /tool fetch http-method=put mode=https output=none \ 
    http-header-field="Authorization:Bearer $token,Content-Type:application/json" \ 
    url="$baseURL/zones/$zoneID/dns_records/$recordID" \ 
    http-data="{\"type\":\"A\",\"name\":\"$domain\",\"ttl\":120,\"content\":\"$1\",\"proxied\":true}"
}

:local updateFirewall do={
    :local baseURL "https://api.hetzner.cloud/v1"
    :local firewallID ""
    :local token ""

    /tool fetch http-method=post mode=https output=none \ 
    http-header-field="Authorization:Bearer $token,Content-Type:application/json" \ 
    url="$baseURL/firewalls/$firewallID/actions/set_rules" \ 
    http-data="{\"rules\":[{\"description\":\"Allow all TCP\",\"direction\":\"in\",\"protocol\":\"tcp\",\"port\":\"any\",\"source_ips\":[\"$1/32\"]},{\"description\":\"Allow all UDP\",\"direction\":\"in\",\"protocol\":\"udp\",\"port\":\"any\",\"source_ips\":[\"$1/32\"]},{\"description\":\"Allow all ICMP\",\"direction\":\"in\",\"protocol\":\"icmp\",\"source_ips\":[\"$1/32\"]}]}"
}


# Step 1. Check current IP
/system/leds set 0 type=on
:local currentIP [$getCurrentIP]
/system/leds set 0 type=off

:if ($currentIP = $publicIP) do={
    :log info "[DDNS] public IP is the same, nothing to do"
    /system/leds set 2 type=on
    /system/leds set 2 type=off
    /system/leds set 4 type=on
    /system/leds set 4 type=off
    /quit
}

:log info "[DDNS] public IP has been changed from '$publicIP' to '$currentIP'"
:set publicIP $currentIP

# Step 2. Change IP on Cloudflare DNS
/system/leds set 2 type=on
:log info "[DDNS] changing IP on Cloudflare DNS..."
$updateDNS $publicIP
:log info "[DDNS] IP on Cloudflare DNS has been changed to '$publicIP'"
/system/leds set 2 type=off

# Step 3. Change IP for Hetzner Firewall
/system/leds set 4 type=on
:log info "[DDNS] changing IP on Hetzner Firewall..."
$updateFirewall $publicIP
:log info "[DDNS] IP on Hetzner Firewall has been changed to '$publicIP'"
/system/leds set 4 type=off
