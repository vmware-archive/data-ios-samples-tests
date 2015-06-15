#!/bin/bash

set -x
set -e

source acceptanceconfig
xcrun simctl shutdown booted || true
xcrun simctl erase all || true

cucumber
