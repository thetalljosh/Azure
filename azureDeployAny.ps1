#Log in to azure and set the subscription
$connected = $false
if (Get-AzAccessToken) { $connected = $true }

if (!($connected)) { connect-azaccount }
get-azsubscription | ft name, id
$sub = read-host "Enter the subscription ID from above"
set-azcontext -subscriptionid $sub
#Set the template file and template parameter file paths and paste in to Az powershell. Enter the admin password of your choosing for the new VMs, and your domain-join-capable user account and password for automated domain join

#Provides Dialog Box to select a file with list of computers.  File must contain only 1 of each of the Computer name(s) per line
Function Get-OpenFile($initialDirectory) { 
   [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

   $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
   $OpenFileDialog.initialDirectory = $initialDirectory
   $OpenFileDialog.filter = "All files (*.*)| *.*"
   $OpenFileDialog.ShowDialog() | Out-Null
   $OpenFileDialog.filename

}

$wif = read-host "is this is a what-if deployment? [y/n]"
while ($wif -ne "y" -and $wif -ne "n") {
   write-host "Please enter either y or n"
   $wif = read-host "is this is a what-if deployment? [y/n]"
}

Write-host "##########################"
Write-host "Select Azure Template File" -ForegroundColor Green -BackgroundColor white
Write-host "##########################"

$templateFile = Get-OpenFile

Write-host "##########################"
Write-host "Select Template Parameters File" -ForegroundColor Green -BackgroundColor white
Write-host "##########################"

$templateparameterfile = Get-OpenFile

#$credential = Get-Credential -Message "Enter Domain Join Username and Password"

$newRG = Read-host "Has resource group already been created? [y] yes or [n] no"
if ($newrg -eq 'y' -or $newRG -eq 'yes') {
   $rgName = read-host "Enter existing resource group name"
   if (!(Get-AzResourceGroup -Name $rgName)) {
      write-host "No resource group with that name found - creating resource group in eastus2"
      New-AzResourceGroup -Name $newrgname -Location 'eastus2'

   }
}
if ($newrg -eq 'n' -or $newRG -eq 'no') {
   $newrgName = read-host "Enter new resource group name"
   $loc = Read-Host "Enter azure region for new resource group [eastus2/centralus]"
   #create the resource group
   New-AzResourceGroup -Name $newrgname -Location $loc
}

if ($newrgName) { $rgName = $newrgName }

#$datadiskSize = read-host "Do you want to create a data disk? If not, enter 0, else enter Data disk size in gb"

#set variables for each template parameter
$temp = get-content $templateparameterfile -raw    
$jsonObject = $temp | ConvertFrom-Json
$parsedParams = $jsonObject.parameters.PSObject.Properties.Name

foreach ($param in $parsedParams) {
   if ($param -notlike "*password*") {
      $defaultValue = $jsonobject.parameters.$param.value
      $parVar = read-host "Specify value: $param [default value: $defaultValue]"
      if (!([string]::IsNullOrWhiteSpace($parVar))) {
         new-variable -name $param -ErrorAction silent
         set-variable -name $param -value $parVar
      }
      else {
         set-variable -name $param -value $defaultValue
      }
   }
}

foreach ($param in $parsedParams) {
   if ($param -notlike "*password*") {

      if ($null -eq (get-variable -name $param -erroraction silent)) {
         $defaultValue = $jsonobject.parameters.$param.value
         write-host "Using default value for $param : $defaultValue"
         set-variable -name $param -value $defaultValue
      }
   }
}

$deploymentName = "TemplateDeployment"
$commandArgs = ""

foreach ($param in $parsedParams) {
   if ($param -notlike "*password*") {

      $var = (get-variable -name $param).value
      if ($var.ToString().ToLower() -eq "true" -or $var.ToString().ToLower() -eq "false") {
         $string = "-$param  ([System.Convert]::ToBoolean(`$$param)) "
      }
      else {
         $string = "-$param `"$var`" "
      }
      $commandArgs += $string
   }
   
}

$commandArgs += " -ResourceGroupName $rgName -Name $deploymentName -verbose -templatefile `"$templatefile`" -TemplateParameterFile `"$templateparameterfile`" "

if ($wif -eq "y") {
   $commandArgs += "-whatif"
}

$command = "new-azresourcegroupdeployment " + $commandargs  

$quit = ""
$quit = read-host "`n`nThe following command will be executed:`n`n $command `n`nto cancel, enter q or press ctrl+c" 

if ($quit -eq 'q') { exit }

#execute the command
iex $command

<#
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
-Name $deploymentName.replace(" ","-") `
-vmName $vmName
-TemplateFile $templateFile `
-TemplateParameterFile $templateparameterfile `
-existingVirtualNetworkName $existingVirtualNetworkName `
-existingVirtualNetworkResourceGroup $existingVirtualNetworkResourceGroup`
-vmName $vmName `
-windowsOSVersion $windowsOSVersion `
-vmSize $vmSize`
-location $loc`
-domainToJoin $domainToJoin`
-vmSize "Standard_B2s" `

# -whatif
#>

if ($wif -eq 'y' -and $newrgname) {
   write-host "What-if deployment - removing resource group"
   remove-azresourcegroup -name $newrgname -Force
}
foreach ($param in $parsedParams) {
   if (get-variable -name $param -erroraction silent) {
      remove-variable -name $param
   }
}
