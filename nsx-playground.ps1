# Global environment variables
$nsxHost = "10.152.129.58:13433"
$nsxUser = "admin"
$nsxPass = "password1!"

# Create authentication header with base64 encoding
$EncodedAuthorization = [System.Text.Encoding]::UTF8.GetBytes($nsxUser + ':' + $nsxPass)
$EncodedPassword = [System.Convert]::ToBase64String($EncodedAuthorization)

# Construct headers with authentication data + expected Accept header (xml / json)
$headers = @{"Authorization" = "Basic $EncodedPassword"}
$headers.Add("Accept", "application/json")

# Build NSX base URI
$nsxUrl = "https://$nsxHost"

# Bypass SSL certificate verification
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


# Small Function to execute a REST operations and return the JSON response
function http-rest
{
    <#
    .SYNOPSIS
        This function establishes a connection to the NSX API
    .DESCRIPTION
        This function establishes a connection to  NSX API
    .PARAMETER method
        Specify the REST Method to use (GET/PUT/POST/DELETE)"
    .PARAMETER uri
        Specify the REST URI that identifies the resource you want to interact with
    .PARAMETER body
        Specify the body content if required (PUT/POST)
    .INPUTS
        String: REST Method to use.
        String: URI that identifies the resource
        String: Body if required
    .OUTPUTS
        JsonObject: Request result in JSON
    .LINK
        None.
    #>

    [CmdletBinding()]
    param(
        [
            parameter(
                Mandatory = $true,
                HelpMessage = "Specify the REST Method to use (GET/PUT/POST/DELETE)",
                ValueFromPipeline = $false
            )
        ]
        [String]
        $method,
        [
            parameter(
                Mandatory = $true,
                HelpMessage = "Specify the REST URI that identifies the resource you want to interact with",
                ValueFromPipeline = $false
            )
        ]
        [String]
        $uri,
        [
            parameter(
                Mandatory = $false,
                HelpMessage = "Specify the body content if required (PUT/POST)",
                ValueFromPipeline = $false
            )
        ]
        [String]
        $body = $null
    )

    Begin {
        # Build Url from supplied uri parameter
        $Url = "https://$nsxHost" + $uri
    }

    Process {
        # Build Invoke-RestMethod request
        try
        {
            if (!$body)
            {
                $HttpRes = Invoke-RestMethod -Uri $Url -Method $method -Headers $headers
            }
            else
            {
                $HttpRes = Invoke-RestMethod -Uri $Url -Method $method -Headers $headers -Body $body -ContentType "application/xml"
            }
        }
        catch {
            Write-Host -ForegroundColor Red "Error connecting to $Url"
            Write-Host -ForegroundColor Red $_.Exception.Message
        }

        # If the response to the HTTP request is OK,
        # Convert it to JSON before returning it.
        if ($HttpRes) {
            $json = $HttpRes | ConvertTo-Json
            return $json
        }
        else
        {
            Write-Host -ForegroundColor Red "Error retrieving response body for $Url"
        }
    }
    End {
        # What to do here ?
    }
}



"# Get vCenter Registration configuration"
http-rest "GET" "/api/2.0/services/vcconfig"


"# Get default vCenter Server connection status"
http-rest "GET" "/api/2.0/services/vcconfig/status"


"# Query global information"
http-rest "GET" "/api/1.0/appliance-management/global/info"

"# Query summary"
http-rest "GET" "/api/1.0/appliance-management/summary/system"


"# Query global information"
http-rest "GET" "/api/1.0/appliance-management/summary/components"

"# Query CPU"
http-rest "GET" "/api/1.0/appliance-management/system/cpuinfo"

"# Query MEM"
http-rest "GET" "/api/1.0/appliance-management/system/meminfo"

"# Query Storage"
http-rest "GET" "/api/1.0/appliance-management/system/storageinfo"

"# Query uptime"
http-rest "GET" "/api/1.0/appliance-management/system/uptime"

"# Query network details"
http-rest "GET" "/api/1.0/appliance-management/system/network"

"# Query time settings"
http-rest "GET" "/api/1.0/appliance-management/system/timesettings"

"# Query locale"
http-rest "GET" "/api/1.0/appliance-management/system/locale"

"# Query syslog"
http-rest "GET" "/api/1.0/appliance-management/system/syslogserver"

"# Query components"
http-rest "GET" "/api/1.0/appliance-management/components"

# "# Query backup settings"
# http-rest "GET" "/api/1.0/appliance-management/backuprestore/backupsettings"

