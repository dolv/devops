<################################
Global Variables Definition block
################################>

$doNotPerformChecks=0
$clusterName = "OpenCPU cluster"
$region = "East US 2"
$resourceGroupName = "dev-nethawk-opencpu"
$virtualNetworkName = "dev"
$virtualNetworkAddressPrefix = "10.201.96.0/19"
$virtualNetworkResourceGroupName = "dev"
$virtualNetworkSubnetName = "app"
$virtualNetworkSubnetAddressPrefix = "10.201.104.0/24"
$virtualNetworkSecurityGroupName = "app"
$virtualNetworkSecurityGroupResourceGroupName = $virtualNetworkResourceGroupName
$storageAccountName = "devnethawkopencpuosdisks"
$OS_Image = @{ PublisherName = "OpenLogic";
	Offer = "CentOS";
	Skus = "7.3";
	Version = "latest"
}

# Definer user name with blank password then define SSH key
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("ops", $securePassword)
$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\edd_ops_authorized_string"
$defaultSSHAuthorisedKeysFile = "/home/" + $cred.UserName + "/.ssh/authorized_keys"

#Define security rules list
$SecurityRuleConfigs = @(
	(New-AzureRmNetworkSecurityRuleConfig `
		-Name "allow-outbound-virtualnetwork" `
		-Protocol "*" `
		-SourcePortRange "*" `
		-DestinationPortRange "*" `
		-SourceAddressPrefix "10.201.104.0/24" `
		-DestinationAddressPrefix "VIRTUALNETWORK" `
		-Access "Allow" `
		-Priority 100 `
		-Direction "Outbound"
	), 
	(New-AzureRmNetworkSecurityRuleConfig `
		-Name "allow-inbound-xmoffice" `
		-Protocol "*" `
		-SourcePortRange "*" `
		-DestinationPortRange "*" `
		-SourceAddressPrefix "50.76.255.221" `
		-DestinationAddressPrefix "10.201.104.0/24" `
		-Access "Allow" `
		-Priority 100 `
		-Direction "Inbound"
	),
	(New-AzureRmNetworkSecurityRuleConfig `
		-Name "deny-inbound-internet" `
		-Protocol "*" `
		-SourcePortRange "*" `
		-DestinationPortRange "*" `
		-SourceAddressPrefix "INTERNET" `
		-DestinationAddressPrefix "10.201.104.0/24" `
		-Access "Deny" `
		-Priority 101 `
		-Direction "Inbound"
	),
	(New-AzureRmNetworkSecurityRuleConfig `
		-Name "allow-inbound-virtualnetwork" `
		-Protocol "*" `
		-SourcePortRange "*" `
		-DestinationPortRange "*" `
		-SourceAddressPrefix "VIRTUALNETWORK" `
		-DestinationAddressPrefix "10.201.104.0/24" `
		-Access "Allow" `
		-Priority 102 `
		-Direction "Inbound"
	)
)

# define cluster configuration
$clusterVMs = @(
	@{ Name = "opencpu-F4s";
		Size = "Standard_F4s";
		UserName = $cred.UserName;	
		SSHPubKey = $sshPublicKey;
		authorized_keys_Path = $defaultSSHAuthorisedKeysFile
	},
	@{ Name = "opencpu-F8s";
		Size = "Standard_F8s";
		UserName = $cred.UserName;
		SSHPubKey = $sshPublicKey;
		authorized_keys_Path = $defaultSSHAuthorisedKeysFile
	},
	@{ Name = "opencpu-F16s";
		Size = "Standard_F16s";
		UserName = $cred.UserName;
		SSHPubKey = $sshPublicKey;
		authorized_keys_Path = $defaultSSHAuthorisedKeysFile
	}
)

<###################################
 Helper functions definition block
