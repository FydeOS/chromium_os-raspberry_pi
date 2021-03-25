[<img src="https://img.shields.io/badge/Join%20Telegram%20Group-FydeOS-yellowgreen.svg?style=popout-square&logo=telegram&colorA=870611&colorB=333333">](https://t.me/hi_fydeos)


[Changelog](https://github.com/FydeOS/chromium_os-raspberry_pi/blob/master/CHANGELOG.md)

<br>

# TL;DR: (in FAQ format)

<details>
  <summary>What's this, is this FydeOS?</summary>
  <br>
  
  We get it, it's confusing. There are `Chromium OS for Raspberry Pi` and `FydeOS for You - Raspberry Pi 400`, these are different releases.
  
  This project is about `Chromium OS for Raspberry Pi`, **not** `FydeOS for You - Raspberry Pi 400`. However, some of the elements that we have used to produce FydeOS for You - Raspberry Pi 400 are also open sourced in this project.
  
  The next question gives detailed differences between these confusing terms.
</details>


<details>
  <summary>What's the difference between Chromium OS, Chrome OS and FydeOS?</summary>
  <br>
  
  - Chromium OS is the open source project, used primarily by developers, with code that is available for anyone to checkout, modify, and build.
  - Google Chrome OS is the Google product that OEMs ship on Chromebooks for general consumer use.
  - FydeOS is similar to Google Chrome OS, but produced and maintained by Fyde Innovations. 
  
  Some specific differences:

  - These OS projects fundamentally share the same code base, but Google Chrome OS has some additional firmware features, including verified boot and easy recovery, which require corresponding hardware changes and thus also don't work out of the box in Chromium OS builds.
  - Google Chrome OS / "FydeOS for You" runs on specially optimised hardware in order to get enhanced performance and security.
  - Chromium OS does not auto-update by default (so that changes you may have made to the code are not blown away), whereas Google Chrome OS / FydeOS seamlessly auto-updates so that users have the latest and greatest features and fixes.
  - Google Chrome OS / FydeOS includes some proprietary/commercial/licensed packages which are not included in the Chromium OS project.
  - In consequence of the above, Google Chrome OS / FydeOS supports Android subsystem, Chromium OS does not.
  - Google Chrome OS has a green/yellow/red logo, Chromium OS has a blue/bluer/bluest logo, FydeOS has a weird grey/black/red logo and it may change in the future.

</details>


<details>
  <summary>Can I build Chromium OS? Can I build FydeOS?</summary>
  <br>
  
   - Yes you can build Chromium OS, in fact this project is all about building your own Chromium OS for Raspberry Pi as well as offering pre-built images using the provided build artefacts.
   - No you can't build FydeOS - same reason that you can't build Google Chrome OS.
</details>


<details>
  <summary>I don't want to be bothered with the technicalities, where are the download links?</summary>
  <br>
  
   - To download pre-built Chromium OS for Raspberry Pi, head over to [releases](https://github.com/FydeOS/chromium_os-raspberry_pi/releases) tab, you will find all historical releases as well as important release notes. Please do read the release note!
   - To download FydeOS for You - Raspberry Pi 400, please use the [Download](https://fydeos.com/download) page of the FydeOS official site.
</details>


<details>
  <summary>Where to get help?</summary>
  <br>
  
  You are welcome to open an issue in this project if:
   - You've read the entire developer guide and even watched the [build demonstration video](https://youtu.be/og4wzzIfGA0), and then you are attempting to build Chromium OS but have encountered problems
   - You believe your copy of the Chromium OS for Raspberry Pi isn't functioning correctly as it should be

  Your issues will likely to get closed if:
   - You are asking about FydeOS for You - Raspberry Pi 400: for this please use [FydeOS Community](http://community.fydeos.com/) or join [Official FydeOS Telegram Group](http://t.me/hi_fydeos)
   - You are asking generic features/bugs about Chromium OS / Chrome OS itself: for this please use use [chromium-os-dev Google Group](https://groups.google.com/a/chromium.org/g/chromium-os-dev) or report bugs to [CRBUGS](https://bugs.chromium.org/)
   - You are asking issues about a 3rd-party app, a non-standard peripheral device or a special setup that does not benefit the general community
</details>



<br><br>

# Table of contents (for cool kids)

<!-- TOC -->

- [Introduction](#introduction)
- [System requirement](#system-requirement)
- [Prepare the system](#prepare-the-system)
- [Get Chromium OS source code](#get-chromium-os-source-code)
- [Setup Raspberry Pi overlay](#setup-raspberry-pi-overlay)
- [Setup local chromium source](#setup-local-chromium-source)
- [Build Chromium OS for Raspberry Pi](#build-chromium-os-for-raspberry-pi)
- [Boot Raspberry Pi from the image](#boot-raspberry-pi-from-the-image)
- [Video demonstration of the build process](#video-demonstration-of-the-build-process)
- [More information](#more-information)
- [About us](#about-us)
  <!-- /TOC -->



# Introduction

This document describes how to build and run Google [Chromium OS](https://www.chromium.org/chromium-os) on Raspberry Pi 3B, 3B+, 4B and the Pi 400 personal computer kit(Pi400 hereafter), from its source code and the board overlay hosted in this repository.

These overlays and the document has been tested against Raspberry Pi 3B, 3B+, 4B and Pi400 by FydeOS team. It **will not work** on any earlier version of the Raspberry Pi line-up.

## Goal of this project

* To provide a usable Chromium OS pre-built image that everybody can download and use that offers a similar experience to Chrome OS 
* To provide a open-source code base that everybody can use to build and improve Chromium OS on Raspberry Pi.
* This project does not aim to provide support for Chromium OS itself. If you find bugs and glitches, please report to [crbugs](https://bugs.chromium.org/p/chromium/issues/list); if you have further queries regarding Chromium OS, plase revert to one of the official Chromium related [Google groups](https://www.chromium.org/developers/technical-discussion-groups).

## About this repository

The code and document in this repository is the result of works by the people of the FydeOS team. We previously worked on this overlay internally and released a few disk images for Raspberry Pi to the public. Now we open this to the public.

### Branches and tags in this repository

There was a big change regarding the graphics stack in Chrome OS. Before release 57, Xorg/X11 was used. Beginning from release 57, Chrome OS moved to the Freon graphics stack, which is a modern display system developed solely for Chrome OS by Google.

#### branches

 - `master` - this branch can be used to build a Chromium OS image with Freon as the graphics stack. It has been tested against our current release version. You are welcome to test it with future releases and send feedback and/or PRs.

#### tags

 - When we do release a prebuilt image, the commit would be tagged with a release number correspond to the repo manifest. For example, if the repo manifest release is `release-R80-12739.B`, then our release tag would be `r80`.
 - Often we will be doing more than one releases for each repo manifest release number, so we will append meaningful string to the tag name to identify such. For example: `r80-hardware_acceleration`


## Typography Conventions

Shell Commands are shown with different labels to indicate whether they apply to 

 - your build computer (the computer on which you're doing development)
 - the chroot (Chromium OS SDK) on your build computer
 - your Chromium OS computer (the device on which you run the images you build)


| Label     | Commands                                   |
| --------- | ------------------------------------------ |
| (outside) | on your build computer, outside the chroot |
| (inside)  | inside the chroot on your build computer   |


# System requirement

* A x86_64 system to perform the build. 64-bit hardware and OS are must. The Chromium OS is a very large project, building from the source form scratch usually takes hours to over 10 hours, depends on the system configuration.
  * CPU: we recommend using a 4-core or higher processor. The Chromium OS build process runs in parallel so more cores can help shorten build time dramatically.

  * Memory: we recommend at least 16GB, plus enough swap space, because for the purpose of this project you will need to build Chromium from source code. Linking Chromium required between 8GB and 28GB of RAM as of March 2017, so you will run into massive swapping or OOM if you have less memory. However, if you are not building your own copy of Chromium, the RAM requirements will be substantially lower at a cost of losing some of the key features provided by this project.

  * Disk: at least 100GB of free space, 200GB or more is recommended. SSD could noticeably shorten the build time as there are many gigabytes of files need to be written to and read from the disk.

  * Network: total source code downloading will be over 10GB. A fast and stable Internet access is going to be very helpful.

* A x86_64 Linux OS, it is called as the host OS later in this doc. The Chromium OS build process utilises chroot to isolate the build environment from the host OS. So theoretically any modern Linux system should work. However, only limited Linux distros are tested by the Chromium OS team and the FydeOS team. Linux versions that are known to work:

  * Ubuntu Linux 18.04 LTS
  * Gentoo Linux

* A non-root user account with sudo access. The build process should be run by this user, not the root user. The user need to have _sudo_ access. For simplicity and convenience password-less sudo could be set for this user.



# Prepare the system

## Install necessary tools

Git and curl as the essential tools need to installed in the host OS, you will also need Python3 for most of the scripting work in the build process.

```bash
(outside)
sudo apt-get install git-core gitk git-gui curl lvm2 thin-provisioning-tools \
     python-pkg-resources python-virtualenv python-oauth2client xz-utils \
     python3.6

# If Python 3.5 is the default, switch it to Python 3.6.
python3 --version
# If above version says 3.5, you'll need to run:
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.5 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 2
sudo update-alternatives --config python3
```

This command also installs git's graphical front end (`git gui`) and revision history browser (`gitk`).


## Install Google depot_tools

The depot_tools is a software package of scripts, provided by Google, to manage source code checkouts and code reviews. We need it to fetch the Chromium OS source code.

```bash
(outside)
$ sudo mkdir -p /usr/local/repo
$ sudo chmod 777 /usr/local/repo
$ cd /usr/local/repo
$ git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

```

Then add depot_tools directory to PATH and setup proper umask for the user who is going to perform the build. Add below lines to the file `~/.bash_profile` of that user. Or if you are using a different shell, handle that accordingly.

```bash
(outside)
export PATH=/usr/local/repo/depot_tools:$PATH
umask 022
```

Then re-login to make above changes take effective.


## Configure git

Better configure git now or it may complain in some operations later.

```bash
(outside)
$ git config --global user.email "you@email.address"
$ git config --global user.name "Your Name"
```



# Get Chromium OS source code

## Create directory structure

The directory structure described here is a recommendation based on the best practice in the Fyde team. You may host the files in a different way as you wish.

```bash
(outside)
# This is the directory to hold Chromium OS source code， aka cros-sdk
$ mkdir -p /path/to/cros-pi
```

If you are building a different release, make sure you use the actual directory name on your own system, the name here mentioned is just an example.


## Fetch Chromium OS source code

First you need to find out the reference name of the release you would like to build, by visiting this page [https://chromium.googlesource.com/chromiumos/manifest.git](https://chromium.googlesource.com/chromiumos/manifest.git):

You will see a list of Git commit IDs and its name in the form of `refs/heads/release-Rxx-xxxx.B`. That `release-Rxx-XXXX.B` link is what you need for fetching the code of that specific Chromium OS release. For example, [release-R86-13421.B](https://chromium.googlesource.com/chromiumos/manifest.git/+/refs/heads/release-R86-13421.B) for release r86.

Now run these commands to fetch the source code. Find and use a different release name if you would like to build a different release.

```bash
(outside)
#Assuming you understand what /path/to means. If not, replace it with '~'
$ cd /path/to/cros-pi

$ repo init -u https://chromium.googlesource.com/chromiumos/manifest.git --repo-url https://chromium.googlesource.com/external/repo.git -b release-R86-13421.B

# Raise this number if you have a fast internet connection
$ repo sync -j8
```

Fetching of Chromium OS source code may take 10 to more than 30 minutes depends on your connection speed, around 10GB of data will need to be downloaded primarily from googlesource.com, it'd be helpful if you have a decent internet speed to reach google's server.



## Request for Google API key

If you would like to login into the Chromium OS GUI by using your Google account, you will need to request for Google API key and include them in the disk image you build. Since the only authentication mechanism included in Chromium OS is Google ID, you probably will need this or you will only be able to login as guest user.

Apply for Google API on Google website per [this document](http://www.chromium.org/developers/how-tos/api-keys). After acquired the client ID, client secret and API key, put then in ```~/.googleapikeys``` file as in below format.

```
'google_api_key': 'your api key',
'google_default_client_id': 'your client id',
'google_default_client_secret': 'your client secret',
```

Then the Chromium OS build script will read necessary information from this file automatically, and the image you build will allow Google ID login.



# Setup Raspberry Pi overlay

Now fetch this overlay, also create symlinks in the designated place.

```bash
(outside)
$ cd /path/to/overlays
$ git clone https://github.com/fydeos/chromium_os-raspberry_pi.git .

$ cd /path/to/cros-pi/src/overlays
$ ln -s /path/to/overlays/* .
```

By now, your `cros-pi/src/overlays` directory should have included symbolic links for:

- `project-cros-pi`
- `baseboard-rpi3`
- `overlay-rpi3`
- `overlay-rpi4`
- `chipset-bcm2837`



# Setup local chromium source

It's recommended to build chromium browser on your local setup so that your Chromium OS for Raspberry Pi could benefit from the additional functionalities like kiosk mode, you will also have the option to incorporate your own modifications. If you wish to do so, you need to prepare the necessary files prior to entering the cros_sdk.

As far as this project is concerned, the chromium source that we use to build our releases can be found in the [chromium-raspberry_pi](https://github.com/FydeOS/chromium-raspberry_pi) project. You may also choose to use Google's vanilla chromium repository which can be found [here](https://chromium.googlesource.com/chromium/src.git/).

Note that we use a much simpler way to manage releases, with our [chromium-raspberry_pi](https://github.com/FydeOS/chromium-raspberry_pi) project you need to select the correct branch corresponding to the [repo manifest](#fetch-chromium-os-source-code) you used in previous step to sync your Chromium OS code. For example, if you are building r86, you will then need to look out for "`chromium-m86`" branch under [chromium-raspberry_pi](https://github.com/FydeOS/chromium-raspberry_pi). The letter "m" stands for "milestone" and it correlates to the release number for Chromium OS(r86 in this case). Choosing an unmatched chromium milestone branch and Chromium OS repo will probably result in endless build errors.

With Google's repository, you need to choose a correct release tag rather than branch. For example, if you are building r86, you can browse all existing chromium release tags on [this page](https://chromium.googlesource.com/chromium/src.git/) and deduce that the latest tag on your desired milestone version. At the point where this was written, this would be [86.0.4240.260](https://chromium.googlesource.com/chromium/src.git/+/refs/tags/86.0.4240.260).

Having understood the above, now create a directory parallel to your Chromium OS repo to house the chromium source:

```bash
(outside)
$ mkdir chromium-pi
$ cd chromium-pi
$ mkdir src
$ cd src
```

Now clone the desired chromium project:

```bash
(outside)
# use our chromium repo
$ git clone git@github.com:FydeOS/chromium-raspberry_pi.git .

# use google's vanilla chromium
$ git clone https://chromium.googlesource.com/chromium/src.git . 
```

Note that chromium is a HUGE project, cloning the entire repo will require ~15GB of disk space and will require about 2 hours to complete even if you have a decent internet speed.

Then choose the correct branch/tag

```bash
(outside)
#with our chromium repo
$ git checkout chromium-m86

#with Google's repo and you wish to build for r86
$ git checkout 86.0.4240.260
```

Now you need to create a config file known to gclient for syncing the chromium dependecies:

```bash
(outside)
$ cd ..
# now you should be in /path/to/chromium-pi
$ touch .gclient
```

The .gclient file should have the following content, note that you should replace the correct branch name to the `url`field (in this example we use `chromium-m86`) you may also replace the `url` value to Google's per your setup.

```
solutions = [{'custom_deps': {},
  'custom_vars': {},
  'deps_file': '.DEPS.git',
  'managed': False,
  'name': 'src',
  'url': 'git@github.com:FydeOS/chromium-raspberry_pi.git@refs/remotes/origin/chromium-m86'}]
target_os = ['chromeos']
```

Now you can start syncing:

```bash
(outside)
$ gclient sync
```

Note, due to an existing issue with WebRTC, during syncing you may encounter a git related error complaining fetch failure. A temporary fix is to manually edit the `src/third_party/webrtc/.git/config` file under the WebRTC folder:

```
[core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
[remote "origin"]
        url = https://webrtc.googlesource.com/src.git
        fetch = +refs/heads/*:refs/remotes/origin/*
        fetch = +refs/branch-heads/*:refs/remotes/branch-heads/*
[branch "master"]
        remote = origin
        merge = refs/heads/master
```

Once gclient sync is completed, chromium source folder is now fully setup.



# Build Chromium OS for Raspberry Pi

## Create the chroot

As mentioned above, a chroot environment will be used to run the actual build process and some other related tasks. To create the chroot environment, run below commands.

```
(outside)
$ cd /path/to/cros-pi
$ cros_sdk
```

If you wish to build your own chromium and you have follow the steps to set it up, you need to specify it when entering the cros_sdk by:


```bash
(outside)
$ cd /path/to/cros-pi
$ cros_sdk --chrome-root /path/to/your/chromium-pi #absolute path needed
```


It make take 10 to over 30 minutes depends on your internet connection speed and disk speed. Once finished, it will enter into the chroot. The shell prompt string looks like below so it is very easy to tell whether you are currently in the chroot or not.

```
(inside)
(release-R86-13421.B/(xxxxxx...)) <user>@<host> ~/trunk/src/scripts $
```

The chroot environment is located under the `/path/to/cros-pi/chroot` directory.

Let's exit from the chroot first as we need to do some customisation before moving on. Type `exit` or `ctrl + d` to exit from the chroot shell.

Usually the chroot only needs to be created once and can be used to build a board many times or build different boards. It very rarely need to be removed/re-created.


### Delete the chroot

If you would like to remove the chroot and re-create it from scratch, don't delete the `chroot` directory directly. As there could be directories from the host OS bind mounted in the chroot, a `rm chroot` command could actually remove files from your host OS undesirably.

The correct way to remove the chroot is by using below commands.

```bash
(outside)
$ cd /path/to/cros-pi
$ cros_sdk --delete
```


## Setup bind mount directories for chroot

Programs running inside the chroot will not be able to access files outside of the chroot. One way to circumvent this is to bind mount those files into a directory inside the chroot.

When entering the Chromium OS chroot environment, a file named `.local_mounts` will be checked and directories listed in it will be bind mounted inside the chroot. All we need to do is to create this file in the right place and put necessary contents in, by using below command.

```bash
(outside)
$ echo "/path/to/overlays" > /path/to/cros-pi/src/scripts/.local_mounts
```

Now, after entered the chroot, a `/path/to/overlays` directory will exist in the chroot and its content is the same as the `/path/to/overlays` directory in the host OS, as it actually is bind mounted from the host OS.

If we don't do this, the `/path/to/cros-pi/src/overlays/overlay-rpi4` symbolic link will not be accessible, as the top directory (`/path/to/overlays`) it points to doesn't exist in the chroot.


## Enter the chroot

Now we can enter the chroot.

```bash
(outside)
$ cd /path/to/cros-pi
$ cros_sdk
```

It is the same command used to create the chroot. It creates the chroot if one does not exist, and enters the chroot if there is already one.

And we can check whether above `.local_mounts` setup was done correctly. 

```bash
(inside)
$ ls /path/to/overlays/             # You should be able to see the same content as in host OS.
$ ls ../overlays/overlay-rpi4/      # You should be able to see the content of this repo.
```

Move on if it works well. If not, check and make sure you set up `.local_mounts` correctly.


## Set password for the chronos user

The chronos user is used to log into the command line interface of Chromium OS, via SSH, local console or the shell in crosh interface. It is recommended that a password is set for this user so you can login as this user and also can do `sudo` in the Chromium OS command line, for advanced tasks.

To set password for chronos user, run below command.

```bash
(inside)
$ ./set_shared_user_password.sh
```

Type in a password when been prompted. If you would like to change the password, simply run the command again.

The password is encrypted and saved in the file `/etc/shared_user_passwd.txt` in the chroot. You only need to set it once and it will be used for all the images you build, unless you re-create the chroot.


## Setup Raspberry Pi board

In the Chromium OS terminology, a board refers to a class of computer platform with distinct hardware configurations. The board will be used as a target in the process of building software packages and disk image for that specific computer platform.

There are many boards exist in the Chromium OS code base. They are either development platforms or real selling hardware products running Chrome OS, such as Chromebooks you can buy from many vendors.

The Chromium OS project utilises the Portage package management system from Gentoo Linux. Each board lives in its own "overlay", which holds distinct build configuration, system configurations, collection of software packages, system services, disk image customisation etc. for that board.

In our case here, we created a board named "rpi4" and it refers to the Raspberry Pi 4B. And we call the overlay "overlay-rpi4", all its files are hosted in this repository.

To build Chromium OS for a board, the first thing is to initialise the board from its overlay.

**Beginning from release 86 and onwards, we have done some efforts to add Raspberry Pi 3B/3B+ support to the Raspberry Pi 4B overlay. The following steps we will be using the rpi4 board as example, the result image will work on both Raspberry Pi 3B/3B+.**

```bash
(inside)
$ setup_board --board=rpi4
```

Again, it may take 10 to over 30 minutes depends on the speed of your internet connection and disk i/o.

Once it's done, a directory structure for the "rpi4" board will be created under `/build/rpi4` of the chroot.


### Re-initialise the board

It is usually not necessary to re-initialise the board as what you have already built will be lost, and you will have to spend hours to rebuild all packages from scratch. But if you really need to do so, just re-run the same setup_board command with the `---force` option.

```bash
(inside)
$ setup_board --board=rpi4 --force
```

The `--force` option will remove the existing board directory `/build/rpi4` and re-create it from scratch.


## Build packages

Now it time to build all software packages for the rpi4 board.

```bash
(inside)
$ ./build_packages --board=rpi4 --nowithautotest 
# Append "--nowithautotest" to speed up the build process by skipping some tests
```

It may take hours depending on your processor power, your memory size, your disk speed and the quality of your internet connection. Here are some examples for you to adjust your expectation: 

- On a decent machine with 4 cores 8 threads, 16GB memory, files on regular HDD, and 100Mb broadband, it takes about 5 to 6 hours for the command to finish.
- On a Workstation-grade server with AMD Threadripper 3990x CPU with 64-core 128-thread, 128GB memory and 300Mb broadband, it takes 44mins for the command to finish.


### Things to note

- **What is happening now**

  The `build_packages` script acts as an entry point to initialise a series of processes aiming to compile all the necessary software packages from source code and build them together forming Chromium OS as a whole. During the process there are a few required dependencies will be fetched and cloned from GitHub, so please do ensure a decent internet connection to github.com.


- **When interrupted**

  The build process is incremental. If it gets interrupted for any reason, you can always re-run the same `build_packages` command and it will resume the build instead of rebuild from scratch.

- **Read the output**

  The `build_packages` command throw out a lot of information on the console. Fortunately those information are very well organised.

  - <span style="color:red">Red text</span>: these are error messages and very likely will cause the build process to break.
  - <span style="color:green">Green text</span>: these are useful messages printed by the build script itself. They are useful when debugging problem.
  - White text: these are regular information that mostly are printed by the commands called in the build script. They provide more details about the build process thus are also useful for debugging.

- **Read the logs**

  The `build_packages` script spends most of its airtime on running the `emerge` commands, to build, install and pack those hundreds of software packages required by the overlay. The `emerge` command is from the Portage system of Gentoo Linux.

  The `emerge` command saves the output of its building, installation and packing process into log files. These files are extremely useful if there is failure when building packages. Those log files are located under the `/build/rpi4/tmp/portage/logs` directory of the chroot. They are plain text files so can be viewed right from your commandline interface.


## Build the disk image

After the build_packages command finished successfully, you can start building the disk image.

```bash
(inside)
$ ./build_image --board=rpi4 --noenable_rootfs_verification
# Append --noenable_rootfs_verification flag to enable root file system read/write on the built image
```

It may take 10 to 30 minutes, mainly depends on the speed of your disk. It will be much faster on SSD than on HDD.


### Find your image

After the command finished successfully, you will have disk images generated, saved under `/mnt/host/source/src/build/images/rpi4/` directory in the chroot, or `/path/to/cros-pi/src/build/images/rpi4` in the host OS. These two are the same directory, just bind mounted in the chroot.

Each invoke of the build_image command will create a directory named similar to `R86-XXXX.XXX.<date time>-a1` under above directory. There is a symlink named `latest` under above directory, that always point to the image directory of the last successful build.

The disk image is usually named `chromiumos_image.bin`, under abovementioned directory. So full path to the latest image is

```
/mnt/host/source/src/build/images/rpi4/latest/chromiumos_image.bin
```

in the chroot, and

```
/path/to/cros-pi/src/build/images/rpi4/latest/chromiumos_image.bin
```

in the host OS.



# Boot Raspberry Pi from the image

The Raspberry Pi boots from the SD card so we need to write the previously generated disk image on to the SD card. A SD card of at least 8GB capacity is required.


## Write the disk image to a SD card

There are two usual ways to write the Chromium OS disk image to a SD card. You can copy the image out to another Window/macOS/Linux system and write it using your favorite GUI/CLI application. It is the same as writing other Linux images for Raspberry Pi, so will not be explained here.

Another Chromium OS specific way is by using the `cros` command in the chroot.


### Write the image by using the `cros` command

First plug the SD card into the box used to build the image and has the chroot. Then run below command.

```
(inside)
$ cros flash usb:// rpi4/latest
```

This asks to write the latest disk image to USB removable media. A list of USB removable media will be presented, with index number prefixed. You can select which USB drive to write to by type in the index number when prompted.



## Boot from the SD card

After the disk image is successfully written to the SD card, plug it into the Raspberry Pi and boot it as usual. After a few seconds you will see a Chromium logo, later on it will boot into GUI mode and the first time setup screen (OOBE) will pop up for you to configure the system and login.


# Video demonstration of the build process

<https://youtu.be/og4wzzIfGA0>


# More information

[Chromium OS Developer Guide](http://www.chromium.org/chromium-os/developer-guide). This is the official source of how to build Chromium OS

[The FydeOS website](https://fydeos.com), our home.

[FydeOS official Telegram group](https://t.me/hi_fydeos), to say hi and get help.


# About us

Fyde began with a vision where all applications and services we use today will be living in the Cloud. We believed that with the ever advancing browser platform technology and web frontend performances, it’s not surprising that most things we do today with the internet can be done through a single browser window. We are stepping into an era where installable apps will soon become history. FydeOS is our answer to this new era for computing.

FydeOS is a simple, secure, fast and productive operating system. Based on the open-source Chromium Project that also powers the well-known Google Chromebooks. FydeOS inherits most of the benefits that Chromebooks have but also bundled with our enhancements and new features. We have turned FydeOS into a more open platform, users will no longer be forced to rely on Google services and have the freedom to choose whichever services they prefer. We have also made FydeOS run on a wider range of hardware platforms ranging from x86 PCs and ARM based single board computers, providing endless of possibilities and potentials of how FydeOS can be used and applied.
