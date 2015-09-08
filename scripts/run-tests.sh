#!/bin/bash

# 1. Fetch token for admin
# 2. Create user
# 3. Create namespace
# 4. Create collection
# 5. Fetch Certificate
# 6. Fetch token for user created in #2
# 7. Write configuration files
# 8. Run tests

set -e

[ -z $UAA_URL ] && echo "UAA_URL not set"
[ -z $UAA_ADMIN_IDENTITY ] && echo "UAA_ADMIN_IDENTITY not set"
[ -z $UAA_ADMIN_PASSWORD ] && echo "UAA_ADMIN_PASSWORD not set"
[ -z $SYSTEM_DOMAIN ] && echo "SYSTEM_DOMAIN not set"
[ -z $TARGET_DOMAIN ] && TARGET_DOMAIN=$SYSTEM_DOMAIN
[ -z $DEVICE_UDID ] && echo "DEVICE_UDID not set"
[ -z $PROFILE_ID ] && echo "PROFILE_ID not set"
[ -z $DEVICE_IP ] && echo "DEVICE_IP not set"

([ -z $UAA_ADMIN_IDENTITY ] || [ -z $UAA_ADMIN_PASSWORD ] || [ -z $UAA_URL ] || [ -z $SYSTEM_DOMAIN ] || [ -z $DEVICE_UDID ] || [ -z $PROFILE_ID ] || [ -z $DEVICE_IP ]) && exit 1

export USERNAME=$(uuidgen)
export PASSWORD=$(uuidgen)
export NAMESPACE=$(uuidgen)
export COLLECTION=objects

auth_url=https:\/\/datasync-authentication.$TARGET_DOMAIN
data_url=https:\/\/datasync-datastore.$TARGET_DOMAIN

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
payload="{\"username\" : \"$USERNAME\", \"password\" : \"$PASSWORD\"}"

curl -sk $auth_url/api/users -X POST -H "$authorization_header" -H "$content_type_header" -d "$payload"
)

echo ""
echo "======================================================"
echo "3. Create namespace"
echo "======================================================"
echo ""

(
authorization_header="Authorization: Bearer $admin_token"
payload="{\"name\" : \"$NAMESPACE\"}"

curl -sk $data_url/admin/namespaces -X POST -H "$authorization_header" -d "$payload"
)

echo ""
echo "======================================================"
echo "4. Create collection"
echo "======================================================"
echo ""

(
authorization_header="Authorization: Bearer $admin_token"
payload="{\"name\" : \"$COLLECTION\"}"

curl -sk $data_url/admin/namespaces/$NAMESPACE/collections -X POST -H "$authorization_header" -d "$payload"
)

echo ""
echo "======================================================"
echo "5. Fetch certificate"
echo "======================================================"
echo ""

cert_path=$(dirname $0)/../PCFDataSample/cert.der

$(dirname $0)/get-certificates.sh *.$TARGET_DOMAIN:443 $cert_path

echo ""
echo "======================================================"
echo "6. Fetch token for user"
echo "======================================================"
echo ""

client_id=ios-client
client_secret=006d0cea91f01a82cdc57afafbbc0d26c8328964029d5b5eae920e2fdc703169
payload_auth="username=$USERNAME&password=$PASSWORD&scope=openid&grant_type=password&client_id=$client_id&client_secret=$client_secret"

access_token=$(curl -sk $auth_url/token -X POST -d "$payload_auth" | jq '.access_token' | awk -F '"' '{print $2}')

echo $access_token

echo ""
echo "======================================================"
echo "7. Write configuration files"
echo "======================================================"
echo ""

cat > $(dirname $0)/../PCFDataSample/Pivotal.plist << EOM
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
  <string>$data_url/data/$NAMESPACE</string>
  <key>pivotal.data.collisionStrategy</key>
  <string>OptimisticLocking</string>
  <key>pivotal.data.trustAllSslCertificates</key>
  <string>false</string>
  <key>pivotal.data.pinnedSslCertificateNames</key>
  <string>$(basename $cert_path)</string>
  <key>pivotal.auth.trustAllSslCertificates</key>
  <string>false</string>
  <key>pivotal.auth.pinnedSslCertificateNames</key>
  <string>$(basename $cert_path)</string>
</dict>
</plist>
EOM

echo ""
echo "======================================================"
echo "8. Build"
echo "======================================================"
echo ""

gem install calabash-cucumber

echo "

y" | calabash-ios setup

xcodebuild -sdk iphoneos -project PCFDataSample.xcodeproj -target PCFDataSample-cal -config Debug clean build PROVISIONING_PROFILE=$PROFILE_ID

echo ""
echo "======================================================"
echo "9. Run"
echo "======================================================"
echo ""


brew install node
npm install -g ios-deploy

ios-deploy --bundle $(dirname $0)/../build/Debug-iphoneos/PCFDataSample-cal.app --id $DEVICE_UDID

BUNDLE_ID=io.pivotal.ios.PCFDataSample-cal DEVICE_TARGET=$DEVICE_UDID DEVICE_ENDPOINT=http://$DEVICE_IP:37265 cucumber

