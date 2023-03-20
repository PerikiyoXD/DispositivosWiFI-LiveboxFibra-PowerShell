# Function to get authentication data
function Get-AuthenticationData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$username,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$password
    )

    $url = "https://192.168.1.1/authenticate?username=$username&password=$password"

    $response = Invoke-WebRequest -SkipCertificateCheck -Uri $url -Method POST -UseBasicParsing -SessionVariable session

    # get the sessid from the Set-Cookie header
    $sessid = $response.Headers["Set-Cookie"].Split("=")[1].Split(";")[0]

    # print to console the sessid
    Write-Host "Session ID:" $sessid

    # get the contextid from the response content
    $content = $response.Content | ConvertFrom-Json
    $contextid = $content.data.contextID

    # print to console the contextid
    Write-Host "Context ID:" $contextid

    # return the sessid and contextid
    return $sessid, $contextid
}


# Function to get the list of all the devices
function Get-DeviceData
{
    # parameters: sessid, contextid

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$sessid,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$contextid
    )

    #Create a request object
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.Cookies.Add((New-Object System.Net.Cookie("17922a3f/zoom-accessibility", "small", "/", "192.168.1.1")))
    $session.Cookies.Add((New-Object System.Net.Cookie("17922a3f/contrast-accessibility", "contrast2", "/", "192.168.1.1")))
    $session.Cookies.Add((New-Object System.Net.Cookie("17922a3f/context", $contextid, "/", "192.168.1.1")))
    $session.Cookies.Add((New-Object System.Net.Cookie("17922a3f/login", "admin", "/", "192.168.1.1")))
    $session.Cookies.Add((New-Object System.Net.Cookie("17922a3f/expirydate", "Any", "/", "192.168.1.1")))
    $session.Cookies.Add((New-Object System.Net.Cookie("17922a3f/sessid", $sessid, "/", "192.168.1.1")))

    $response = Invoke-WebRequest -SkipCertificateCheck -UseBasicParsing -Uri "https://192.168.1.1/sysbus/Devices:get" `
    -Method POST `
    -WebSession $session `
    -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/111.0" `
    -Headers @{
    "Accept" = "text/javascript"
    "Accept-Language" = "es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3"
    "Accept-Encoding" = "gzip, deflate"
    "X-Requested-With" = "XMLHttpRequest"
    "X-Prototype-Version" = "1.7"
    "X-Context" = $contextid
    "Origin" = "http://192.168.1.1"
    "DNT" = "1"
    "Referer" = "http://192.168.1.1/myNetwork.html"
    "Pragma" = "no-cache"
    "Cache-Control" = "no-cache"
    } `
    -ContentType "application/x-sah-ws-1-call+json; charset=UTF-8" `
    -Body "{`"parameters`":{`"expression`":{`"usbM2M`":`"usb && wmbus and .Active==true`",`"usb`":`"printer && physical and .Active==true`",`"usblogical`":`"volume && logical and .Active==true`",`"eth`":`"eth and edev and not owl and not owl6 and .Active==true`",`"wifi`":`"wifi and edev and not owl and not owl6 and .Active==true`",`"dect`":`"voice && dect && handset && physical`",`"airbox`":`"storage airbox and .Active==true`",`"repeater`":`"(owl or owl6) and .Active==true`"}}}"

    # pretty print the response content which is a JSON string
    Write-Host "-----------------------------------------------------------------"
    Write-Host $response.Content | ConvertFrom-Json | Format-List -Property *
    Write-Host "-----------------------------------------------------------------"

    # return the response content parsed as JSON and filtered to get the wifi devices
    return $response.Content | ConvertFrom-Json | Select-Object -ExpandProperty result | Select-Object -ExpandProperty status | Select-Object -ExpandProperty wifi
}

