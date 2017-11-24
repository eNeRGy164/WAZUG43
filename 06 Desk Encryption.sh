az login

az account set -s YOUR-SUBSCRIPTION-ID

keyvault_name=wazug43
resourcegroup_name=wazug43
encryptionkey_name=encryptionkey
vm_name=wazug43encryptedvm

# Create encyption key
az keyvault key create \
    --vault-name $keyvault_name \
    --name $encryptionkey_name \
    --protection software

# Create Service Principal in Azure AD
read sp_id sp_password <<< $(az ad sp create-for-rbac --query [appId,password] -o tsv)

# Allow the Service Principal to work with the Key Vault
az keyvault set-policy \
    --name $keyvault_name \
    --spn $sp_id \
    --key-permissions wrapKey \
    --secret-permissions set

# Create VM with Encryption supported image
az vm create \
    --resource-group $resourcegroup_name \
    --name $vm_name \
    --image Canonical:UbuntuServer:16.04-DAILY-LTS:16.04.201711211 \
    --admin-username azureuser \
    --generate-ssh-keys \
    --data-disk-sizes-gb 5

# Enable encryption for all volumes
az vm encryption enable \
    --resource-group $resourcegroup_name \
    --name $vm_name \
    --aad-client-id $sp_id \
    --aad-client-secret $sp_password \
    --disk-encryption-keyvault $keyvault_name \
    --key-encryption-key $encryptionkey_name \
    --volume-type all

# Get status information of encryption process
az vm encryption show \
    --resource-group $resourcegroup_name \
    --name $vm_name 

# Restart VM after encryption is finished
az vm restart \
    --resource-group $resourcegroup_name \
    --name $vm_name 