# "# Query available backups"
# http-rest "GET" "/api/1.0/appliance-management/backuprestore/backups"

"# Get NSX Manager system events (10 elements)"
http-rest "GET" "/api/2.0/systemevent?startIndex=0&pageSize=10"

# "# Get NSX Manager audit logs (10 elements)"
# http-rest "GET" "/api/2.0/logging/auditlog?startIndex=0&pageSize=10"

"# Query notifications"
http-rest "GET" "/api/1.0/appliance-management/notifications"

# How to query all the IP Pools ?
# "# Query IP Pool"
# http-rest "GET" "/api/2.0/services/ipam/pools/1"


"# Query controllers"
http-rest "GET" "/api/2.0/vdn/controller"


"# Query controller logs"
# This probably requires tuning as it will download/data
# WILL NOT WORK AS IS
# http-rest "GET" "/api/2.0/vdn/controller/{controllerId}/techsupportlogs"

"# Query cluster details"
http-rest "GET" "/api/2.0/vdn/controller/cluster"



"# Get all Segment ID Ranges"
http-rest "GET" "/api/2.0/vdn/config/segments"

"# Get all network scopes"
http-rest "GET" "/api/2.0/vdn/scopes"

"# Get a network scope"
http-rest "GET" "/api/2.0/vdn/scopes/vdnscope-1"

# Configure controller syslog exporter
# TBD / FIXME
# http-rest "POST" "/api/2.0/vdn/controller/controller-1/syslog" $syslogConfig
# Request Body:
# <controllerSyslogServer>
# <syslogServer>10.135.14.236</syslogServer>
# <port>514</port>
# <protocol>UDP</protocol>
# <level>INFO</level>
# </controllerSyslogServer>

# "# Query controller syslog exporter"
# http-rest "GET" "/api/2.0/vdn/controller/controller-1/syslog"

"# Get all Segment ID Ranges"
http-rest "GET" "/api/2.0/vdn/config/segments"

"# Get a specific Segment ID Range"
http-rest "GET" "/api/2.0/vdn/config/segments/1"

# "# Reset Network Fabric Communication"
# http-rest "POST" "/api/2.0/nwfabric/configure?action=synchronize"
# FAILS WITH UNSUPPORTED MEDIA TYPE (415), nothing in the doc about the accept/content type required.

"# Query features"
http-rest "GET" "/api/2.0/nwfabric/features"

# "# Query services"
# http-rest "GET" "/api/2.0/si/deploy/cluster/<cluster-id>"

# "# Query service"
# http-rest "GET" "/api/2.0/si/deploy/cluster/<cluster-id>/service/<service-id>"


# "# Query clusters"
# http-rest "GET" "/api/2.0/si/deploy/service/<service-id>"

# "# Query agents on host"
# http-rest "GET" "/api/2.0/si/host/<host-id>/agents"

# "# Query agent details"
# http-rest "GET" "/api/2.0/si/agent/<agent-id>"

"# Get all configured switches"
http-rest "GET" "/api/2.0/vdn/switches"

"# Get configured switches on a datacenter"
http-rest "GET" "/api/2.0/vdn/switches/datacenter/datacenter-2"

"# Get specific switch"
http-rest "GET" "/api/2.0/vdn/switches/dvs-29"

"# Get all multicast ranges"
http-rest "GET" "/api/2.0/vdn/config/multicasts"


"# Get all logical switches"
http-rest "GET" "/api/2.0/vdn/scopes/vdnscope-1/virtualwires"

"# Get all logical switches on all network scopes"
http-rest "GET" "/api/2.0/vdn/virtualwires"

"# Get a logical switch definition"
http-rest "GET" "/api/2.0/vdn/virtualwires/virtualwire-1"


"# Query ARP suppression and MAC learning"
http-rest "GET" "/api/2.0/xvs/networks/virtualwire-1/features"

"# Get resources allocated (Segment IDs, multicast ranges)"
http-rest "GET" "/api/2.0/vdn/config/resources/allocated?type=segmentId&pagesize=10&startindex=0"
http-rest "GET" "/api/2.0/vdn/config/resources/allocated?type=multicastAddress&pagesize=10&startindex=10"

#
# Logical Router
#


"# Query a router"
http-rest "GET" "/api/4.0/edges/edge-1"
http-rest "GET" "/api/4.0/edges/edge-2"

"# Query interfaces"
http-rest "GET" "/api/4.0/edges/edge-1/mgmtinterface"
# http-rest "GET" "/api/4.0/edges/edge-2/mgmtinterface" (not LDR => ESG)

