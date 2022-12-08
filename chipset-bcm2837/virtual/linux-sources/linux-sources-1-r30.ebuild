# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

# Copyright 2012 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="Chrome OS Kernel virtual package"
HOMEPAGE="http://src.chromium.org"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="*"

IUSE_KERNEL_VERS=(
	kernel-4_4
	kernel-4_14
	kernel-4_19
	kernel-5_4
	kernel-5_10
	kernel-5_15
	kernel-experimental
	kernel-next
	kernel-upstream
	kernel-upstream-mainline
	kernel-upstream-next
)
IUSE="${IUSE_KERNEL_VERS[*]}"
# exactly one of foo, bar, or baz must be set, but not several
REQUIRED_USE="^^ ( ${IUSE_KERNEL_VERS[*]} )"

RDEPEND="
	kernel-4_4? ( sys-kernel/chromeos-kernel-4_4 )
	kernel-4_14? ( sys-kernel/chromeos-kernel-4_14 )
	kernel-4_19? ( sys-kernel/chromeos-kernel-4_19 )
	kernel-5_4? ( sys-kernel/chromeos-kernel-5_4 )
	kernel-5_10? ( sys-kernel/raspberry-kernel )
	kernel-5_15? ( sys-kernel/chromeos-kernel-5_15 )
	kernel-experimental? ( sys-kernel/chromeos-kernel-experimental )
	kernel-next? ( sys-kernel/chromeos-kernel-next )
	kernel-upstream? ( sys-kernel/chromeos-kernel-upstream )
	kernel-upstream-mainline? ( sys-kernel/upstream-kernel-mainline )
	kernel-upstream-next? ( sys-kernel/upstream-kernel-next )
"

# Add blockers so when migrating between USE flags, the old version gets
# unmerged automatically.
RDEPEND+="
	$(for v in "${IUSE_KERNEL_VERS[@]}"; do echo "!${v}? ( !sys-kernel/chromeos-${v} )"; done)
"

# Default to the latest kernel if none has been selected.
# TODO: This defaulting does not work. Fix or remove.
RDEPEND_DEFAULT="sys-kernel/chromeos-kernel-5_4"
# Here be dragons!
RDEPEND+="
	$(printf '!%s? ( ' "${IUSE_KERNEL_VERS[@]}")
	${RDEPEND_DEFAULT}
	$(printf '%0.s) ' "${IUSE_KERNEL_VERS[@]}")
"
