#!/bin/bash

set -x
set -e

source $(dirname $0)/acceptance-setup.sh

gem install calabash-cucumber

echo "

y" | calabash-ios setup

xcodebuild -sdk iphoneos -project PCFDataSample.xcodeproj -target PCFDataSample-cal -config Debug clean build PROVISIONING_PROFILE="c36664a7-cd05-4879-aabd-1f9c89056961"
