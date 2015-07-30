# 1. Fetch token for admin
# 2. Create user
# 3. Create namespace
# 4. Create collection
# 5. Fetch Certificate
# 6. Fetch token for user created in #2
# 7. Write configuration files
# 8. Run tests

([ -z $UAA_ADMIN_IDENTITY ] || [ -z $UAA_ADMIN_PASSWORD ] || [ -z $UAA_URL ] || [ -z $SYSTEM_DOMAIN ]) && echo "Missing environment variables" && exit 1

username=$(uuidgen)
password=$(uuidgen)
namespace=$(uuidgen)
collection=$(uuidgen)

auth_url=https:\/\/datasync-authentication.$SYSTEM_DOMAIN
data_url=https:\/\/datasync-datastore.$SYSTEM_DOMAIN

echo ""
echo "======================================================"
echo "1. Fetch token for admin"
echo "======================================================"
echo ""

authorization_header_uaa="Authorization: Basic $(printf "cf:" | base64)"
payload_uaa="username=$UAA_ADMIN_IDENTITY&password=$UAA_ADMIN_PASSWORD&scope=openid&grant_type=password"

admin_token=$(curl -sk $UAA_URL/oauth/token -X POST -H "$authorization_header_uaa" -d "$payload_uaa" | jq '.access_token' | awk -F '"' '{print $2}')

echo ""
echo "======================================================"
echo "2. Create user"
echo "======================================================"
echo ""

(
content_type_header="Content-Type: application/json"
authorization_header="Authorization: Bearer $admin_token"
payload="{\"username\" : \"$username\", \"password\" : \"$password\"}"

curl -sk $auth_url/api/users -X POST -H "$authorization_header" -H "$content_type_header" -d "$payload"
)

echo ""
echo "======================================================"
echo "3. Create namespace"
echo "======================================================"
echo ""

(
authorization_header="Authorization: Bearer $admin_token"
payload="{\"name\" : \"$namespace\"}"

curl -sk $data_url/admin/namespaces -X POST -H "$authorization_header" -d "$payload"
)

echo ""
echo "======================================================"
echo "4. Create collection"
echo "======================================================"
echo ""

(
authorization_header="Authorization: Bearer $admin_token"
payload="{\"name\" : \"$collection\"}"

curl -sk $data_url/admin/namespaces/$namespace/collections -X POST -H "$authorization_header" -d "$payload"
)

echo ""
echo "======================================================"
echo "5. Fetch certificate"
echo "======================================================"
echo ""

cert_path=$(dirname $0)/../PCFDataAcceptance/cert.der

$(dirname $0)/../../scripts/get-certificates *.$SYSTEM_DOMAIN:443 $cert_path

echo ""
echo "======================================================"
echo "6. Fetch token for user"
echo "======================================================"
echo ""

client_id=ios-client
client_secret=006d0cea91f01a82cdc57afafbbc0d26c8328964029d5b5eae920e2fdc703169
payload_auth="username=$username&password=$password&scope=openid&grant_type=password&client_id=$client_id&client_secret=$client_secret"

access_token=$(curl -sk $auth_url/token -X POST -d "$payload_auth" | jq '.access_token' | awk -F '"' '{print $2}')

echo $access_token

echo ""
echo "======================================================"
echo "7. Write configuration files"
echo "======================================================"
echo ""

cat > $(dirname $0)/../PCFDataAcceptanceTests/Pivotal.plist << EOM
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>pivotal.auth.scopes</key>
  <string>openid offline_access</string>
  <key>pivotal.auth.tokenUrl</key>
  <string>$auth_url/token</string>
  <key>pivotal.auth.authorizeUrl</key>
  <string>$auth_url/authorize</string>
  <key>pivotal.auth.redirectUrl</key>
  <string>io.pivotal.ios.PCFDataSample://oauth2callback</string>
  <key>pivotal.auth.clientId</key>
  <string>$client_id</string>
  <key>pivotal.auth.clientSecret</key>
  <string>$client_secret</string>
  <key>pivotal.data.serviceUrl</key>
  <string>$data_url/data/$namespace</string>
  <key>pivotal.data.collisionStrategy</key>
  <string>OptimisticLocking</string>
  <key>pivotal.data.trustAllSslCertificates</key>
  <string>false</string>
  <key>pivotal.data.pinnedSslCertificateNames</key>
  <string>$(basename $cert_path)</string>
</dict>
</plist>
EOM

echo ""
echo "======================================================"
echo "8. Run tests"
echo "======================================================"
echo ""
