# The Chrome ICU package

This ebuild builds and installs the [icu package in chrome][chrome-icu-location]
so that it can be used in Chrome OS. Compared with the vanilla ICU library, it
is customised for Chrome so there are some missing functionality and encoding
(e.g. ISO-2022-CN and ISO-2022-KR). But it should be powerful enough for most
usages. (It supports the i18n of Chrome!)

[TOC]

## Why chrome-icu?

The biggest reason is to save resources. Chrome-icu saves,

1.  10MB of rootfs disk space due to sharing the icu data.
2.  Up to 10MB of RAM because of sharing the icu data.
3.  Maintaining effort in Chrome OS (icu needs regular major uprev every 6
    months and small bug fixes from time to time).

## How to use it?

> Please give us a heads-up if you want to use it. This is because chrome-icu
> is currently a static library, so linking it will non-trivially increase the
> disk space. And if the users of chrome-icu become more and more, we will
> spend the effort to make it into a shared library. (This will not affect your
> usage, please see [the tracker][make-into-shared-library].)

1.  Add `chrome-icu` as a dependency in your ebuild.
2.  Link `icui18n-chrome` and `icuuc-chrome` libraries.
3.  Add header paths `${sysroot}/usr/include/icu-chrome/common` and
    `${sysroot}/usr/include/icu-chrome/i18n`.
4.  If some headers are missing, you can add them to [here][chrome-icu-headers].
5.  At run time, load the icu data file from `/opt/google/chrome/icudtl.dat`.
    You can follow the example [here][ml-service-load-icu-data].

## TODO

1.  We should consider
    [setting up a CQ tryjob for chrome-icu][chrome-side-tryjob-tracker],
    although this has become not very urgent after we
    [only configure the icu package][cl-that-only-configure-icu] in compiling
    chrome-icu.
2.  We should consider having a `build-chrome.eclass` and avoid the duplication
    between `chromeos-chrome.ebuild` and `chrome-icu.ebuild`. (We used to
    duplicate the code because chrome-icu used to be very experimental so we do
    not want to greatly change the `chromeos-chrome.ebuild` for it. With
    chrome-icu method becoming stable, we can consider it now.)

## Other questions

### Emerging chrome-icu in cros chroot takes ages. What happened and how to resolve it?

This normally means that there is no prebuilt binary available for chrome-icu
so it has to build chrome-icu from source and this needs the whole chrome repo.
Because chrome-icu and chrome share a similar build mechanism, this usually
implies that there is no prebuilt binary available for chrome too. So if you
just did a repo sync and found it has to build chrome-icu from source in running
`build_packages`, it means you will also need to build chrome from source too
--- it is only because chrome depends on chrome-icu so the latter will be built
first.

How to resolve it: There are a few methods that you could try,

1.  Run `emerge-$BOARD -G chrome-icu` and see if this succeeds and
    satisfies your needs. (This command enforce emerging chrome-icu from
    prebuilt binary.)
2.  If this is because the repo synced is very fresh, consider syncing to an
    older version of Chrome OS (e.g. [sync to green][sync-to-green]).
3.  If this is caused by changing configurations (e.g. USE flag changes), you
    could let chrome-icu built from your local chrome checkout. First, you
    need to enter your chroot with the `--chrome-root` option pointing to your
    local chrome checkout. Then after entering the chroot, the chrome checkout
    is located at "~/chrome_root". Second, now you can run
    `CHROME_ORIGIN=LOCAL_SOURCE emerge-$BOARD chrome-icu` to build it form
    local chrome checkout.

### Why is chrome-icu a static library, not a shared library?

This is because: First, making it into a static library is easier and
requires less modifications in chrome; Second, currently only two packages
are using it, and total size increase of linking it statically is smaller
than that of making it into a shared library.

### After we make chrome-icu into a shared library, can chrome use it too to save more disk space?

The answer is no. This is because in chrome, icu is compiled with
"control-flow integrity (CFI)" turned on. And CFI currently does not work
well with shared libraries.

### I want to use the chrome-icu mechanism to share other code in Chrome with Chrome OS. How should I do this?

Theoretically, the method used by chrome-icu should be able to share any
code in chrome to Chrome OS. But considering that 1) the chrome-icu method
is still very new and 2) it requires changes in both chrome and the infra
configurations, we recommend you to first chat with the Chrome OS build team
to discuss about your problem before moving forward. And there are other
(e.g. more lightweight) [sharing methods](http://go/chromeos-code-sharing) which
may be more suitable.


[chrome-side-tryjob-tracker]: https://crbug.com/1133101
[cl-that-only-configure-icu]: https://crrev.com/c/2524460
[sync-to-green]: https://chromium.googlesource.com/chromiumos/docs/+/HEAD/developer_guide.md#sync-to-green
[make-into-shared-library]: https://crbug.com/1152936
[chrome-icu-headers]: https://chromium.googlesource.com/chromiumos/overlays/chromiumos-overlay/+/HEAD/chromeos-base/chrome-icu/chrome-icu-9999.ebuild#629
[ml-service-load-icu-data]: https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/ml/machine_learning_service_impl.cc#75
[chrome-icu-location]: https://source.chromium.org/chromium/chromium/src/+/main:third_party/icu/