"# Retrieve All interfaces"
http-rest "GET" "/api/4.0/edges/edge-1/interfaces"
# http-rest "GET" "/api/4.0/edges/edge-2/interfaces" (not LDR => ESG)

"# Get interface with specific index"
http-rest "GET" "/api/4.0/edges/edge-1/interfaces/2"
# http-rest "GET" "/api/4.0/edges/edge-2/interfaces/1" (not LDR => ESG)

"# Retrieve routes"
http-rest "GET" "/api/4.0/edges/edge-1/routing/config"
http-rest "GET" "/api/4.0/edges/edge-2/routing/config"


"# Query global route => DOC IS WRONG, fixed below"
http-rest "GET" "/api/4.0/edges/edge-1/routing/config/global"
http-rest "GET" "/api/4.0/edges/edge-2/routing/config/global"

"# Query static routes"
http-rest "GET" "/api/4.0/edges/edge-1/routing/config/static"
http-rest "GET" "/api/4.0/edges/edge-2/routing/config/static"

"# Query OSPF"
http-rest "GET" "/api/4.0/edges/edge-1/routing/config/ospf"
http-rest "GET" "/api/4.0/edges/edge-2/routing/config/ospf"

"#  Query ISIS"
http-rest "GET" "/api/4.0/edges/edge-1/routing/config/isis" # no isis config
http-rest "GET" "/api/4.0/edges/edge-2/routing/config/isis" # no isis config

"# Query BGP"
http-rest "GET" "/api/4.0/edges/edge-1/routing/config/bgp" # no bgp config
http-rest "GET" "/api/4.0/edges/edge-2/routing/config/bgp" # no bgp config

"# Query bridges"
http-rest "GET" "/api/4.0/edges/edge-1/bridging/config"
http-rest "GET" "/api/4.0/edges/edge-2/bridging/config"

#
# Edge Services Gateway
#

"# Retrieve Edges"
http-rest "GET" "/api/4.0/edges/"

# Retrieve Edges by datacenter:
# GET /api/4.0/edges/?datacenter=<datacenterMoid>
# Retrieve Edges on specified tenant:
# GET /api/4.0/edges/?tenant=<tenantId>
# Retrieve Edges with one interface on specified port group:
# GET /api/4.0/edges/?pg=<pgMoId>
# Retrieve Edges with specified tenant and port group:
# GET /api/4.0/edges/?tenant=<tenant>&pg=<pgMoId>

"# Retrieve Edge details" # Same as logical Router
http-rest "GET" "/api/4.0/edges/edge-2"

"# Query all jobs"
http-rest "GET" "/api/4.0/edges/edge-1/jobs?status=all"
http-rest "GET" "/api/4.0/edges/edge-2/jobs?status=all"

"# Query active jobs"
http-rest "GET" "/api/4.0/edges/edge-1/jobs?status=active"
http-rest "GET" "/api/4.0/edges/edge-2/jobs?status=active"

"# Query firewall"
http-rest "GET" "/api/4.0/edges/edge-1/firewall/config"
http-rest "GET" "/api/4.0/edges/edge-2/firewall/config"

# "# Retrieve specific rule"
# GET https://<nsxmgr-ip>/api/4.0/edges/<edgeId>/firewall/config/rules/<ruleId>

"# Query global firewall configuration"
http-rest "GET" "/api/4.0/edges/edge-1/firewall/config/global"
http-rest "GET" "/api/4.0/edges/edge-2/firewall/config/global"

"# Query default firewall configuration"
http-rest "GET" "/api/4.0/edges/edge-1/firewall/config/defaultpolicy"
http-rest "GET" "/api/4.0/edges/edge-2/firewall/config/defaultpolicy"

"# Query firewall statistics (range is 60min per default)"
# GET https://<nsxmgr-ip>/api/4.0/edges/{edgeId}/firewall/statistics/dashboard/firewall?interval=<range>
http-rest "GET" "/api/4.0/edges/edge-1/firewall/statistics/dashboard/firewall"
http-rest "GET" "/api/4.0/edges/edge-2/firewall/statistics/dashboard/firewall"
# => Error 404 (maybe because firewall is disabled in the lab, to verify)

# "# Query statistics for a rule"
# http-rest "GET" "/api/4.0/edges/{edgeId}/firewall/statistics/{ruleId}"

"# Query SNAT and DNAT rules for a Edge Gateway"
http-rest "GET" "/api/4.0/edges/edge-2/nat/config"

