#TASK 1

TENANT_DOMAIN=$(az ad signed-in-user show --query "userPrincipalName" -o tsv | cut -d'@' -f2)

az ad user create \
  --display-name "az104-user1" \
  --user-principal-name "az104-user1@${TENANT_DOMAIN}" \
  --password "TempPassword123!" \


az rest --method PATCH \
  --url "https://graph.microsoft.com/v1.0/users/az104-user1@${TENANT_DOMAIN}" \
  --headers "Content-Type=application/json" \
  --body '{
    "accountEnabled": true,
    "jobTitle": "IT Lab Administrator",
    "department": "IT",
    "usageLocation": "US",
    "passwordProfile": {
      "forceChangePasswordNextSignIn": true,
    }
  }'



JSON_RESPONSE=$(az rest --method POST \
  --url "https://graph.microsoft.com/v1.0/invitations" \
  --headers "Content-Type=application/json" \
  --body "{
    \"invitedUserEmailAddress\": \"taras.ivankiv.22@pnu.edu.ua\",
    \"inviteRedirectUrl\": \"https://portal.azure.com\",
    \"sendInvitationMessage\": true,
    \"invitedUserDisplayName\": \"External User\",
    \"invitedUserMessageInfo\": {
        \"customizedMessageBody\": \"Welcome to Azure and our group project\"
    }
  }" \
)
    
USER_ID=$(echo $JSON_RESPONSE | jq -r '.invitedUser.id')

az rest --method PATCH \
  --url "https://graph.microsoft.com/beta/users/$USER_ID" \
  --headers "Content-Type=application/json" \
  --body '{
    "jobTitle": "IT Lab Administrator",
    "department": "IT",
    "usageLocation": "US"
  }'    



# TASK 2

az ad group create \
  --display-name "IT Lab Administrators" \
  --description "Administrators that manage the IT lab" \
  --mail-nickname "itlabadmins"

USER_ID=$(az ad user show --id "ivankiv@manowe9460erynka.onmicrosoft.com" --query id -o tsv)

az ad group owner add \
  --group "IT Lab Administrators" \
  --owner-object-id "$USER_ID"


az ad group member add --group "IT Lab Administrator" --member-id "$(az ad user show --id "az104-user1@manowe9460erynka.onmicrosoft.com" --query id -o tsv)"
az ad group member add --group "IT Lab Administrator" --member-id "$(az ad user show --id "taras.ivankiv.22_pnu.edu.ua#EXT#@manowe9460erynka.onmicrosoft.com" --query id -o tsv)"


az ad group member list --group "IT Lab Administrators"
az ad group owner list --group "IT Lab Administrators"



az rest --method GET --url "https://graph.microsoft.com/v1.0/users/3c38c939-78e2-4507-a8b3-f207ce8642d4" --headers "Content-Type=application/json" --output json
