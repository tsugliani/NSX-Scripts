#
# NSX-Deploy-Services
# Description: Deploy Guest Introspection & Data Security
# Author: Timo sugliani <tsugliani@vmware.com>
# Version: 1.0
# Date: 09/04/2014
#


# Global environment variables
$vcenter_hostname = "vc-cap-a.corp.local"
$vcenter_port     = 443
$vcenter_username = "corp\administrator"
$vcenter_password = "password1!"
$nsx_hostname     = "192.168.110.40:443"
$nsx_username     = "admin"
$nsx_password     = "password1!"

# Create authentication header with base64 encoding
$EncodedAuthorization = [System.Text.Encoding]::UTF8.GetBytes($nsx_username + ':' + $nsx_password)
$EncodedPassword = [System.Convert]::ToBase64String($EncodedAuthorization)

# Construct headers with authentication data + expected Accept header (xml / json)
$headers = @{"Authorization" = "Basic $EncodedPassword"}
$headers.Add("Accept", "application/json")


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
function http-rest-json
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
    $Url = "https://$nsx_hostname" + $uri
  }

  Process {
    # Construct headers with authentication data + expected Accept header (xml / json)
    $headers = @{"Authorization" = "Basic $EncodedPassword"}
    $headers.Add("Accept", "application/json")


    # Build Invoke-RestMethod request
    try
    {
      if (!$body) {
        $HttpRes = Invoke-RestMethod -Uri $Url -Method $method -Headers $headers
      }
      else {
        $HttpRes = Invoke-RestMethod -Uri $Url -Method $method -Headers $headers -Body $body -ContentType "application/json"
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
    else {
      Write-Host -ForegroundColor Red "Error retrieving response body for $Url"
    }
  }
  End {
      # What to do here ?
  }
}

# Small Function to execute a REST operations and return the JSON response
function http-rest-xml
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
    $Url = "https://$nsx_hostname" + $uri
  }

  Process {
    # Construct headers with authentication data + expected Accept header (xml / json)
    $headers = @{"Authorization" = "Basic $EncodedPassword"}
    $headers.Add("Accept", "application/xml")

    # Build Invoke-RestMethod request
    try
    {
      if (!$body) {
        $HttpRes = Invoke-RestMethod -Uri $Url -Method $method -Headers $headers
      }
      else {
        $HttpRes = Invoke-RestMethod -Uri $Url -Method $method -Headers $headers -Body $body -ContentType "application/xml"
      }
    }
    catch {
      Write-Host -ForegroundColor Red "Error connecting to $Url"
      Write-Host -ForegroundColor Red $_.Exception.Message
    }

    # If the response to the HTTP request is OK,
    if ($HttpRes) {
      return $HttpRes
    }
  }
  End {
      # What to do here ?
  }
}

if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)) {
    add-pssnapin VMware.VimAutomation.Core
}

"# Fetch NSX Available Services ..."
$nsx_guestintrospection_service = $null
$nsx_datasecurity_service = $null

$services = http-rest-json "GET" "/api/2.0/si/services"
$services_json = $services | ConvertFrom-Json

Foreach ($service in $services_json.services) {
  if ($service.name -eq "Guest Introspection") {
    $nsx_guestintrospection_service = $service.objectId
  }
  elseif ($service.name -eq "VMware Data Security"){
    $nsx_datasecurity_service = $service.objectId
  }
}

"-> NSX Guest Introspection Service  : $nsx_guestintrospection_service"
"-> NSX VMware Data Security Service : $nsx_datasecurity_service"

"# Fetching NSX IP Pools"
$nsx_guestintrospection_pool = $null
$nsx_datasecurity_pool = $null

$pools = http-rest-json "GET" "/api/2.0/services/ipam/pools/scope/globalroot-0"
$pools_json = $pools | ConvertFrom-Json

Foreach ($ippool in $pools_json.ipAddressPools) {
  if ($ippool.name -eq "NSX-GuestIntrospection-Pool") {
    $nsx_guestintrospection_pool = $ippool.objectId
  }
  elseif ($ippool.name -eq "NSX-DataSecurity-Pool") {
    $nsx_datasecurity_pool = $ippool.objectId
  }
}

"-> NSX-GuestIntrospection-Pool : $nsx_guestintrospection_pool"
"-> NSX-DataSecurity-Pool       : $nsx_datasecurity_pool"

"# Connecting to vc-cap-a.corp.local ..."
Connect-VIServer -Server $vcenter_hostname -Port $vcenter_port -User $vcenter_username -Password $vcenter_password