"# Retrieve routes" # Same as Logical Router
http-rest "GET" "/api/4.0/edges/edge-2/routing/config"
"# Retrieve Global route" # Same as Logical Router
http-rest "GET" "/api/4.0/edges/edge-2/routing/config/global"
"# Query static routes" # Same as Logical Router
http-rest "GET" "/api/4.0/edges/edge-2/routing/config/static"

"# Retrieve load balancer configuration"
http-rest "GET" "/api/4.0/edges/edge-2/loadbalancer/config"

# "# Query LB Application profiles"
#http-rest "GET" "/api/4.0/edges/edge-2/loadbalancer/config/applicationprofiles/"
# "# Query LB Application profile Id"
# http-rest "GET" "/api/4.0/edges/edge-2/loadbalancer/config/applicationprofiles/<applicationprofileId>"
# "# Query LB Application rule"
# http-rest "GET" "/api/4.0/edges/edge-2/loadbalancer/config/applicationrules/<applicationruleId>""

# "# Query All LB Application rules" # DOC Error fix below
# http-rest "GET" "/api/4.0/edges/edge-2/loadbalancer/config/applicationrules/"


# "# Query All LB monitors" # DOC Error fix below
# http-rest "GET" "/api/4.0/edges/edge-2/loadbalancer/config/monitors/"
# "# Query LB Monitor" # Doc Error fix below
# http-rest "GET" "/api/4.0/edges/edge-2/loadbalancer/config/monitors/{monitorId}"


# "# Query virtual servers"
# http-rest "GET" "/api/4.0/edges/edge-2/loadbalancer/config/virtualservers/"
# http-rest "GET" "/api/4.0/edges/edge-2/loadbalancer/config/virtualservers/<virtualserverID>"

# "# Query all backend pools"
# http-rest "GET" "/api/4.0/edges/<edgeId>/loadbalancer/config/pools"
# http-rest "GET" "/api/4.0/edges/<edgeId>/loadbalancer/config/pools/<poolID>"

# "# Retrieve load balancer statistics"
# http-rest "GET" "/api/4.0/edges/edge-2/loadbalancer/statistics"

# "# Get DHCP configuration"
# http-rest "GET" "/api/4.0/edge-2/dhcp/config"
# "# Get DHCP lease information"
# http-rest "GET" "/api/4.0/edge-2/dhcp/leaseInfo"


"# Query DHCP Relay" # 6.1 feature
http-rest "GET" "/api/4.0/edges/edge-2/dhcp/config/relay"

"# Get high availability configuration"
http-rest "GET" "/4.0/edges/edge-2/highavailability/config"

"# Query syslog servers"
http-rest "GET" "/api/4.0/edges/edge-1/syslog/config"
http-rest "GET" "/api/4.0/edges/edge-2/syslog/config"

#
# Edge Services VPN
#

"# Get SSL VPN details"
http-rest "GET" "/api/4.0/edges/edge-2/sslvpn/config/"

"# Query SSL VPN advanced configuration"
http-rest "GET" "/api/4.0/edges/<edgeId>/sslvpn/config/advancedconfig/"

"# Get SSL VPN portal web resource"
http-rest "GET" "/api/4.0/edges/edge-2/sslvpn/config/webresources/"

"# Query SSL VPN active clients"
http-rest "GET" "/api/4.0/edges/<edgeId>/sslvpn/activesessions/"

"# Get SSL VPN all script parameters"
http-rest "GET" "/api/4.0/edges/edge-2/sslvpn/config/script/"

# "# Get SSL VPN statistics"
# http-rest "GET" "/api/4.0/edges/<edgeId>/statistics/dashboard/sslvpn?interval=<range>"
# <!--range can be 1 - 60 minutes or oneDay|oneWeek|oneMonth|oneYear. Default is 60 minutes -->


"# Query L2VPN"
http-rest "GET" "/api/4.0/edges/edge-2/l2vpn/config/"


"# Query L2VPN statistics"
http-rest "GET" "/api/4.0/edges/edge-2/l2vpn/config/statistics"

"#  Get IPSEC statistics"
http-rest "GET" "/api/4.0/edges/edge-2/ipsec/statistics"
# "# Get tunnel traffic statistics"
# http-rest "GET" "/api/4.0/edges/edge-2/statistics/dashboard/ipsec?interval=<range>"


# "# Redeploy Edge"
# http-rest "POST" "https://<nsxmgr-ip>/api/4.0/edges/{edgeId}?action=redeploy" $null


"# Retrieve Edge details"
http-rest "GET" "/api/4.0/edges/edge-2/summary"