###################################>
function securityRuleConfigsEqual {
 
    Param(
 
        [parameter(position=0, Mandatory=$true)]
		[Microsoft.Azure.Commands.Network.Models.PSSecurityRule]
        $rule1,
        [parameter(position=1, Mandatory=$true) ]
		[Microsoft.Azure.Commands.Network.Models.PSSecurityRule]
        $rule2
 
        )

	$comparingProperties = @(
		#"Description",
		"Protocol",
		"SourcePortRange"
		"DestinationPortRange",
		"SourceAddressPrefix",
		"DestinationAddressPrefix",
		"Access",
		"Priority",
		"Direction",
		#"ProvisioningState",
		"Name"
		#"Etag",
		#"Id"
	)

	$result = $true

	foreach ($property in $comparingProperties){
		if(-Not $rule1.$property -eq $rule2.$property){
			$result = $false
			break
		}
	}
    
	return $result
 
}
<###################################
    Main Script body goes here
###################################>

echo "==> Start Creating $clusterName with the following parameters:"
echo "    Location: $region"
echo "    Resource Group: $resourceGroupName"
echo "    Virtual Network: $virtualNetworkName"
echo "    Virtual Network Subnet: $virtualNetworkSubnetName [ $virtualNetworkSubnetAddressPrefix ]"
echo "    Virtual Network Security Group: $virtualNetworkSecurityGroupName"
echo "    Storage Account Name: $storageAccountName"
Write-Output "    OS: $($OS_Image.Offer) $($OS_Image.Skus) $($OS_Image.Version)"
echo "    Cluster size: $($clusterVMs.Length) VMs including:"

$totalVMnumber = $clusterVMs.Length
For ($i=0;$i -lt $totalVMnumber; $i++){
	Write-Output "            - $($clusterVMs[$i].Name)"
}
echo "<== Processing has began."

#check object type
#(New-AzureRmVMConfig -VMName opencpu-F4s -VMSize Standard_F4s).pstypenames[0]

# Check if the Resource group exists and create new one if not
$getResourceGroupResult = $null
$resourceGroupNotPresent = $null
$getResourceGroupResult = Get-AzureRmResourceGroup -Name $resourceGroupName -ev resourceGroupNotPresent -ea 0

If ($resourceGroupNotPresent -or $doNotPerformChecks) {
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $region
}

#Check if the Storage account exists and Create New one if not
$getStorageAccountResult = $null
$storageAccountNotPresent = $null

$getStorageAccountResult = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ev storageAccountNotPresent -ea 0
If ($storageAccountNotPresent -or $doNotPerformChecks) {
    New-AzureRmStorageAccount -ResourceGroupName "dev-nethawk-opencpu" -Name "devnethawkopencpuosdisks" -SkuName Premium_LRS -Location "East US 2" -Kind Storage -EnableHttpsTrafficOnly 1
}

#Check if the the Virtual Network exists and Create New one if not
$getVNetResult = $null
$virtualNetworkNotPresent = $null

$getVNetResult = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $virtualNetworkResourceGroupName -ev virtualNetworkNotPresent -ea 0
If ($virtualNetworkNotPresent) {
    New-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $virtualNetworkResourceGroupName 
    -Location $region -AddressPrefix $virtualNetworkAddressPrefix
}

$virtualNetwork = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $virtualNetworkResourceGroupName

#Check if the Virtual Network SecurityGroup exists and create new one if not
$getVNetSecurityGroupResult = $null
$virtualNetworkSecurityGroupNotPresent = $null

$getVNetSecurityGroupResult = Get-AzureRMNetworkSecurityGroup -Name $virtualNetworkSecurityGroupName -resourceGroupName $virtualNetworkSecurityGroupResourceGroupName -ev virtualNetworkSecurityGroupNotPresent -ea 0
if ($virtualNetworkSecurityGroupNotPresent){
	New-AzureRmNetworkSecurityGroup -Name $virtualNetworkSecurityGroupName -ResourceGroupName $virtualNetworkSecurityGroupResourceGroupName -Location $region
}
$virtualNetworkSecurityGroup = $getVNetSecurityGroupResult


