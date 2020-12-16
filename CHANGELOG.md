# Changelog

### 2020-12-16
##### Refactoring and add wifi support for Pi400

 - **Purpose**
    
    Refreshed the overlays updated README to reflect a recent full run-through of the build process.

 - **Changes highlight**

   - Name changes
     - The umbrella project `project-fyde-for-rpi` is renamed to `project-cros-pi`: There is no "fyde" in there
     - Updated `chromeos-chrome-86.0.4240.260_rc-r1.ebuild` to reflect recent rebase of the chromium project

   - Location changes
     - The Linux kernel used in for building Chromium OS is now moved from <https://github.com/FydeOS-for-You-overlays/kernel-rpi> to this group, named <https://github.com/FydeOS/kernel-raspberry_pi>
     - To reflect the kernel location change, also updated `raspberry-kernel-5.4.74-r2.ebuild` file.

   - Removals
     - Removed an unnecessary power management policy borrowed from other board

   - License updates
     - Updated ebuild files front matter, copyright text, homepage and some descriptions
     - Updated contact email address and removed personal information
     - Updated License to BSD in consistency with the project

   - README updates
     - Directory name fixes and added some additional information
     - Refreshed the build process description

### 2020-07-12
##### Tweaked and enabled PNaCl
* so that things like Zoom/Polarr can now work on Chromium OS for Raspberry Pi.


### 2020-02-10
##### Relocate CHANGELOG to a single separate file.


### 2020-01-16
##### Maintenance and enhancement
* Rename the project to `chromium_os-raspberry_pi` to comply with our standard usage of `-` and `_`: `_` as separators for within words and `-` for words connector / preposition replacement
* Added support for kiosk mode
* Updated README for building with local chromium source.
* Added corresponding projects [chromium-raspberry_pi](https://github.com/FydeOS/chromium-raspberry_pi) and [kiosk-demo-app](https://github.com/FydeOS/kiosk-demo-app) for building with kiosk mode enabled

### 2019-11-19
##### Maintenance and enhancement
* Added support for vpd(vital product information) storage capability.
* Fix system freeze and crash caused by `cras` 


### 2019-09-25
##### Added Raspberry Pi 4B support
* Same known issues with the 3B/3B+ release
* A separate overlay needs to be created for Raspberry Pi 4, named "overlay-rpi4". If you are building the image yourself make sure you use `--board=rpi4` rather than rpi3

### 2019-09-12
##### Updated Chromium OS platform manifest to [release-R77-12371.B](https://chromium.googlesource.com/chromiumos/manifest/+/refs/heads/release-R77-12371.B)
* No hardware acceleration support for decoding video streaming, yet. [ref](https://cs.chromium.org/chromium/src/media/gpu/gpu_video_decode_accelerator_factory.cc)
* Removed unused code
* Fixed static version naming in the README
* Added Telegram group link

### 2019-01-29
##### Fix Slack invitation link, oops 😅

### 2019-01-28
##### Add [Slack channel](https://chromium-os-for-sbc.slack.com/messages/CFPSV215F/) for better community experience.


### 2019-01-24
##### Update to Chromium OS r72
* The overlays are now updated to build Chromium OS r72, with Chromium OS manifest pointing to `release-R72-11316.B` and Chromium at `72.0.3626.54` tag.
* Added optional SD card expansion script, courtesy of FydeOS.
* Added missing firmware from latest official Raspbian release.
* Fixed various build issues from previous release.

### 2018-11-19
##### Update to Chromium OS r70
* The overlays are now updated to build Chromium OS r70
* Fix poor graphic performance with full hardware accelecration enabled.
* Add firmware support for Raspberry Pi 3B+. Note that although kernel patches for brcm are in place, there are still issues with wifi with this release.
* You can build packages with "cros_embedded" (or uncomment the USE flags in `overlay-/make.conf`) to produce a more efficient image.