"# Query Edge status"
http-rest "GET" "/api/4.0/edges/edge-1/status"
http-rest "GET" "/api/4.0/edges/edge-2/status"


"# Get appliance configuration"
http-rest "GET" "/api/4.0/edges/edge-1/appliances"
http-rest "GET" "/api/4.0/edges/edge-2/appliances"

"# Retrieve all interfaces"
http-rest "GET" "/api/4.0/edges/edge-1/vnics" # Not ESG => LDR
http-rest "GET" "/api/4.0/edges/edge-2/vnics"

# Disabled => long output
# "# Get interface statistics"
# http-rest "GET" "/api/4.0/edges/edge-1/statistics/interfaces"
# http-rest "GET" "/api/4.0/edges/edge-2/statistics/interfaces"

# Disabled => long output
# "# Get uplink interface statistics"
# http-rest "GET" "/api/4.0/edges/edge-1/statistics/interfaces/uplink"
# http-rest "GET" "/api/4.0/edges/edge-2/statistics/interfaces/uplink"

# Disabled => long output
# "# Get internal interface statistics"
# http-rest "GET" "/api/4.0/edges/edge-1/statistics/interfaces/internal"
# http-rest "GET" "/api/4.0/edges/edge-2/statistics/interfaces/internal"

# "# Get interface statistics"
# http-rest "GET" "/api/4.0/edges/edge-1/statistics/dashboard/interface?interval=<range>"

#
# Firewall Management
#

"# Get firewall configuration for NSX Manager"
http-rest "GET" "/api/4.0/firewall/globalroot-0/config"


"# Get firewall configuration status"
http-rest "GET" "/api/4.0/firewall//globalroot-0/status"

# Example 9-5. Get section configuration
# Request:
# GET https://<nsxmgr-ip>/api/4.0/firewall/globalroot-0/config/layer3sections|layer2sections/<sectionId> |<sectionName>

# Example 9-9. Get firewall rule
# Request:
# GET https://<nsxmgr-ip>/api/4.0/firewall//globalroot-0/config/layer3sections|layer3sections/<sectionNumber>/rules/<ruleNumber>


# Example 9-23. Get layer2 status
# Request:
# GET https://<nsxmgr-ip>/api/4.0/firewall//globalroot-0/status/layer2sections/<sectionNumber>

# Example 9-22. Get Layer3 status
# Request:
# GET https://<nsxmgr-ip>/api/4.0/firewall//globalroot-0/status/layer3sections/<sectionNumber>

# Example 9-25. Query thresholds
# Request:
# GET https://<nsxmgr-ip>/api/4.0/firewall/stats/eventthresholds/

# Example 9-27. Query global configuration
# Request:
# GEThttps://<nsxmgr-ip>/api/4.0/firewall/config/globalconfiguration

# Example 9-28. Force sync host
# Request:
# POST https://<nsxmgr-ip>/api/4.0/firewall/forceSync/<hostID>

# Example 9-29. Force sync cluster
# Request:
# POST https://<nsxmgr-ip>/api/4.0/firewall/forceSync/<clusterID>

#
# Service Composer Management
#

"# Query security policies"
# GET https://<nsxmgr-ip>/api/2.0/services/policy/securitypolicy/securitypolicyID | all
http-rest "GET" "/api/2.0/services/policy/securitypolicy/all"

# Example 10-7. Query security actions for a security policy
# Request:
# GET https://<nsxmgr-ip>/api/2.0/services/policy/securitypolicy/securitypolicyId/securityactions

# Example 10-10. Query security actions on a virtual machine
# Request:
# GET https://<nsxmgr-ip>/api/2.0/services/policy/virtualmachine/VM_ID//securityactions

# Example 10-11. Query security policies mapped to a security group
# Request:
# GET https://<nsxmgr-ip>/api/2.0/services/policy/securitygroup/securitygroupID/securitypolicies

# Example 10-13. Query virtual machines in a security group
# Request:
# GET https://<nsxmgr-ip>/api/2.0/services/securitygroup/{securityGroupId}/translation/virtualmachines

# Example 10-14. Query security groups to which a virtual machine belongs
# Request:
# GET https://<nsxmgr-ip>/api/2.0/services/securitygroup/lookup/virtualmachine/<virtualMachineId>

# Example 11-1. Get all SDD policy regulations
# Request:
# GET https://<nsxmgr-ip>/api/2.0/dlp/regulation


# Example 11-3. Get all classification values associated with customizable classifications
# Request:
# GET https://<nsxmgr-ip>/api/2.0/dlp/classificationvalue