function Get-WifiDeviceDetails {
    $sessid, $contextid = Get-AuthenticationData -username "admin" -password "MyAwesomeRouterPasswordThatYouMightThinkI'dBeDumbEnoughToUseThisOne"
    $wifiDevices = Get-DeviceData -sessid $sessid -contextid $contextid
    # Print the count of wifi devices
    Write-Host "Number of wifi devices:" $wifiDevices.Count

    # Create an array of PSCustomObjects with the wifi devices
    # Ensure it's an array
    $wifiDeviceTable = [System.Collections.ArrayList]@()
    
    foreach ($wifiDevice in $wifiDevices) {
        # New code:
        $wifiDeviceDetails = [PSCustomObject]@{
            "Name" = $wifiDevice.Name
            "DeviceType" = $wifiDevice.DeviceType
            "Active" = $wifiDevice.Active
            "MACAddress" = $wifiDevice.PhysAddress
            "SignalStrength" = $wifiDevice.SignalStrength
            "IPAddress" = $wifiDevice.IPv4Address[0].Address
            "LastSeen" = [DateTime]::ParseExact($wifiDevice.LastConnection, "MM/dd/yyyy HH:mm:ss", $null).ToLocalTime()
        }
        $wifiDeviceTable += $wifiDeviceDetails
    }

    # Print the type of $wifiDeviceTable
    Write-Host "Type of wifiDeviceTable:" $wifiDeviceTable.GetType()

    # Print the wifi devices, needs a foreach and writes it in a line
    Write-Host "Wifi devices:"
    foreach ($wifiDevice in $wifiDeviceTable) {
        Write-Host "----------------"
        Write-Host $wifiDevice
    }
    Write-Host "----------------"
    
    return ,$wifiDeviceTable # Stupid workaround to return an array, blame PowerShell
}

# Create a window with a table to show the wifi devices, return the window
function Create-WifiDeviceDetailsWindow
{
    # Create a window
    $window = New-Object System.Windows.Window
    $window.Title = "Wifi Devices"
    $window.Width = 700
    $window.Height = 500
    $window.WindowStartupLocation = "CenterScreen"

    # Create a table
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = New-Object System.Windows.Thickness(10, 10, 10, 10)

    # Create a data grid
    $dataGrid = New-Object System.Windows.Controls.DataGrid

    return $window, $grid, $dataGrid
}


# Create a window with a table to show the wifi devices
function Show-WifiDevicesWindowStatic
{
    # Pass the wifi devices table as parameter
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object[]]
        $WifiDevices
    )

    # Print the type of $WifiDevices
    Write-Host "Type of WifiDevices:" $WifiDevices.GetType()

    $window, $grid, $dataGrid = Create-WifiDeviceDetailsWindow

    # Create a data grid
    $dataGrid = New-Object System.Windows.Controls.DataGrid

    # Convert WifiDevices to a list of PSCustomObject and set it as the data grid source
    $WifiDevicesData = $WifiDevices | ForEach-Object { [PSCustomObject]@{
        "Name" = $_.Name
        "DeviceType" = $_.DeviceType
        "Active" = $_.Active
        "MACAddress" = $_.MACAddress
        "SignalStrength" = $_.SignalStrength
        # IPAddresses must be converted to it's raw string address
        "IPAddress" = $_.IPAddress
        # Format LastSeen to a dd/MM/yyyy HH:mm:ss string
        "LastSeen" = $_.LastSeen.ToString("dd/MM/yyyy HH:mm:ss")
    }}

    # Set the data grid source, we might need to convert the wifi devices to a list of PSCustomObject
    $dataGrid.ItemsSource = $WifiDevicesData

    # Add the data grid to the grid
    $grid.Children.Add($dataGrid)

    # Add a refresh button Under the data grid
    $refreshButton = New-Object System.Windows.Controls.Button
    $refreshButton.Content = "Refresh"
    $refreshButton.Margin = New-Object System.Windows.Thickness(0, 10, 0, 0)
    $refreshButton.HorizontalAlignment = "Right"
    $refreshButton.VerticalAlignment = "Bottom"
    $refreshButton.Width = 100
    $refreshButton.Height = 30

    # Add a click event to the refresh button
    $refreshButton.Add_Click({
        # Get the wifi devices
        $wifiDeviceTable = Get-WifiDeviceDetails

        # Set the data grid source
        $dataGrid.ItemsSource = $wifiDeviceTable

        # Refresh the view
        $dataGrid.Items.Refresh()
    })

    # Add the refresh button to the grid
    $grid.Children.Add($refreshButton)

    # Add the grid to the window
    $window.Content = $grid

    $null = $window.ShowDialog()
}


function Main
{
    # Import the PresentationFramework assembly
    Add-Type -AssemblyName PresentationFramework

    # Set up the STAThread
    $null = [System.Threading.Thread]::CurrentThread.SetApartmentState('STA')

    $wifiDeviceTable = Get-WifiDeviceDetails

    # Show the wifi devices window
    Show-WifiDevicesWindowStatic -WifiDevices $wifiDeviceTable
}

Main
