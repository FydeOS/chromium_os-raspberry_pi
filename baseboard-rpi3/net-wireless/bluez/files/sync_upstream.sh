#!/bin/bash
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script does a one-time sync from BlueZ upstream to Chromium's mirror.
# Call this from inside cros_sdk. Special permission is needed to push to
# Chromium's upstream/master branch.

UPSTREAM_URL=https://git.kernel.org/pub/scm/bluetooth/bluez.git
LOCAL_CHECKOUT=/mnt/host/source/src/third_party/bluez/upstream
UPSTREAM_REMOTE=sync-upstream
CHROMIUM_BRANCH=upstream/master

die() {
  echo "ERROR: $*" >&2
  exit 1
}

cd "${LOCAL_CHECKOUT}" || die "Local checkout ${LOCAL_CHECKOUT} does not exist."

# Add remote of upstream if doesn't exist yet.
git config "remote.${UPSTREAM_REMOTE}.url" >/dev/null || \
    git remote add "${UPSTREAM_REMOTE}" "${UPSTREAM_URL}"

if [[ "$(git remote get-url "${UPSTREAM_REMOTE}")" != "${UPSTREAM_URL}" ]]
then
  die "Failed: ${UPSTREAM_REMOTE} URL is not ${UPSTREAM_URL}"
fi

echo Fetching from upstream...
git fetch "${UPSTREAM_REMOTE}" master || die "Failed fetching from upstream."

echo Pushing to Chromium: "$(git remote get-url cros) ${CHROMIUM_BRANCH}"...
git push cros "${UPSTREAM_REMOTE}/master:refs/heads/${CHROMIUM_BRANCH}" || \
    die "Failed pushing to Chromium. Check your push permission?"

echo Done.