#Check if the needed Security Rules have been defined in Networ Security Group and create new if not
foreach ($securityRuleConfig in $SecurityRuleConfigs){
	$getSecurityRuleConfigResult = $null
	$securityRuleConfigNotPresent = $true

	foreach($rule in $(Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $virtualNetworkSecurityGroup)){
		if ( securityRuleConfigsEqual $rule $securityRuleConfig ){
			$getSecurityRuleConfigResult = $rule
			$securityRuleConfigNotPresent = $false
			break
		}
	}

	if ($securityRuleConfigNotPresent){
		Add-AzureRmNetworkSecurityRuleConfig -Name $securityRuleConfig.Name -NetworkSecurityGroup $virtualNetworkSecurityGroup `
		-Access $securityRuleConfig.Access `
		-Protocol $securityRuleConfig.Protocol `
		-Direction $securityRuleConfig.Direction `
		-Priority $securityRuleConfig.Priority `
		-SourceAddressPrefix $securityRuleConfig.SourceAddressPrefix `
		-SourcePortRange $securityRuleConfig.SourcePortRange `
		-DestinationAddressPrefix $securityRuleConfig.DestinationAddressPrefix `
		-DestinationPortRange  $securityRuleConfig.DestinationPortRange `
		| Set-AzureRmNetworkSecurityGroup
	}

}

#Check if the the Virtual Network Subnet exists and Create New one if not and add it to Virtual Network object
$getVNetSubnetResult = $null
$virtualNetworkSubnetNotPresent = $null

$getVNetSubnetResult =  Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $virtualNetwork -Name $virtualNetworkSubnetName -ev virtualNetworkSubnetNotPresent -ea 0
If ($virtualNetworkSubnetNotPresent) {
	$virtualNetworkSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $virtualNetworkSubnetName -AddressPrefix $virtualNetworkSubnetAddressPrefix -NetworkSecurityGroup $virtualNetworkSecurityGroup
    
}

$virtualNetworkSubnet = $getVNetSubnetResult

For ($i=0;$i -lt $totalVMnumber; $i++){

	echo ("==========> Processing $i VM out of total $totalVMnumber <============")
	$vm = $clusterVMs[$i]
	
	#Check if the NICs exist and Create New if not
	$getNetworkInterfaceResults = $null
	$networkInterfaceNotPresent = $null
	
	$getNetworkInterfaceResults = Get-AzureRmNetworkInterface -Name ($vm.Name + '-NIC') -ResourceGroupName $resourceGroupName -ev networkInterfaceNotPresent -ea 0
	if ($networkInterfaceNotPresent -or $doNotPerformChecks) {
		$nic = New-AzureRmNetworkInterface -Name ($vm.Name + '-NIC') -ResourceGroupName $resourceGroupName -Location $region `
		-SubnetId  $virtualNetworkSubnet.Id -NetworkSecurityGroupId $virtualNetworkSecurityGroup.Id
		
	    $vm.NIC = $nic
	} 
	else {
	    $vm.NIC = $getNetworkInterfaceResults
	}
	
		
	# Create a virtual machine configuration
	$vmConfig = New-AzureRmVMConfig -VMName $vm.Name -VMSize $vm.Size | `
	  Set-AzureRmVMOperatingSystem -Linux -ComputerName $vm.Name -Credential $cred -DisablePasswordAuthentication | `
	  Set-AzureRmVMSourceImage -PublisherName $OS_Image.PublisherName -Offer $OS_Image.Offer -Skus $OS_Image.Skus -Version $OS_Image.Version | `
	  Add-AzureRmVMNetworkInterface -Id $vm.NIC.Id

	Add-AzureRmVMSshPublicKey -VM $vmConfig -KeyData $vm.SSHPubKey -Path $vm.authorized_keys_Path

	#Check VM with the defined above config exists and Create New if not
	$getVMResult = $null
	$vmNotPresent = $null

	$getVMResult = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vm.Name -ev vmNotPresent -ea 0
	if ($vmNotPresent -or $doNotPerformChecks){
		# Create a virtual machine
		New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $region -VM $vmConfig
	}

}

echo "==> Please consider adding the following lines to your hosts file:" ""

Foreach ($vm in $clusterVMs){
	echo "$((Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Name $($vm.NIC.Name)).IpConfigurations[0].PrivateIpAddress) $($vm.Name).$resourceGroupName"
}

echo "" "DONE"