#
# NSX-Resolve-Issues
# Description: FIX NSX Cluster Status seen as unresolved.
# Author: Timo sugliani <tsugliani@vmware.com>
# Version: 1.1
# Date: 09/10/2014
#

# Global environment variables
$vcenter_hostname = "vc-cap-a.corp.local"
$vcenter_port     = 443
$vcenter_username = "corp\administrator"
$vcenter_password = "password1!"
$nsx_hostname     = "192.168.110.40"
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

function nsx_resolve_issues
{
  "# Connecting to vc-cap-a.corp.local ..."
  Connect-VIServer -Server $vcenter_hostname -Port $vcenter_port -User $vcenter_username -Password $vcenter_password

  "## Fetching NSX Cluster 'Site A Capacity Cluster' MoRef ..."
  $cluster = Get-Cluster "Site A Capacity Cluster"
  $cluster_moref = $cluster.ExtensionData.MoRef.Value
  "-> Cluster : $cluster_moref"

  "## Resolving NSX Cluster Issue -> WARNING this will show FAILURE, but actually works !"
  http-rest-xml "POST" "/api/2.0/nwfabric/resolveIssues/$cluster_moref"
  "-> API Bug that returns 404 when it should return 200 or 204"

  "# Disconnecting from vc-cap-a.corp.local ..."
  Disconnect-VIServer -Server $vcenter_hostname -Force -Confirm:$false
}

