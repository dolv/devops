# devops

Here you see folder named env. It means environment provisioning. Under the env you will see split by provisioning tools: Ansible, Chef, Terraform maybe something else will be added.


## Notes About ansible & AZURE Cloud

In order to be able to run playbooks related to AZURE you need to get the master host (the host where you run the playboook from) to be properly configured for it.

Further I'll walk you through the configuration steps.
Please note that these steps will be performed on the CentOS Linux based distributive in particular CentOS-based 7.3 published by OpenLogic

## Creating VM via Azure Portal.

1. Log in to [https://portal.azure.com](https://portal.azure.com)
2. Click big plus in the upper-left corner. You will see submenu called **Marketplace**
3. Select Compute from the menu as VMs are found in this service.
4. In the filter search field type 'OpenLogic' and hit enter.
5. From the provided search results select CentOS-based 7.3
6. And click 'Create' on the newly appeared window to the right from the search results.
7. Now you are in the 'Create virtual machine interface'. Enter VM name, User name
8. Choose whatever Authentication type you'd like use for connection. For instance Password.
9. Fill-in Password field and Confirm password fields which should coincide.
10. Select Subscription type from the drop-down list box.
11. In the Resource group click redio-button 'Create' and provide Resource group name or click 'Use existing' and select one from the drop-down menu.
12. Select geographical location from the drop-down list box something near to you or you.
13. Than when you click OK you will finish with the Basic Step 1 and move to the VM size step.
14. For our purposes the Standard DS1 size is well enough. Select it and Click select.
15. Now the second step is over and we are on the third step which is about optional features.
16. In the Network section click at the > signs if you need something to tweak. For example if you need static IP click IP address and Change Assignment from Dynamic which is default to Static.
17. Click OK. Verify Summary. Go back if something is wrong if everything looks good click OK.

In a few minutes new VM will be created. The details about it can be found in the lefthand portal menu called Virtual machines. Click it
While the VM is being created the status will be 'Creating' that it will change for 'Running'

Once deployment has been finished the notification will appear with words 'Deployment succeeded'.

Click on VM and in the Essentials section you will find Public IP address. Copy it.

## Preparing master host
1. Connect to the VM via SSH with the following command.

    `ssh yourusername@12.123.23.456` replace with correct username and IP respectively.

2. Once you are in the system console you now have to install packages needed for our solution to run.

    `sudo yum install -y git epel-release python2-pip python-wheel gcc libffi-devel python-devel openssl-devel python2-jmespath`

3. Ensure you have latest pip version with

    `sudo pip install --upgrade pip`

4. Ansible is in EPEL repositosy.
Thus, once it is enebled in the system you are able to install it with the following command:

    `sudo yum install -y ansible`

5. Create dir for the repositiories. E.g

    `mkdir -p ~/repos && cd ~/repos`

6. Clone this repo with the command

    `git clone https://github.com/dolv/devops.git`

7. Using the Azure Resource Manager modules requires having Azure Python SDK installed on the host running Ansible. You will need to have == v2.0.0RC5 installed. The simplest way to install the SDK is via pip:

    `sudo pip install "azure==2.0.0rc6"`

8. Install the new version of the Azure CLI

     `curl -L https://aka.ms/InstallAzureCli | bash`
     hit enter to all questions to go with the default options or provide answers to the script questions.
    
     ** Run `exec -l $SHELL` to restart your shell. **

9. Check if everything works so far with the command
    
     `az --version`
    
     You should see the output similar to the following one:
     ```
     azure-cli (2.0.1)
    
     acs (2.0.1)
     appservice (0.1.1b6)
     batch (0.1.1b5)
     cloud (2.0.0)
     component (2.0.0)
     configure (2.0.1)
     container (0.1.1b4)
     core (2.0.1)
     documentdb (0.1.1b2)
     feedback (2.0.0)
     find (0.0.1b1)
     iot (0.1.1b3)
     keyvault (0.1.1b6)
     network (2.0.1)
     nspkg (2.0.0)
     profile (2.0.1)
     redis (0.1.1b3)
     resource (2.0.1)
     role (2.0.0)
     sql (0.1.1b6)
     storage (2.0.1)
     vm (2.0.1)
    
     Python (Linux) 2.7.5 (default, Nov  6 2016, 00:28:07)
     [GCC 4.8.5 20150623 (Red Hat 4.8.5-11)]
     ```


10. login to the Azure from console

     `az login`

     It will as you to use browser with the notification like this:
     ```
    To sign in, use a web browser to open the page https://aka.ms/devicelogin and enter the code C4JHQR92K to authenticate.
     ```

11. Create a service principal for your app

    `az ad sp create-for-rbac --name ansible --password {strong password}
`

    Your results should look similar to this output (but with values you supplied):
     ```
     {
       "appId": "a487e0c1-82af-47d9-9a0b-af184eb87646d",
       "displayName": "ansible",
       "name": "http://ansible",
       "password": {strong password},
       "tenant": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
     }
     ```
    
     You can verify a list of your registered applications with command `az ad app list`
     
     And you can if needed get information about the service principal.
     
     `az ad sp show --id a487e0c1-82af-47d9-9a0b-af184eb87646d`
     
     ```aidl
     {
       "appId": "a487e0c1-82af-47d9-9a0b-af184eb87646d",
       "displayName": "ansible",
       "objectId": "0ceae62e-1a1a-446f-aa56-2300d176659bde",
       "objectType": "ServicePrincipal",
       "servicePrincipalNames": [
         "http://ansible",
         "a487e0c1-82af-47d9-9a0b-af184eb87646d"
       ]
     }
    ```
 
12. Sign in using the service principal
 
      `az login --service-principal -u a487e0c1-82af-47d9-9a0b-af184eb87646d --password {strong password} --tenant XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`

     You will see this output after a successful sign-on:
     ```
        [
           {
             "cloudName": "AzureCloud",
             "id": "YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYYY",
             "isDefault": true,
             "state": "Enabled",
             "tenantId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
             "user": {
               "name": "a487e0c1-82af-47d9-9a0b-af184eb87646d",
               "type": "servicePrincipal"
             }
           }
        ]
     ```

13. Create ~/.azure/credentials file with the contents similar to the shown below:
    ```
    [newgistics]
    subscription_id=YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYYY
    client_id=a487e0c1-82af-47d9-9a0b-af184eb87646d
    secret={strong password}
    tenant=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    ```
   
14. Change permissions for the sake of securiry
    `chmod 600 ~/.azure/credentials`
  
15. Go inside the devops/env/ansible/stacks/azure-stack and list folder contents
    
    `cd devops/env/ansible/stacks/azure-stack && ls`
         
16. Edit bootstrap.sh script, place correct credential there and save
17. Generate SSH key for accessing provisioned VM

    `ssh-keygen`
    
    Hit enter to all questions.
    
18. Get the key string from the public key file you've just created
    
    `cat ~/.ssh/id_rsa.pub | cut -d ' ' -f 2`
    
    The outpuut should be similar to this one:
    
    ```
    AAAAB3NzaC1yc2EAAAADAQABAAABAQDFQZJpqohHPijvxKUovXE0u0gSiKwz4cB5hBduOiyptRbmWnmX0TbgKGRcZYGV3S/WPrrOqZhMfXJjv+9LrUdz7EvF2ixGXJPkUtGKWA1y8Vq33eX6zgYKPOvQTyqxskfRcGzcu5iPfdssrWE43+kMqrMDjEyyfEelCdJivuSlKOvdiVE3cx/xmR/kgzqdSNFSWO+hGe9g1wLVPpcEAwLLOLE7w/VlZEec+1DG9AZFXQM4cZyXrpMqrKozZXS9iKbJ7PVS1uhE5UPMQv3VYOjgBy8ufVwcOoamULK6SkIhnY1nJflO93OWKHSRBQSNcC+giOMnNMkZifK8DcrKJTgD
    ```
19. Put this as a value of the azure_ssh_public_key_string variable in the roles/create_vm/defaults/main.yml file. Or use extravars with this vallue in the bootstrap.sh Or any other way you like better.   
    the main.yml extract will look like this:
    
    ```
    azure_ssh_public_key_string: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFQZJpqohHPijvxKUovXE0u0gSiKwz4cB5hBduOiyptRbmWnmX0TbgKGRcZYGV3S/WPrrOqZhMfXJjv+9LrUdz7EvF2ixGXJPkUtGKWA1y8Vq33eX6zgYKPOvQTyqxskfRcGzcu5iPfdssrWE43+kMqrMDjEyyfEelCdJivuSlKOvdiVE3cx/xmR/kgzqdSNFSWO+hGe9g1wLVPpcEAwLLOLE7w/VlZEec+1DG9AZFXQM4cZyXrpMqrKozZXS9iKbJ7PVS1uhE5UPMQv3VYOjgBy8ufVwcOoamULK6SkIhnY1nJflO93OWKHSRBQSNcC+giOMnNMkZifK8DcrKJTgD'
    ```

20. Execute bootstrap script `./bootstrap.sh`
