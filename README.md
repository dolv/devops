# devops

In order to be able to run playbooks from ansible/azure-stack you need to get the master host (the host where you run the playboook from) to be p
roperly configured for it.

Further I'll walk you through the configuration steps.
Please note that these steps will be performed on the CentOS Linux based distributive in particular CentOS-based 7.3 published by OpenLogic

## Creating VM in on Azure Portal.

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

 `sudo yum install -y git epel-release python-pip python-wheel gcc libffi-devel python-devel openssl-devel`

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

   `pip install "azure==2.0.0rc6"`

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

 `az ad sp create-for-rbac --name ansible --password SomeAppPasswordString
`

 Your results should look similar to this output (but with values you supplied):
 ```
 {
   "appId": "59db508a-3429-4094-a828-e8b4680fc790",
   "displayName": "WebApplication17089",
   "name": "https://webapplication17089.azurewebsites.net",
   "password": {the password you supplied displayed here},
   "tenant": "72f988bf-86f1-41af-91ab-2d7cd011db47"
 }
 ```





Go inside the devops/env/ansible/stacks/azure-stack

 ` cd devops/env/ansible/stacks/azure-stack`
