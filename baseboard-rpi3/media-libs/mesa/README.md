# ChromeOS freedreno development

[TOC]

## Ebuild workflow

The ebuild for `mesa-freedreno` uses a downstream branch called
`chromeos-freedreno`, which the `repo` tool will checkout under
`src/third_party/mesa-freedreno`. The ebuild is a `cros_workon` ebuild
and builds off of the `mesa-freedreno` repo. Rebasing to newer
upstream is done by merging in a more recent upstream master.
Downstream changes are committed directly to the branch, using the
kernel repo convention for commit message prefixes.

### Rebasing to new upstream

Rebasing the `mesa-freedreno` package is done by merging the upstream
`master` branch into `chromeos-freedreno`.  The ChromeOS mesa repo
tracks upstream mesa master as `cros/master`, but it's also possible
to just add a remote for the upstream repo to the `mesa-freedreno`
repo.

Even if the merge could fast-forward, always create a merge commit so
that we can push it to gerrit. As it is, `chromeos-freedreno` is
already diverged form upstream master, and so `git merge` will always
create a merge commit.

```bash
$ git merge --no-ff cros/master
```

Then push to gerrit:

```base
$ git push cros HEAD:refs/for/chromeos-freedreno
```

which should result in a merge CL like http://crrev.com/c/1692972

### Downstream changes

Downstream changes should be kept to a minimum. To fix a bug or
regression, ideally we fix the issue upstream, then rebase
`chromeos-freedreno` to a master commit with the fix in
question. Then, if required, cherry-pick the patch back to a chromeos
release branch of the `chromeos-freedreno` branch (for example
`release-R76-12239.B-chromeos-freedreno`).

Downstream commits follow the convention of
https://chromium.googlesource.com/chromiumos/docs/+/HEAD/kernel_development.md,
in particular, using the `CHROMIUM:`, `FROMLIST:` etc commit message
prefixes to highlight that a commit is downstream and identify the
type of downstream commit.

```bash
$ git cherry-pick $HASH
```

Edit commit message, add `TEST=` and `BUG=` fields, prefix commit
message with `UPSTREAM:` or other appropriate label, then

```bash
$ git push cros HEAD:refs/for/release-R76-12239.B-chromeos-freedreno
```

Ultimately, there may be cases were we have to carry a downstream
modification that can't go upstream for some reason, in which case we
will have to commit the change to `chromeos-freedreno`.  Implement
downstream modification, commit with `CHROMIUM:` prefix and push to
gerrit as:

```bash
$ git push cros HEAD:refs/for/chromeos-freedreno
```

Result should be a CL something like http://crrev.com/c/1693031.

### Viewing downstream delta

One downside to the `chromeos-freedreno` branch workflow is that it
can be difficult to see the amount of changes we have
downstream. There are a few git commands that can help visualize
that. To get a list of commits that are only downstream use:

```bash
$ git log HEAD ^cros/master --oneline
8abe41b2fdd (HEAD) Merge remote-tracking branch 'cros/master' into HEAD
da35bf4b1d8 UPSTREAM: nir/lower_io_to_temporaries: Fix hash table leak
10721ef0b38 (m/master, cros/chromeos-freedreno) mesa-freedreno: Add OWNERS file
```

and to show the total diff between upstream and downstream use:

```bash
$ git diff cros/master...HEAD
diff --git a/OWNERS b/OWNERS
new file mode 100644
index 00000000000..b0ead24fa9d
--- /dev/null
+++ b/OWNERS
@@ -0,0 +1,4 @@
+astrachan@google.com
+basni@chromium.org
+chadversary@chromium.org
+cstout@chromium.org
diff --git a/src/compiler/nir/nir_lower_io_to_temporaries.c b/src/compiler/nir/nir_lower_io_to_temporaries.c
index c865c7de10c..f92489b9d51 100644
--- a/src/compiler/nir/nir_lower_io_to_temporaries.c
+++ b/src/compiler/nir/nir_lower_io_to_temporaries.c
@@ -364,4 +364,6 @@ nir_lower_io_to_temporaries(nir_shader *shader, nir_function_impl *entrypoint,
    exec_list_append(&shader->globals, &state.old_outputs);

    nir_fixup_deref_modes(shader);
+
+   _mesa_hash_table_destroy(state.input_map, NULL);
 }
```

Notice the triple-dot syntax `cros/master...HEAD`, shows the diff
between `cros/master` as of when it was most recently merged into HEAD
and current HEAD.

## Upstream Development

This section documents a few workflows useful for developing upstream
freedreno within the chromeos infrastructure.

### Set up `.local_mounts`

The `cros_sdk` tool can bind mount a directory from the host
filesystem into the SDK chroot. This is useful when editing source
code outside the SDK and compiling it inside. Edit
`src/scripts/.local_mounts` to something like:

```bash
/usr/local/google/home/hoegsberg/workspace /home/hoegsberg/workspace
```

to map the directory `workspace` from your host home directory to the
home directory in the SDK.

### Clone upstream mesa

With the shared workspace set up, clone mesa into it:

```bash
$ cd ~/workspace
$ git clone https://gitlab.freedesktop.org/mesa/mesa.git
```

### Configure

In the mesa repository, create the file `meson.armv7a-cros-linux-gnueabihf` with this content:

```ini
[binaries]
ar = ['armv7a-cros-linux-gnueabihf-ar']
c = ['armv7a-cros-linux-gnueabihf-clang']
cpp = ['armv7a-cros-linux-gnueabihf-clang++']
fortran = ['gfortran']
llvm-config = 'llvm-config'
objc = ['cc']
objcpp = ['armv7a-cros-linux-gnueabihf-c++']
pkgconfig = '/build/cheza-freedreno/build/bin/pkg-config'
strip = ['armv7a-cros-linux-gnueabihf-strip']

[properties]
c_args = ['-O2', '-pipe', '-march=armv8-a+crc', '-mtune=cortex-a57.cortex-a53', '-mfpu=crypto-neon-fp-armv8', '-mfloat-abi=hard', '-g', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-UENABLE_SHADER_CACHE']
c_link_args = ['-O2', '-pipe', '-march=armv8-a+crc', '-mtune=cortex-a57.cortex-a53', '-mfpu=crypto-neon-fp-armv8', '-mfloat-abi=hard', '-g', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-Wl,-O2', '-Wl,--as-needed']
cpp_args = ['-O2', '-pipe', '-march=armv8-a+crc', '-mtune=cortex-a57.cortex-a53', '-mfpu=crypto-neon-fp-armv8', '-mfloat-abi=hard', '-g', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-std=gnu++11', '-UENABLE_SHADER_CACHE']
cpp_link_args = ['-O2', '-pipe', '-march=armv8-a+crc', '-mtune=cortex-a57.cortex-a53', '-mfpu=crypto-neon-fp-armv8', '-mfloat-abi=hard', '-g', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-std=gnu++11', '-Wl,-O2', '-Wl,--as-needed']
fortran_args = ['-O2']
fortran_link_args = ['-O2', '-Wl,-O2', '-Wl,--as-needed']
objc_args = ['-UENABLE_SHADER_CACHE']
objc_link_args = ['-Wl,-O2', '-Wl,--as-needed']
objcpp_args = ['-UENABLE_SHADER_CACHE']
objcpp_link_args = ['-Wl,-O2', '-Wl,--as-needed']

[host_machine]
system = 'linux'
cpu_family = 'arm'
cpu = 'armv7a'
endian = 'little'
```

This is a snapshot from the meson cross file generated by
`emerge-cheza-freedreno` and may get out of date as the ChromeOS
toolchain and build settings change over time. When building mesa with
emerge, the cross file can be found in
`/build/cheza-freedreno/tmp/portage/media-libs/mesa-freedreno-9999/temp/meson.armv7a-cros-linux-gnueabihf.arm`.

Then configure mesa for cross compiling the main ChromeOS GLES and
Vulkan drivers using:

```bash
$ meson --buildtype debug --wrap-mode nodownload --cross-file meson.armv7a-cros-linux-gnueabihf \
    -Dllvm=false -Ddri3=false -Dglx=disabled -Degl=true -Dgbm=false -Dgles1=false -Dgles2=true \
	-Dshared-glapi=true -Ddri-drivers= -Dgallium-drivers=freedreno -Dgallium-vdpau=false \
	-Dgallium-xa=false -Dplatforms=surfaceless -Dvulkan-drivers=freedreno -DI-love-half-baked-turnips=true . build-debug
```

### Building

Now we should be ready to compile mesa using `ninja`:

```bash
$ SYSROOT=/build/cheza-freedreno ninja -C build-debug
```

To compile mesa from outside the SDK (for example, from an editor or
IDE), this script (`fast-sdk.sh`) enters an active SDK and runs the
given command:

```bash
#!/bin/sh

set -x -e -u
set -o pipefail

board=cheza-freedreno
cros_sdk_pid=$(pgrep -f 'python2 /work/chromiumos/chromite/bin/cros_sdk' -n)
if [ -d /build/${board} ]; then
   echo Already in SDK
   SYSROOT=/build/${board} exec "$@"
else
   exec sudo nsenter -a -t $cros_sdk_pid chroot /work/chromiumos/chroot \
      sudo -u ${USER} -i SYSROOT=/build/${board} "$@"  |
      sed -e "s#/home/${USER}#${HOME}#g" 2>&1
fi
```

which can then be used to compile mesa from outside the SDK like so:

```bash
$ ./fast_sdk.sh ninja -C /home/hoegsberg/workspace/mesa-work/build-debug
```

### Deploy to target

This script will rsync the built driver and libraries to a device. It
unconditionally overwrites whatever other driver currently on the
device, so use with caution.

```bash
#!/bin/bash

set -e

dir=$(readlink -f $1)
shift

DESTDIR=$dir/build-debug/install ninja -C $dir install

files=$dir/install/usr/local/lib*.so*
driver=$dir/install/usr/local/lib/dri/msm_dri.so

for host in "$@"; do
    echo deploy to host $host
    ssh -n $host "mount -o rw,remount /" &&
    rsync -a --info=name2 $files $host:/usr/lib &&
    rsync -a --info=name2 $driver $host:/usr/lib/dri/msm_dri.so &
done

wait
```

Another approach is to copy the libraries and DRI driver to a `/tmp`
subdirectory and set up `LD_LIBRARY_PATH` and `LIBGL_DRIVERS_PATH` to
point to that location.
