#Set the template file and template parameter file paths and paste in to Az powershell. Enter the admin password of your choosing for the new VMs, and your domain-join-capable user account and password for automated domain join


#Provides Dialog Box to select a file with list of computers.  File must contain only 1 of each of the Computer name(s) per line
Function Get-OpenFile($initialDirectory)
{ 
   [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = $initialDirectory
$OpenFileDialog.filter = “All files (*.*)| *.*”
$OpenFileDialog.ShowDialog() | Out-Null
$OpenFileDialog.filename

}

Write-host "Select Azure Template File"

$templateFile = Get-OpenFile


Write-host "Select Azure Template Parameters File"

$templateParams = Get-OpenFile

#$credential = Get-Credential -Message "Enter Domain Join Username and Password"
#-domainUsername $credential.UserName  `
#-domainPassword $credential.Password `

New-AzDeployment `
-Name (Read-Host "Please enter deployment name") `
-TemplateFile $templateFile `
-TemplateParameterFile $templateParams `
-copyCount (Read-Host "How many VM would you like to create?") `
-copyIndexNumber (Read-Host "Enter the last 3 digits of the VM name, based on the team the VM(s) will be assigned to. Number will increment by 1 per each VM specified in the copyCount parameter.")`
-adminPassword (ConvertTo-SecureString (Read-Host "Enter Password for Azure VM") -asplaintext -force) `
-vmSize "Standard_B4ms" `
-Location usgovvirginia `
-DeploymentDebugLogLevel All `
-verbose 