"## Fetching NSX Cluster 'Site A Capacity Cluster' MoRef ..."
$cluster = Get-Cluster "Site A Capacity Cluster"
$cluster_moref = $cluster.ExtensionData.MoRef.Value
"-> Cluster : $cluster_moref"


"## Fetching NSX Cluster Datastore 'cap-a-nfs-01' MoRef ..."
$datastore = $cluster | Get-Datastore 'cap-a-nfs-01'
$datastore_moref = $datastore.ExtensionData.MoRef.Value
"-> Datastore : $datastore_moref"

"## Fetching NSX Management dvPortgroup 'DPortgroup-Management' MoRef ..."
$portgroup = Get-VirtualSwitch -Name "DSwitch-NSX" | Get-VirtualPortGroup -Name "DPortgroup-Management"
$portgroup_moref = $portgroup.ExtensionData.MoRef.Value
"-> dvPortgroup : $portgroup_moref"

"# Deploying VMware Guest Introspection ..."
$xml = "
<clusterDeploymentConfigs>
  <clusterDeploymentConfig>
    <clusterId>$cluster_moref</clusterId>
    <datastore>$datastore_moref</datastore>
    <services>
      <serviceDeploymentConfig>
        <serviceId>$nsx_guestintrospection_service</serviceId>
        <dvPortGroup>$portgroup_moref</dvPortGroup>
        <ipPool>$nsx_guestintrospection_pool</ipPool>
      </serviceDeploymentConfig>
    </services>
  </clusterDeploymentConfig>
</clusterDeploymentConfigs>"

$job_id = http-rest-xml "POST" "/api/2.0/si/deploy" $xml

"# Checking deployment status ..."
$check_url = "/api/2.0/si/deploy/cluster/$cluster_moref/service/$nsx_guestintrospection_service"
$installed = "None"

$loops = 0 # Added this because of another bug ...

while ($installed -eq "None") {
  $test = http-rest-xml "GET" $check_url

  $progress_status = $test.deployedService.progressStatus
  #$service_status = $test.deployedService.serviceStatus

  "-> Progress Status: [$progress_status]"
  if ($progress_status -eq "SUCCEEDED") {
    "Loops: $loops"
    if ($loops -gt 2) {
      break
    }
    else {
      "# API Bug, showing 'SUCCEEDED' when it didn't even start..."
    }
  }
  "-- Sleeping 10s --"
  Start-Sleep -s 10
  $loops = $loops + 1
}

"# Deploying VMware Data Security ..."
$xml = "
<clusterDeploymentConfigs>
  <clusterDeploymentConfig>
    <clusterId>$cluster_moref</clusterId>
    <datastore>$datastore_moref</datastore>
    <services>
      <serviceDeploymentConfig>
        <serviceId>$nsx_datasecurity_service</serviceId>
        <dvPortGroup>$portgroup_moref</dvPortGroup>
        <ipPool>$nsx_datasecurity_pool</ipPool>
      </serviceDeploymentConfig>
    </services>
  </clusterDeploymentConfig>
</clusterDeploymentConfigs>"

$job_id = http-rest-xml "POST" "/api/2.0/si/deploy" $xml

"# Checking deployment status ..."
$check_url = "/api/2.0/si/deploy/cluster/$cluster_moref/service/$nsx_datasecurity_service"
$installed = "None"

$loops = 0 # Added this because of another bug ...

while ($installed -eq "None") {
  $test = http-rest-xml "GET" $check_url

  $progress_status = $test.deployedService.progressStatus
  #$service_status = $test.deployedService.serviceStatus

  "-> Progress Status: [$progress_status]"
  if ($progress_status -eq "SUCCEEDED") {
    "Loops: $loops"
    if ($loops -gt 2) {
      break
    }
    else {
      "# API Bug, showing 'SUCCEEDED' when it didn't even start..."
    }
  }
  "-- Sleeping 10s --"
  Start-Sleep -s 10
  $loops = $loops + 1
}

"# Changing VMware Data Security Policy to scan only .sec files and < 5KB ..."
$xml = "
<FileFilters>
  <scanAllFiles>false</scanAllFiles>
  <sizeLessThanBytes>5120</sizeLessThanBytes>
  <extensionsIncluded>true</extensionsIncluded>
  <extensions>sec</extensions>
</FileFilters>"

http-rest-xml "PUT" "/api/2.0/dlp/policy/filefilters" $xml

"# Applying updated VMware Data Security policy ..."
http-rest-xml "PUT" "/api/2.0/dlp/policy/publish"

"# Disconnecting from vc-cap-a.corp.local ..."
Disconnect-VIServer -Server $vcenter_hostname -Force -Confirm:$false
