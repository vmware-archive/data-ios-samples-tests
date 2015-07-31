#!/bin/bash

set -ex

source $(dirname $0)/acceptance-setup.sh

brew install node
npm install -g ios-deploy

ios-deploy --bundle $(dirname $0)/../build/Debug-iphoneos/PCFDataSample-cal.app

BUNDLE_ID=io.pivotal.ios.PCFDataSample-cal DEVICE_TARGET=9bb3f0712804e21a0cd4267175b171ba62275651 DEVICE_ENDPOINT=http://10.74.16.174:37265 cucumber

