$input_path = ‘https://support.content.office.net/en-us/static/O365IPAddresses.xml'
$output_file = ‘.\O365IPv4Addresses’
[xml]$XmlDocument = (New-Object System.Net.WebClient).DownloadString($input_path)
$IPv4regex = ‘\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b’
Write-Host "O365IPAddresses.xml"
Write-Host "Last Updated: " $XmlDocument.products.updated
$datestring = $XmlDocument.products.updated -replace '[/]',''
$output_file = $output_file + "-" + $datestring + ".txt"
(Select-Xml -Xml $XmlDocument -XPath "//address").Node.InnerText | ?{$_ -match $IPv4regex} | out-file $output_file
notepad $output_file
