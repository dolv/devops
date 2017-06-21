<################################
Global Variables Definition block
################################>

$doNotPerformChecks=0
$clusterName = "OpenCPU cluster"
$region = "East US 2"
$resourceGroupName = "dev-nethawk-opencpu"

$virtualNetworkName = "dev"
$virtualNetworkResourceGroupName = "dev"
$virtualNetwork = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $virtualNetworkResourceGroupName

$virtualNetworkSubnetName = "app"
$virtualNetworkSubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $virtualNetwork -Name $virtualNetworkSubnetName

$virtualNetworkSecurityGroupName = "app"
$virtualNetworkSecurityGroupResourceGroupName = $virtualNetworkResourceGroupName
$virtualNetworkSecurityGroup = Get-AzureRMNetworkSecurityGroup -Name $virtualNetworkSecurityGroupName -resourceGroupName $virtualNetworkSecurityGroupResourceGroupName

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


# define cluster configuration
$clusterVMs = @(
	@{ Name = "POC-opencpu-F4s";
		Size = "Standard_F4s";
		UserName = $cred.UserName;	
		SSHPubKey = $sshPublicKey;
		authorized_keys_Path = $defaultSSHAuthorisedKeysFile
	},
	@{ Name = "POC-opencpu-F8s";
		Size = "Standard_F8s";
		UserName = $cred.UserName;
		SSHPubKey = $sshPublicKey;
		authorized_keys_Path = $defaultSSHAuthorisedKeysFile
	},
	@{ Name = "POC-opencpu-F16s";
		Size = "Standard_F16s";
		UserName = $cred.UserName;
		SSHPubKey = $sshPublicKey;
		authorized_keys_Path = $defaultSSHAuthorisedKeysFile
	}
)

# $clusterVMs = @(
# 	@{ Name = "POC-opencpu-F4s";
# 		Size = "Standard_F4s";
# 		UserName = $cred.UserName;	
# 		SSHPubKey = $sshPublicKey;
# 		authorized_keys_Path = $defaultSSHAuthorisedKeysFile
# 	}
# )

<###################################
    Main Script body goes here
###################################>

echo "==> Start Creating $clusterName with the following parameters:"
echo "    Location: $region"
echo "    Resource Group: $resourceGroupName"
echo "    Virtual Network: $virtualNetworkName"
echo "    Virtual Network Subnet: $virtualNetworkSubnetName [ $($virtualNetworkSubnet.AddressPrefix) ]"
echo "    Virtual Network Security Group: $virtualNetworkSecurityGroupName"
echo "    Storage Account Name: $storageAccountName"
Write-Output "    OS: $($OS_Image.Offer) $($OS_Image.Skus) $($OS_Image.Version)"
echo "    Cluster size: $($clusterVMs.Length) VMs including:"

$totalVMnumber = $clusterVMs.Length
For ($i=0;$i -lt $totalVMnumber; $i++){
	Write-Output "            - $($clusterVMs[$i].Name)"
}
echo "<== Processing has began."

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
	  Set-AzureRmVMOperatingSystem -Linux -ComputerName $vm.Name -Credential $cred | `
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