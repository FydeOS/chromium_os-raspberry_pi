# Table of contents
<!-- TOC -->

- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
    - [About this repository](#about-this-repository)
        - [Branches in this repository](#branches-in-this-repository)
        - [Goal of this repository](#goal-of-this-repository)
    - [Typography Conventions](#typography-conventions)
- [System requirement](#system-requirement)
- [Prepare the system](#prepare-the-system)
    - [Install necessary tools](#install-necessary-tools)
    - [Install Google depot_tools](#install-google-depot_tools)
    - [Configure git](#configure-git)
- [Get Chromium OS source code](#get-chromium-os-source-code)
    - [Create directory structure](#create-directory-structure)
    - [Fetch Chromium OS source code](#fetch-chromium-os-source-code)
    - [Request for Google API key](#request-for-google-api-key)
- [Setup Raspberry Pi overlay](#setup-raspberry-pi-overlay)
- [Build Chromium OS for Raspberry Pi](#build-chromium-os-for-raspberry-pi)
    - [Create the chroot](#create-the-chroot)
        - [Delete the chroot](#delete-the-chroot)
    - [Setup bind mount directories for chroot](#setup-bind-mount-directories-for-chroot)
    - [Enter the chroot](#enter-the-chroot)
    - [Set password for the chronos user](#set-password-for-the-chronos-user)
    - [Setup Raspberry Pi board](#setup-raspberry-pi-board)
        - [Re-initialize the board](#re-initialize-the-board)
    - [Build packages](#build-packages)
        - [When interrupted](#when-interrupted)
        - [Read the output](#read-the-output)
        - [Read the logs](#read-the-logs)
    - [Build the disk image](#build-the-disk-image)
        - [Find your image](#find-your-image)
- [Boot Raspberry Pi from the image](#boot-raspberry-pi-from-the-image)
    - [Write the disk image to a SD card](#write-the-disk-image-to-a-sd-card)
        - [Write the image by using the ```cros``` command](#write-the-image-by-using-the-cros-command)
    - [Boot from the SD card](#boot-from-the-sd-card)
- [More information](#more-information)
- [About us](#about-us)

<!-- /TOC -->

# Introduction
This document describes how to build and run Google Chromium OS on Raspberry Pi 3b, from its source code and the board overlay hosted in this repository.

This overlay and the document has been tested against Raspberry Pi 3b by the FydeOS team. It doesn't work on Pi 2.

## Change Logs

### Update to ChromiumOS R70
* The overlays is move to fit for ChromiumOS R70.
* Fix poor graphic performance (full hw accelecrate).
* Add firmware for RPI 3B+, patches kernel for brcm, but it still doesn't work (so sad).
* The image released is for testing usage, if you want more efficient, build packages with "cros_embedded" (or uncomment the USE flags in overlay-rpi3/make.conf) 
* Some things need explored by yourself

## About this repository
The code and document in this repository is the result of works by the people of the Flint team. We previously worked on this overlay internally and released a few disk images for Raspberry Pi to the public. Now we open this to the public.

### Branches in this repository
There was a big change regarding the graphics stack in Chrome OS. Before release 57, Xorg/X11 was used. Beginning from release 57, Chrome OS moved to the Freon graphics stack, which is a modern display system developed solely for Chrome OS by Google.

* master - this branch can be used to build a Chromium OS image with Freon as the graphics stack. It has been tested against release 68. You are welcome to test it with future releases and send feedback and/or PRs.

### Goal of this repository
* To provide a open source code base that everybody can use to build and improve Chromium OS for Raspberry Pi.
* To make as less change to the original Chromium OS code and process as possible, so that people can study and get used to the Chromium OS development process. We may provide scripts later to ease the process.

## Typography Conventions
Shell commands running in the host OS are prefixed with the ```$``` sign, like below.
```
$ cd /mydir
```

Shell commands running in the Chromium OS chroot environment are prefixed with ```(cr) $```, like below.
```
(cr) $ cd /mydir         # This is a comment for the command. It should not be included in your command.
```


# System requirement

* A x86_64 system to perform the build. 64-bit hardware and OS are must. The Chromium OS is a very large project, building from the source form scratch usually takes hours to over 10 or even 20 hours, depends on the system configuration.
  * CPU: we recommend using a 4-core or higher processor. The Chromium OS build process runs in parallel so more cores can help shorten build time dramatically.

  * Memory: we recommend at least 8GB, plus enough swap space. Linking Chrome(the browser) could require more than 8GB of memory, so you will run into massive swapping or OOM if you have less memory.

  * Disk: at least 100GB of free space, 200GB or more is recommended. SSD could noticeably shorten the build time as there are many gigabytes of files need to be written to and read from the disk.

  * Network: total source code downloading will be over 10GB. A fast and stable Internet access is going to be very helpful.

* A x86_64 Linux OS, it is called as the host OS later in this doc. The Chromium OS build process utilizes chroot to isolate the build environment from the host OS. So theoretically any modern Linux system should work. However, only limited Linux distros are tested by the Chromium OS team and the Fyde team. Linux versions that are known to work:

  * Ubuntu Linux 14.04 & 16.04
  * Gentoo Linux

* A non-root user account with sudo access. The build process should be run by this user, not the root user. The user need to have _sudo_ access. For simplicity and convenience password-less sudo could be set for this user.


# Prepare the system

## Install necessary tools
Git and curl as the essential tools need to installed in the host OS. Python 2.7 is required to run scripts from Google depot_tools package. Python 3 support is marked as experimental by these scripts, so use it at your own risk, feedback are welcome.

Follow the usual way to install them on your host OS.

## Install Google depot_tools
The depot_tools is a software package of scripts, provided by Google, to manage source code checkouts and code reviews. We need it to fetch the Chromium OS source code.

```
$ sudo mkdir -p /usr/local/repo
$ sudo chmod 777 /usr/local/repo
$ cd /usr/local/repo
$ git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
```

Then add depot_tools directory to PATH and setup proper umask for the user who is going to perform the build. Add below lines to the file ```~/.bash_profile``` of that user. Or if you are using a different shell, handle that accordingly.

```
export PATH=/usr/local/repo/depot_tools:$PATH
umask 022
```

Then re-login to make above changes take effective.

## Configure git
Better configure git now or it may complain in some operations later.

```
$ git config --global user.email "you@email.address"
$ git config --global user.name "Your Name"
```

# Get Chromium OS source code

## Create directory structure
The directory structure described here is a recommendation based on the best practice in the Fyde team. You may host the files in a different way as you wish.

```
$ mkdir -p /project/chromiumos-R68      # This is the directory to hold Chromium OS source code, name it according to the release you are going to build.
$ mkdir -p /project/overlays            # This is the directory to hold this repository.
```

If you are building a different release, make sure you use the actual directory name on your own system, the name here mentioned is just an example.

## Fetch Chromium OS source code

First you need to find out the reference name of the release you would like to build.

```
$ git ls-remote https://chromium.googlesource.com/a/chromiumos/manifest.git | grep release
```

You will see a list of Git commit IDs and its name in the form of ```refs/heads/release-Rxx-xxxx.B```. That ```release-Rxx-XXXX.B``` string is what you need for fetching the code of that specific Chromium OS release. For example, ```release-R56-9000.B``` for release 56.

Now run these commands to fetch the source code. Find and use a different release name if you would like to build a different release.

```
$ cd /project/chromiumos-R68
$ repo init -u https://chromium.googlesource.com/chromiumos/manifest.git --repo-url https://chromium.googlesource.com/external/repo.git -b stabilize-10718.88.B  # The last R68 stable release
$ repo sync -j8         # Raise this number if you have a fast Internet connection
```

Fetching of Chromium OS source code may take 10 to more than 30 minutes depends on your connection speed.

**Note: you need to use different branches of this overlay to build different Chromium OS releases. See above [Branches in this repository](#branches-in-this-repository) section for detail.**

## Request for Google API key
If you would like to login into the Chromium OS GUI by using your Google ID, you will need to request for Google API key and include them in the disk image you build. Since the only authentication mechanism included in Chromium OS is Google ID, you probably will need this or you will only be able to login as guest user.

Apply for Google API on Google website per [this document](http://www.chromium.org/developers/how-tos/api-keys). After acquired the client ID, client secret and API key, put then in ```~/.googleapikeys``` file as in below format.

```
'google_api_key': 'your api key',
'google_default_client_id': 'your client id',
'google_default_client_secret': 'your client secret',
```

Then the Chromium OS build script will read necessary information from this file automatically, and the image you build will allow Google ID login.

# Setup Raspberry Pi overlay
Now fetch this overlay and put it in the right place.

```
$ cd /project/overlays
$ git clone https://github.com/fydeos/chromium_os_for_raspberry_pi.git

$ cd /project/chromiumos-R68/src/overlays
$ ln -s /project/overlays/chromium_os_for_raspberry_pi/* .
```

# Build Chromium OS for Raspberry Pi

## Create the chroot
As mentioned above, a chroot environment will be used to run the actual build process and some other related tasks. To create the chroot environment, run below commands.

```
$ cd /project/chromiumos-R68
$ cros_sdk
```

It make take 10 to over 30 minutes depends on your Internet connection speed and disk speed. Once finished, it will enter into the chroot. The shell prompt string looks like below so it is very easy to tell whether you are currently in the chroot or not.

```
(cr) (stabilize-10718.88.B/(xxxxxx...)) <user>@<host> ~/trunk/src/scripts $
```

The chroot environment is located under the ```/project/chromiumos-R68/chroot``` directory.

Let's exit from the chroot first as we need to do some customization before move on. Type ```exit``` or ```Ctrl + D``` to exit from the chroot shell.

Usually the chroot only needs to be created once and can be used to build a board many times or build different boards. It very rarely need to be removed/re-created.

### Delete the chroot
If you would like to remove the chroot and re-create it from scratch, don't delete the ```chroot``` directory directly. As there could be directories from the host OS bind mounted in the chroot, a ```rm chroot``` command could actually remove files from your host OS undesirably.

The correct way to remove the chroot is by using below commands.

```
$ cd /project/chromiumos-R68
$ cros_sdk --delete
```

## Setup bind mount directories for chroot
Programs running inside the chroot will not be able to access files outside of the chroot. One way to circumvent this is to bind mount those files into a directory inside the chroot.

When entering the Chromium OS chroot environment, a file named ```.local_mounts``` will be checked and directories listed in it will be bind mounted inside the chroot. All we need to do is to create this file in the right place and put necessary contents in, by using below command.

```
$ echo "/project" > /project/chromiumos-R68/src/scripts/.local_mounts
```

Now, after entered the chroot, a ```/project``` directory will exist in the chroot and its content is the same as the ```/project``` directory in the host OS, as it actually is bind mounted from the host OS.

If we don't do this, the ```/project/chromiumos-R68/src/overlays/overlay-rpi3``` symbolic link will not be accessible, as the top directory (```/project```) it points to doesn't exist in the chroot.

## Enter the chroot
Now we can enter the chroot.

```
$ cd /project/chromiumos-R68
$ cros_sdk
```

It is the same command used to create the chroot. It creates the chroot if one does not exist, and enters the chroot if there is already one.

And we can check whether above ```.local_mounts``` setup was done correctly. Notice that the ```(cr) $``` prefix denotes these commands should be run in the chroot.

```
(cr) $ ls /project                      # You should be able to see the same content as in host OS.
(cr) $ ls ../overlays/overlay-rpi3/      # You should be able to see the content of this repo.
```

Move on if it works well. If not, check and make sure you set up ```.local_mounts``` correctly.

## Set password for the chronos user
The chronos user is used to log into the command line interface of Chromium OS, via SSH, local console or the shell in crosh interface. It is recommended that a password is set for this user so you can login as this user and also can do ```sudo``` in the Chromium OS command line, for advanced tasks.

To set password for chronos user, run below command.

```
(cr) $ ./set_shared_user_password.sh
```

Type in a password when been prompted. If you would like to change the password, simply run the command again.

The password is encrypted and saved in the file ```/etc/shared_user_passwd.txt``` in the chroot. You only need to set it once and it will be used for all the images you build, unless you re-create the chroot.

## Setup Raspberry Pi board
In the Chromium OS terminology, a board refers to a class of computer platform with distinct hardware configurations. The board will be used as a target in the process of building software packages and disk image for that specific computer platform.

There are many boards exist in the Chromium OS code base. They are either development platforms or real selling products running Chrome OS, such as Chromebooks you can buy from many vendors.

The Chromium OS project utilizes the Portage package management system from Gentoo Linux. Each board lives in its own "overlay", which holds distinct build configuration, system configurations, collection of software packages, system services, disk image customization etc. for that board.

In our case here, we created a board named "rpi" and it refers to the Raspberry Pi computer. And we call the overlay "overlay-rpi" or "rpi", all its files are hosted in this repository.

To build Chromium OS for a board, the first thing is to initialize the board from its overlay.

```
(cr) $ ./setup_board --board=rpi3
```

Again, it may take 10 to over 30 minutes depends on the speed of your Internet connection and disk I/O.

After it's done, a directory structure for the "rpi" board will be created under ```/build/rpi3``` of the chroot.

### Re-initialize the board
It is usually not necessary to re-initialize the board as what you have already built will be lost, and you will have to spend hours to rebuild all packages from scratch. But if you really need to do so, just re-run the same setup_board command with the ```---force``` option.

```
(cr) $ ./setup_board --board=rpi3 --force
```

The ```--force``` option will remove the existing board directory ```/build/rpi3``` and re-create it from scratch.

## Build packages
Now it time to build all software packages for the rpi board.

```
(cr) $ ./build_packages --board=rpi3 # Append "--nowithautotest" to speed up the build process 
```

It may take hours depends on your processor power, your memory size, your disk speed and your Internet bandwidth. On a decent machine with 4 cores 8 threads, 16GB memory, files on regular HDD, and 100Mb broadband, it takes about 5 to 6 hours for the command to finish.

### When interrupted
The build process is incremental. If it gets interrupted for any reason, you can always rerun the same ```build_packages``` command and it will resume the build instead of rebuild from scratch.

### Read the output
The ```build_packages``` command throw out a lot of information on the console. Fortunately those information are very well organized.

* Red text: these are error messages and very likely will cause the build process to break.
* Green text: these are useful messages printed by the build script itself. They are useful when debugging problem.
* White text: these are regular information that mostly are printed by the commands called in the build script. They provide more details about the build process thus are also useful for debugging.

### Read the logs
Most time the ```build_packages``` command spends on is running the ```emerge``` commands, to build, install and pack those hundreds of software packages required by the overlay. The ```emerge``` command is from the portage system of Gentoo Linux.

The ```emerge``` command saves the output of its building, installation and packing process into log files. These files are extremely useful if there is failure when building some package. Those log files are located under the ```/build/rpi/tmp/portage/logs``` directory of the chroot. They are plain text files so can be viewed by tools like ```less```, or ```more```, or editors such as ```vim```.


## Build the disk image
After the build_packages command finished successfully, you can start building the disk image.

```
(cr) $ ./build_image --board=rpi3 --noenable_rootfs_verification
```

It may take 10 to 30 minutes, mainly depends on the speed of your disk. It is much faster on SSD than on HDD.

### Find your image
After the command finished successfully, you will have disk images generated, saved under ```/mnt/host/source/src/build/images/rpi/``` directory in the chroot, or ```/project/chromiumos-R56/src/build/images/rpi``` in the host OS. These two are the same directory, just bind mounted in the chroot.

Each invoke of the build_image command will create a directory named similar to ```R56-9000.104.<date time>-a1``` under above directory. There is a symlink named ```latest``` under above directory, that always point to the image directory of the last successful build.

The disk image is usually named ```chromiumos_image.bin```, under abovementioned directory. So full path to the latest image is

```
/mnt/host/source/src/build/images/rpi3/latest/chromiumos_image.bin
```

in the chroot, and

```
/project/chromiumos-R56/src/build/images/rpi3/latest/chromiumos_image.bin
```
in the host OS.


# Boot Raspberry Pi from the image
The Raspberry Pi boots from the SD card so we need to write the previously generated disk image on to the SD card. A SD card of at least 8GB capacity is required.

## Write the disk image to a SD card
There are two usual ways to write the Chromium OS disk image to a SD card. You can copy the image out to another Window/Mac/Linux system and write it using your favorite GUI/CLI application. It is the same as writing other Linux images for Raspberry Pi, so will not be explained here.

Another Chromium OS specific way is by using the ```cros``` command in the chroot.

### Write the image by using the ```cros``` command
First plug the SD card into the box used to build the image and has the chroot. Then run below command.

```
(cr) $ cros flash usb:// rpi3/latest
```

This asks to write the latest disk image to USB removable media. A list of USB removable media will be presented, with index number prefixed. You can select which USB drive to write to by type in the index number when prompted.

## Boot from the SD card
After the disk image is successfully written to the SD card, plug it into the Raspberry Pi and boot it as usual. After a few seconds you will see a Chromium logo, later on it will boot into GUI mode and the first time setup screen will pop up for you to configure the system and login.

# More information
[Chromium OS Developer Guide](http://www.chromium.org/chromium-os/developer-guide). This is the official source of how to build Chromium OS

[The FydeOS website, English site](https://fydeos.io), our home :)

[The FydeOS website, Chinese site](https://fydeos.com), our home, in Chinese.


# About us
Fyde began with a vision where all applications and services we use today will be living in the Cloud. We believed that with the ever advancing browser platform technology and web frontend performances, it’s not surprising that most things we do today with the internet can be done through a single browser window. We are stepping into an era where installable apps will soon become history. FydeOS is our answer to this new era for computing.

FydeOS is a simple, secure, fast and productive operating system. Based on the open-source Chromium Project that also powers the well-known Google Chromebooks. FydeOS inherits most of the benefits that Chromebooks have but also bundled with our enhancements and new features. We have turned FydeOS into a more open platform, users will no longer be forced to rely on Google services and have the freedom to choose whichever services they prefer. We have also made FydeOS run on a wider range of hardware platforms ranging from x86 PCs and ARM based single board computers, providing endless of possibilities and potentials of how FydeOS can be used and applied.
