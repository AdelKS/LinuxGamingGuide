# A linux gaming guide

This is some kind of guide/compilation of things, that I got to do/learn about while on my journey of gaming on linux. I am putting it here so it can be useful to others! If you want to see something added here, or to correct something where I am wrong, you are welcome to open an issue or a PR ! 

## Table of Content

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [A linux gaming guide](#a-linux-gaming-guide)
  - [Table of Content](#table-of-content)
  - [Linux distribution](#linux-distribution)
  - [Lutris](#lutris)
  - [Self-compiling](#self-compiling)
    - [Flags to try](#flags-to-try)
  - [DXVK](#dxvk)
    - [Custom compile flags](#custom-compile-flags)
  - [GPU](#gpu)
    - [Nvidia](#nvidia)
    - [AMD](#amd)
      - [RADV](#radv)
        - [Self-compile](#self-compile)
  - [Kernel](#kernel)
    - [Command line options](#command-line-options)
    - [Custom/self compiled kernels](#customself-compiled-kernels)
      - [Threading synchronisation](#threading-synchronisation)
    - [Game mode](#game-mode)
    - [AMD Ryzen: the `cpuset` trick](#amd-ryzen-the-cpuset-trick)
      - [A small intro to CPU cache](#a-small-intro-to-cpu-cache)
      - [What can we do with this information ?](#what-can-we-do-with-this-information)
      - [Using `cpuset`](#using-cpuset)
      - [Benchmark](#benchmark)
  - [Wine](#wine)
      - [Environment variables](#environment-variables)
    - [wine-tkg](#wine-tkg)
      - [Esync (+ Fsync (+ Futex2))](#esync-fsync-futex2)
      - [Fastsync](#fastsync)
      - [compiler optimisations](#compiler-optimisations)
  - [Overclocking](#overclocking)
    - [CPU and GPU](#cpu-and-gpu)
    - [RAM](#ram)
  - [X11/Wayland](#x11wayland)
  - [Performance overlays](#performance-overlays)
  - [Streaming - Saving replays](#streaming-saving-replays)
    - [OBS](#obs)
      - [Using `cpuset` with software encoder on Ryzen CPUs](#using-cpuset-with-software-encoder-on-ryzen-cpus)
      - [Gnome](#gnome)
      - [obs-vkcapture](#obs-vkcapture)
    - [Replay sorcery](#replay-sorcery)
    - [Stream only the game sounds](#stream-only-the-game-sounds)
  - [Sound improvements with PulseAudio](#sound-improvements-with-pulseaudio)
    - [Improve the sound of your headset](#improve-the-sound-of-your-headset)
      - [The Graphical way](#the-graphical-way)
    - [Mic noise suppression](#mic-noise-suppression)
      - [The Graphical way](#the-graphical-way-1)
      - [The command line way](#the-command-line-way)
  - [Game render tweaks: vkBasalt](#game-render-tweaks-vkbasalt)
  - [Compositor / desktop effects](#compositor-desktop-effects)
  - [Benchmarks](#benchmarks)
  - [Misc](#misc)

<!-- /code_chunk_output -->


## Linux distribution

I have seen many reddit posts asking which linux distributions is "best" for gaming. My thoughts on the matter is that, to get the best performance, one simply needs the latest updates. All linux distributions provide the sames packages and provide updates. Some provide them faster than others. So any distribution that updates its packages the soonest after upstream (aka the original developpers), is good in my opinion. Some distributions can take longer, sometimes 6 months after, for big projects (which is acceptable too, since one would get the updates without the initial bugs).

## Lutris

Lutris is some kind of open source Steam that helps with installing and running some games. Each game has its own install script, maintained by usually different people (as far as I understand).
I have only used Lutris, to install and run Overwatch, I don't think there's room for improvement in here since Lutris is just here to run overwatch with a chosen Wine version and environment variables. Correct me if I am wrong.

Some useful settings:
* Enable FSYNC (if you have a patched custom kernel, further information below) otherwise enable ESYNC: once overwatch is installed, go to "Configure" > "Runner Options" > Toggle FSYNC or ESYNC.


## Self-compiling

Compiling is the process of tranforming human written code (like C/C++/Rust/... etc) to machine runnable programs (the `.exe` files on Windows, on Linux they usually have no extension :P). Compiling is actually done by a program, a compiler, on linux it's `gcc` or `clang`. There is not a unique way to translate/compile code to machine runnable programs, the compiler has lots of freedom on how to implement that, and we can influence them by telling them to try "harder" to optimize the machine code, by giving them the so called "flags": a set of command line options given to the compiler, an example is
```shell
gcc main.c -O2 -march=native -pipe
```
where `-O2`, `-march=native` and `-pipe` are compiler flags. There are many flags that compilers accept, the ones specific to optimisation are given in [GCC's documentation](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html). A few important (meta)flags
- The `-Ox`, where `x=1,2,3`, is a generic flag that sets the generic level optimization, it activates many other flags that actually do something. Distros that compile their software usually with `-O2`
- The `-march` flag is a flag that tells the compiler to use additionnal features that aren't available for all CPUs: newer CPU implement some "instruction sets" (aka addiotionnal features) that enable them to perform some operations faster, like [SIMD instructions](https://en.wikipedia.org/wiki/SIMD). It makes some programs faster, like `ffmpeg` with video conversion. This instruction is not used by default with Distro packages as they need to have their programs able to run on all machine, even those from 2001. So one can win a lot just by compiling with `-march=native` in computationnal heavy programs. Although some programs have embedded detection code to use addtionnal features of your CPU. Some Linux Distributions like [Gentoo](https://www.gentoo.org/) enable you to compile every single package on your own machine so you can have ALL the apps built with `-march=native` (it may take several hours given your CPU)
- Link Time Optimizations (LTO) that involve the use of the flags `-flto`, `-fdevirtualize-at-ltrans` and `-flto-partition`
- Profile Guided Optimizations (PGO) that involve the use of `-fprofile-generate=/path/to/stats/folder`, `-fprofile-use=/path/to/stats/folder` flags. The idea behind is to produce a first version of the program, with performance counters added in with the `-fprofile-generate=/path/to/stats/folder` flag. Then you use the compiled program in your real life use-cases (it will be way slower than usual), the program meanwhile fills up some extra files with useful statistics in `/path/to/stats/folder`. Then you compile again your program with the `-fprofile-use=/path/to/stats/folder` flag with the folder `/path/to/stats/folder` filed with statistics files that have the `.gcda` extension.

A nice introduction to compiler optimizations `-Ox`, `LTO` and `PGO`, is made in a Suse Documentation that you can find here: https://documentation.suse.com/sbp/all/html/SBP-GCC-10/index.html

The Kernel, `Wine`, `RADV` and `DXVK` can be compiled on your own machine so you can use additional compile flags (up to a certain level) for the particular CPU you own and potentially faster with more "agressive" compiler flags. I said potentially as you need to check for yourself if it is truly the case or not.

### Flags to try

Here is a group of flags can use when building your own programs
```shell
BASE="-march=native -O3 -pipe"
GRAPHITE="-fgraphite-identity -floop-strip-mine"
MISC="-floop-nest-optimize -fno-semantic-interposition -fipa-pta"
LTO3="-flto -fdevirtualize-at-ltrans -flto-partition=one"
LTO2="-flto -fdevirtualize-at-ltrans -flto-partition=balanced"
LTO1="-flto -fdevirtualize-at-ltrans -flto-partition=1to1"
```
It is recommended to try them in this order, if one doesn't work (for whatever reasons: fails to compile or doesn't work), you try the next one:
1. `BASE + GRAPHITE + MISC + LTO3`:
  ```
  -march=native -O3 -pipe -fgraphite-identity -floop-strip-mine -floop-nest-optimize -fno-semantic-interposition -fipa-pta -flto -fdevirtualize-at-ltrans -flto-partition=one
  ```
2. `BASE + GRAPHITE + MISC + LTO2`:
  ```
  -march=native -O3 -pipe -fgraphite-identity -floop-strip-mine -floop-nest-optimize -fno-semantic-interposition -fipa-pta -flto -fdevirtualize-at-ltrans -flto-partition=balanced
  ```
3. `BASE + GRAPHITE + MISC + LTO1`:
  ```
  -march=native -O3 -pipe -fgraphite-identity -floop-strip-mine -floop-nest-optimize -fno-semantic-interposition -fipa-pta -flto -fdevirtualize-at-ltrans -flto-partition=1to1
  ```
4. `BASE + GRAPHITE + MISC`
  ```
  -march=native -O3 -pipe -fgraphite-identity -floop-strip-mine -floop-nest-optimize -fno-semantic-interposition -fipa-pta
  ```
5. `BASE + GRAPHITE`
  ```
  -march=native -O3 -pipe -fgraphite-identity -floop-strip-mine
  ```
6. `BASE`
  ```
  -march=native -O3 -pipe
  ```


## DXVK

This is the library that maps DirectX (Windows) to Vulkan (Multi-platform and open source) so games that are meant for Windows work on Linux. It's better than wine's built-in mapper called WineD3D. Lutris provides a version already. 

You can compile your own latest one with some "better" compiler optimizations if you wish, and that's what I am doing but I have no idea about the possible FPS benefits of doing that. To do so you will need to put what DXVK's compile script gives you in `~/.local/share/lutris/runtime/dxvk/`. Link here: https://github.com/doitsujin/dxvk

```shell
git clone https://github.com/doitsujin/dxvk.git
cd dxvk
# Build new DLLS
./package-release.sh master ~/.local/share/lutris/runtime/dxvk/ --no-package
```

### Custom compile flags

DXVK can be compiled with [user provided compile flags](#self-compiling). For that, you edit `build-win32.txt` and `build-win64.txt` and change the following before running the `./package-release.sh` script:
```shell
[built-in options]
c_args=[... TO BE FILLED ...]
cpp_args=[... TO BE FILLED ...]
c_link_args = ['-static', '-static-libgcc', ... TO BE FILLED ...]
cpp_link_args = ['-static', '-static-libgcc', '-static-libstdc++', ... TO BE FILLED ...]
```
Where you can replace `... TO BE FILLED ...` with `BASE + GRAPHITE + MISC + LTO2` flags [defined here](#flags-to-try), although you need to respect the syntax of this file: flags are quoted and separated with comas _e.g._ `c_args=['-O2', '-march=native']`.

You can also enable [PGO](#self-compiling) by appending `-fprofile-generate` or `-fprofile-use`, depending on the stage you are in, to `c_args` and `cpp_args`. You also need to add `'-lgcov'` to `c_link_args` and `cpp_link_args`

These flag changes may improve performance or not, the best is to test with and without and see for oneself. If regressions happen or it doesn' want to compile you can try [other flags](#flags-to-try).

## GPU

1. Update to the latest possible driver for your GPU
2. If you are hesitating between AMD and Nvidia for your next GPU buy. As far as Linux is concerned: AMD all the way, because they are way more supported since they give out an open source driver.

### Nvidia

The least one can do is redirect to Arch's documentation about it: https://wiki.archlinux.org/index.php/NVIDIA

If you didn't install the proprietary driver your computer is likely to be running an open source driver called `nouveau`, but you wouldn't want that to play games with that as it works based off reverse engineering and doesn't offer much performance.

Once you have the proprietary driver installed, open `nvidia-settings`, make sure you have set your main monitor to its maximum refresh rate and have 'Force Full Composition Pipeline' disabled (advanced settings).

Also, in Lutris, you can disable the size limit of the NVidia shader cache by adding `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1` to the environement variables.

### AMD
A nice documentation is given by, once again, Arch's documentation: https://wiki.archlinux.org/index.php/AMDGPU

* "Very old" GPUs: the opensource driver is `radeon` and you only have that as an option, along with AMD's closed source driver I believe. But you are out of luck for running DXVK, since both driver's don't implement Vulkan.
* "Old" GPUs: GCN1 and GCN2 are now supported by the newer "amdgpu" driver and you switch to it to win a few frames.
* New GPUs: the base driver is `amdgpu`, and is shipped and updated with the linux Kernel, stacks on top of it three different drivers: 
  * Mesa: the open source graphics stack that handles AMD, Intel, Qualcomm ...etc GPUs. The AMD OpenGL driver is called RadeonSI Gallium3D and is the best you can get. The Vulkan driver is called RADV
  * amdvlk: AMD's official open source Vulkan-only driver, I suppose the rest (OpenGL) is left to mesa. link here: https://github.com/GPUOpen-Drivers/AMDVLK
  * amdgpu PRO: AMD's official closed source driver, that has its own Vulkan and OpenGL implementation. 

#### RADV

If you are running RADV and with a mesa version prior to 20.2, you should consider trying out ACO as it makes shader compilation (which happens on the CPU) way faster : go to "Configure" > "System Options" > Toggle ACO.

Your distro ships the latest stable version, you can go more bleeding edge to get the latest additions, but keep in mind that regressions often come with it. On Ubuntu there's a [PPA](https://launchpad.net/~oibaf/+archive/ubuntu/graphics-drivers) that gives out the latest mesa, and another [PPA](https://launchpad.net/~kisak/+archive/ubuntu/kisak-mesa) that's less bleeding edge/more stable . 

##### Self-compile

You can compile only RADV by hand with the extra bonus of using your own compiler optimizations [as described in this section](#self-compiling) and use it for any Vulkan game, in a per game basis.

First, you get the source code
```shell
git clone --depth=1 https://gitlab.freedesktop.org/mesa/mesa.git
```
This command will create a `mesa` folder. To compile only RADV, you go into the sources folder and do the following
```shell
cd path/to/mesa
git clean -fdx
mkdir build && cd build
export CFLAGS="... [To be Filled] ..."
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,now ${CFLAGS}"
meson .. \
    -D prefix="$HOME/radv-master" \
    --libdir="$HOME/radv-master/lib" \
    -D b_ndebug=true \
    -D b_lto=TO BE CHANGED \
    -D b_pgo=TO BE CHANGED \
    -D buildtype=release \
    -D platforms=x11,wayland \
    -D dri-drivers= \
    -D gallium-drivers= \
    -D vulkan-drivers=amd \
    -D gles1=disabled \
    -D gles2=disabled \
    -D opengl=false
meson configure
ninja install
```
Where you need to fill a a few lines
- `CFLAGS` with flags, you can use `BASE + GRAPHITE + MISC + LTO3` from the [flags to try section](#flags-to-try).
- If you enabled the `LTO` flags you must set `-D b_lto=true`, otherwise `-D b_lto=true`
- With regards to PGO, first read [the bullet point about PGO](#self-compiling) 
  1. Profile generation
      - you must set `-D b_pgo=generate`
      - append `-fprofile-generate=$HOME/radv-pgo-data` to `CFLAGS`, where you can replace `$HOME/radv-pgo-data` to a folder of your liking
  2. Profile use
      - you must set `-D b_pgo=use`
      - append `-fprofile-use=$HOME/radv-pgo-data` to `CFLAGS`, where you replace `$HOME/radv-pgo-data` to the same folder you used for profile generation
  3. No PGO, you must set `-D b_pgo=off`

These may improve performance or not, the best is to test with and without and see for oneself. If regressions happen, follow the steps in [flags to try section](#flags-to-try) to reduce the number of flags.

After running the lines above, you get the driver installed in `$HOME/radv-master`, you can change the folder name and where it is in the line `-D prefix="$HOME/radv-master"`. Now, to use it for Overwatch (or any other game), you must set the following environment variable (in Lutris, it's in "Configure" > "System Options" > Environment variables, and add it):
```shell
VK_ICD_FILENAMES=$HOME/radv-master/share/vulkan/icd.d/radeon_icd.x86_64.json:$OTHER_PATH/radeon_icd.i686.json
```
where you should manually replace `$HOME` by your home path `/home/Joe` and `$OTHER_PATH` by where `radeon_icd.i686.json` actually is, you can find out with
```
sudo updatedb
locate radeon_icd.i686.json
```
If the games crashes after doing all this, you can either try other git commits (you will need some git knowledge) or revert to the stable driver by simply removing the `VK_ICD_FILENAMES` environment variable. And if you don't wanna hear about bleeding edge mesa anymore you can simply remove the `mesa` source folder along with `$HOME/radv-master`.

## Kernel

First, try to get the latest kernel your distro ships, it often comes with performance improvements (it contains the base updates for the amd gpu driver for example).

### Command line options

As you may know, the kernel has various protection mechanisms from malicious program-execution based attacks, the likes of [Spectre and Meltdown](https://en.wikipedia.org/wiki/Meltdown_(security_vulnerability)). These protections/mitigations come with [an extra overhead on the CPU](https://www.phoronix.com/scan.php?page=article&item=3-years-specmelt&num=9). (Un)fortunately, it is possible to disable ALL these mitigations, at the expense of security. Although if you use X11 then you are just adding an extra cherry on top of how unsecure your setup is haha. Since any running application can catch your keyboard and what's displayed on your monitor.

Okay, how to disable all mitigations ? Fortunately it's super simple: add `mitigations=off` command line to your [kernel parameters](https://wiki.archlinux.org/index.php/Kernel_parameters).

I ran accross another protection that got added in the kernel that disables a certain set of cpu instructions from user space programs (`umip`), instructions from this set is used for example in Overwatch some other games. That protection broke those games then the kernel got [a patch that emulates those instructions](https://github.com/torvalds/linux/commit/1e5db223696afa55e6a038fac638f759e1fdcc01) with a certain overhead with a kernel message like this one:
```shell
kernel: umip: Overwatch.exe[5970] ip:140621a9a sp:21dea0: For now, expensive software emulation returns the result.
```
You can disable this protection with the following kernel parameter `clearcpuid=514`
### Custom/self compiled kernels

Using a self-compiled kernel can bring some improvements. There is a git repository called [linux-tkg](https://github.com/Frogging-Family/linux-tkg) that provides a script to compile the linux Kernel from source (takes about ~30mins, but can be stripped down with `modprobed-db`) with some customization options : the default [scheduler](https://en.wikipedia.org/wiki/Scheduling_(computing)) ([CFS](https://en.wikipedia.org/wiki/Completely_Fair_Scheduler)) can be changed to other ones (Project C UPDS, PDS, BMQ, MuQSS)  These changes help getting better performance in games. And also other patches. Linux-tkg needs to be compiled on your own machine, where you can use compiler optimisations such as `-O3` and `-march=native` (LTO is experimental and Clang only, PGO will come soon), with an interactive script and a config file, I worked on the script to install on Ubuntu and Fedora.

More information here: https://github.com/Frogging-Family/linux-tkg

#### Threading synchronisation

`linux-tkg` offers patches that makes the kernel better mimick Windows' behavior with threads. And therefore get better performance for games ment to run on Windows: `winesync/fastsync`, `futex2`, `fsync`, `esync`.

`esync` and `fsync` have been developped by CodeWeavers and Collabora. `futex2` is a new backend for `fsync`, and is not a different mechanism per se, the other one being the current `futex` implementation + a patch that adds the `FUTEX_WAIT_MULTIPLE` operation. They are mutualy exclusive, so only one is used at time. To have them in `linux-tkg`, one must manually enable them in the `customization.cfg` or select them in the interactive script (`esync` is by default in any linux kernel since is based in an mainline feature called `eventfd`).

`winesync/fastsync` is a new proposal of syncronization subystem, similar to `futex` and `eventfd`, aimed to serve exclusively for mapping Windows API sync mechanisms. Developped by wine developpers. It seems that this is the implementation that will replace the previous ones (and eventually get included in the kernel by default, no need to patch). `winesync` is a kernel module that communicates with `fastsync` that should be in a patched wine (like `wine-tkg`). The performance should be similar or better than `futex2`. To have the `winesync` module:
- The DKMS route
  - Archlinux: you need to install the following packagse from the AUR: `winesync`, `winesync`, `winesync-header` and `winesync-udev-rule`
  - other distros: follow the [README in this repository](https://github.com/Cat-Lady/winesync-dkms)
- Directly with`linux-tkg`: enable it in the `customization.cfg` or select it from the interactive script. It will do the following
  - Build and bundle the `winesync` module
  - Make the module be autostarted by systemd by creating the `/etc/modules-load.d/winesync.conf` file that contains "winesync" inside.
  - Create a `udev` rule for `winesync` in `/etc/udev/rules.d/winesync.rules` to give it proper permissions. The file contains `KERNEL=="winesync", MODE="0644"`.
  - Add the `winesync` header file to `/usr/include/linux/winesync.h`. In RPM and DEB distros this header file is installed through one of the RPM/DEB packages created. For `Generic` distro, it gets installed by `make headers_install HDR_INSTALL_PATH=/usr`

To know that your linux-tkg kernel is sucessfully showing futex2 sysfs handles, this command should output `futex2`:

```shell
ls /sys/kernel | grep futex
```

For a less efforts solution, you can look up Xanmod kernel, Liquorix, Linux-zen, Chaotic-AUR (Archlinux). That provide precompiled binaries. (`futex2` is afaik not available in them).

### Game mode

It's a small program that puts your computer in performance mode: as far as I know it puts the frequency scaling algorithm to `performance` and changes the scheduling priority of the game. It's available in most distro's repositories and I believe it helps in giving consistent FPS. Lutris uses it automatically if it's detected, otherwise you need to go, for any game in Lutris, to "Configure" > "System Options" > "Environment variables" and add `LD_PRELOAD="$GAMEMODE_PATH/libgamemodeauto.so.0"` where you should replace `$GAMEMODE_PATH` with the actual path (you can do a `locate libgamemodeauto.so.0` on your terminal to find it). Link here: https://github.com/FeralInteractive/gamemode.

You can check whether or not gamemode is running with the command `gamemoded -s`. For GNOME users, there's a status indicator shell extension that show a notification and a tray icon when gamemode is running: https://extensions.gnome.org/extension/1852/gamemode/


### AMD Ryzen: the `cpuset` trick

#### A small intro to CPU cache
The cache is the closest memory to the CPU, and data from RAM needs to go through the cache first before being processed by the CPU. The CPU doesn't read from RAM directly. This cache memory is very small (at maximum few hundred megabytes as of current CPUs) and this leads to some wait time in the CPU: when some data needs to be processed but isn't already in cache (a "cache miss"), it needs to be loaded from RAM. When the cache is "full", because it will always be, some "old" data in cache is synced back in RAM then deleted to give some space to the new needed data. This takes time.

There is usually 3 levels of cache memory in our CPUs: L1, L2, and L3. In Ryzen, the L1 and L2 are few hundred kilobytes and the L3 a (few) dozen megabytes. Each core has its own L1 and L2 cache, the L3 is shared: in zen/zen+/zen2 it is shared among each 4 cores (called a CCX). and CCX'es are groupped two by two in what is called CCDs. In zen 3, the L3 cache is shared  among the cores of an entire CCD, 8 cores. There's [this anandtech article](https://www.anandtech.com/show/16214/amd-zen-3-ryzen-deep-dive-review-5950x-5900x-5800x-and-5700x-tested/4) that gives a through analysis of cache topology in Zen 2 vs Zen 3:

![Zen3_vs_Zen2](./images/Zen3_vs_Zen2.jpg)

One can obtain the cache topology if his current machine by running the following command:
```shell
$ lstopo
```

The lstopo of my previous Ryzen 3700X gives this

![Ryzen 3700X topology](./images/Ryzen-3700X-cache-topology.png)

For my Ryzen 5950X gives this

![Ryzen 5950X topology](./images/Ryzen-5950X-cache-topology.png)

#### What can we do with this information ?
Something really nice: give an entire CCX (for Zen/Zen+/Zen2 for CPUs that have six or more cores) or CCD (for Zen3, can only work with a `5950X` or a `5900X`) to your game, and make (nearly) everything else run in the other CCX(s)/CCD(s). With this, as far as I can hypothesize, one reduces the amount of L3 cache misses for the game, since it doesn't share it with no other app. The really nice thing with this, that you can notice easily, is that if you run a heavy linux kernel compilation on the other CCX(s)/CCD(s) your game is less affected: you can test for yourself. I think that using this trick also downplays the role a scheduler has on your games, since the game is alone and very few other things run with it on the same cores (like wine and the kernel).
#### Using `cpuset`

[cpuset](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v1/cpusets.html) is a linux mechanism to create groups of cores (a cpu set) to which you can assign processes, at runtime. One can use it to create two cpu sets: one for your game, another for all the rest. Have a read at the doc to understand how things work. I may update things here to explain further.

A Ryzen CPU withtwo or more CCDs/CCXs can be split into two sets of cores, lets call the first one `theGood` (for games) and the second `theUgly` (for the rest). I made two similar scripts that do this, [one for the Ryzen 3700X](./scripts/tasks_redirect_3700X.sh), that has 8 cores, 16 threads: logical cores 0-3,8-11 (given in the `P#` in the `lstopo` result) are assigned to `theGood`, which are associated to 4 physical cores (with SMT) in CCX0. Cores 4-7,12-15 are assigned to `theUgly` in CCX1 ; another one for [for the Ryzen 5950X](./scripts/tasks_redirect_5950X.sh), that has 16 cores, 32 threads: logical cores 0-7,16-23 (given in the `P#` in the `lstopo` result) are assigned to `theGood`, which are associated to 8 physical cores (with SMT) in CCD0. Cores 8-15,24-31 are assigned to `theUgly` in CCD1. Then, the script redirects `lutris` to the `theGood` cpuset. Any process in a given cpu set will spawn child processes in the same cpu set, so `lutris` will launch wine and the game in the same cpuset automatically. You can edit the script to fit with your current CPU, after having a look at what `lstopo` outputs and at the cpuset documentation. You can reverse that cpu set creation and go back to no splitting between cores : created cpu sets (that are folders) can be removed if all the processes they contain get redirected to the main cpu set, that contains all cores. [I made that script too](./scripts/reverse_tasks_redirect.sh).

**important:** core IDs should be carefully chosen so the cpu sets are separated by CCX/CCD and not just make a non hardware aware split (a recent AMD BIOS update changed the core naming scheme to fit with what Intel does), one way to verify it is, after doing the splitting, to call `lstopo` in both cpusets and verify. A way to do so is to move one shell to the new group, as root:

```shell
/bin/echo $$ >> /dev/cpuset/theGood/tasks
lstopo
```
![Ryzen 3700X topology](./images/cgroup2.png)

Then also open another shell, and do `lstopo`, you should get separate results:

![Ryzen 3700X topology](./images/cgroup1.png)

#### Benchmark
I did [this benchmark](#overwatch-cpuset) on Overwatch, the conclusions are the following:
- After a fresh restart, I already have a small number of processes (around 300), and most of them are sleeping, which means that Overwatch basically already has the entirety of the CPU for itself. Doing the cpuset trick reduced the performance: I think it's because Overwatch works optimally in more than 4 cores.
- Playing while doing another heavy workload, like stream with software encoding, works better with the cpuset trick.
## Wine

Wine is a program that enables running windows executables on Linux. Through Wine, windows executables run natively on your linux machine (**W**ine **I**s **N**ot an **E**mulator xD), Wine will be there to remap all Windows specific behavior of the program to something Linux can handle, `DXVK` for example replaces the part of Wine that maps `DirectX` (Windows specific) calls of executables to Vulkan calls (That Linux can handle). Tweaking Wine can have quite the impact on games, both positive and negative. Latest wine from Lutris works fine, but `wine-tkg` in my experience performs better.

#### Environment variables

Some [wine environment variables](https://wiki.winehq.org/Wine-Staging_Environment_Variables#Shared_Memory) can be set that can help with performance, given that they can break games, they can be added on a per-game basis as usual in Lutris. The variables are the following:

```shell
STAGING_SHARED_MEMORY=1
STAGING_WRITECOPY=1
```

### wine-tkg
[wine-tkg](https://github.com/Frogging-Family/wine-tkg-git) is a set of scripts that clone and compile `wine`'s source code, on your own machine, with extra patches that offer better performance and better game compatibility. One of the interesting offered extra features are additionnal [threading synchronisation](#threading-synchronisation) primitives that work with the corresponding patched `linux-tkg` kernel. One can use `Esync+Fsync+Futex2` or `fastsync` (with its corresponding kernel module `winesync`).

#### Esync (+ Fsync (+ Futex2))
To enable the use of `Esync` + `Fsync` + `Futex2`, `wine-tkg` needs to be built with the corresponding features enabled. Then, to enable `Esync+Fsync+Futex2`, you need to set the following environment variables
```shell
WINEESYNC=1
WINEFSYNC=1
WINEFSYNC_FUTEX2=1
```
Note that you can also run with only `Esync` or `Esync+Fatsync` by setting the variables to `0` (to disable) or `1` (to enable) accordingly. To know that `esync`, `esync+fsync` or `esync+fsync+futex2` is running. You can try running your game/launcher from the command line and you should see one of the following:
- `esync`:
  ```shell
  [...]
  esync: up and running
  [...]
  ```
- `esync+fsync`:
  ```shell
  [...]
  fsync: up and running
  [...]
- `esync+fsync+futex2`:
  ```shell
  [...]
  futex2: up and running
  [...]
  ```
`esync+fsync+futex2` should be the fastest. But once again, you can only try to make sure.

#### Fastsync
To be able to use `fastsync` with `wine-tkg`, you need to do the following, **in this order**
1. Be running a `winesync` enabled `linux-tkg` kernel, more information [in this section](#threading-synchronisation)
2. Disable the use of `wine-staging`, `fsync` and `futex2` in `wine-tkg`'s (proton or vanilla) config file before building it. 
    * You can also use [this repository](https://github.com/openglfreak/wine-tkg-userpatches/tree/next), instead of disabling the stuff above, to be able to build a `wine-tkg` that can run both `fsync/futex2` and `fatsync` with `wine-staging` code, although that reposistory as-is is hard to use as it has no documentation yet on how to use it.
3. Disable all environment variables related to `esync/fsync/futex2` (and also from lutris' game options):
    ```shell
    WINEESYNC=0
    WINEFSYNC=0
    WINEFSYNC_FUTEX2=0
    ```
To know if fastsync is correctly working, you may run your game/launcher from the command line once and look for the following lines:
```shell
wineserver: using server-side synchronization.
wine: using fast synchronization.
```
This command should also return few exectuables
```shell
lsof /dev/winesync
```
**Note:** even with this, sometimes `fatsync` does not correctly work. I am investigating and will update this guide accordingly. `fastsync` should have a similar performance to `Futex2` so far, so if it doesn't work for you, switch back to `Futex2` then try again a little bit later.
#### compiler optimisations

On top of the config variables that can be toggled in `customization.cfg` in `wine-tkg`, you can set [custom compiler optimizations](#self-compiling) by editing the following lines of the file `wine-tkg-profiles/advanced-customization.cfg`

```shell
_GCC_FLAGS="... EDIT HERE ..."
# Custom LD flags to use instead of system-wide makepkg flags set in /etc/makepkg.conf. Default is "-pipe -O2 -ftree-vectorize".
_LD_FLAGS="-Wl,-O1,--sort-common,--as-needed"
# Same as _GCC_FLAGS but for cross-compiled binaries.
_CROSS_FLAGS="... EDIT HERE ..."
# Same as _LD_FLAGS but for cross-compiled binaries.
_CROSS_LD_FLAGS="-Wl,-O1,--sort-common,--as-needed"
```
Where you can change `... EDIT HERE ...` with flags [from here](#flags-to-try): note that LTO nor PGO works with wine, you can at most use the `BASE + GRAPHITE + MISC` flags

## Overclocking

### CPU and GPU
Overclocking is possible on Linux, please refer to the Archlinux wiki on [Improving performance](https://wiki.archlinux.org/index.php/Improving_performance#Overclocking) for more information.

### RAM

I have found a super nice [guide on Github](https://github.com/integralfx/MemTestHelper/blob/master/DDR4%20OC%20Guide.md) on the matter.
## X11/Wayland

I use only X11 for now, and works nicely. Wayland is not as good as X11 for gaming, for now. Except maybe with a custom wine with Wayland patches: https://github.com/varmd/wine-wayland. I am unable to run Overwatch with it yet. 

**Best DE for gaming:** In terms of input lag LXDE/LXQt (using OpenBox as a WM) has the lowest input lag and the smoothest feel, I heard KDE with its recent `5.22` update should be pretty competitive. `Gnome`, even though I like it for desktop work, sucks with gaming (frame drops, high input lag).

**Some X11 settings for gaming:**
- The `TearFree` option,  to enable it on `AMDGPU`, [follow this](https://wiki.archlinux.org/title/AMDGPU#Tear_free_rendering). Some may argue that it reduces input lag, I think that it's theoretically right. But with high refresh rate monitors, (e.g. 240Hz), I think image update smoothness is way more noticeable than the added input lag. This option entirely removes screen tearing with anything: scrolling on Firefox, on compositorless DEs like LXDE melted butter smooth, for example.
- If you have a FreeSync/Gsync monitor and a GPU that supports it, [follow this documentation](https://wiki.archlinux.org/title/Variable_refresh_rate) on how to enable it on Linux. Reviews of monitors seem to show that enabling this actually adds input lag, but once again, it's better than tearing.

## Performance overlays

Performance overlays are small "widgets" that stack on top of your game view and show performance statistics (framerate, temperatures, frame times, CPU/RAM usages... etc). Two possibilities:

* MangoHud: It is available in the repositories of most linux distros, to activate it, you only need to add the environment variable `MANGOHUD=1`, and the stats you want to see in `MANGOHUD_CONFIG`. The interesting part of MangoHud is that it can also bechmark games: Record the entirety of the frame times, calculate frametime percentiles...etc Ideal to do benchmarks with. More information here: https://github.com/flightlessmango/MangoHud. It can be configured via a GUI with GOverlay - https://github.com/benjamimgois/goverlay
* DXVK has its own HUD and can be enabled by setting the variable `DXVK_HUD`, the possible values are explained in [its repository](https://github.com/doitsujin/dxvk)

## Streaming - Saving replays

### OBS

[OBS](https://obsproject.com/) is the famous open source streaming software, it works nicely with X11 on AMD GPUs, especially LXDE (when compared to Gnome) I feel no added input lag with LXDE. The video quality is actually better than Windows, since you can use VAAPI-FFMPEG on Linux, and it has a better video quality than the AMD thingy on windows. Nvidia has been reported to work nicely on linux and on windows with their new NVENC thing.

#### Using `cpuset` with software encoder on Ryzen CPUs

If you can't use your own GPU for encoding or prefer to use a software encoder, it's a very good idea to se the `cpuset` trick explained above to not affect your game's performance by running OBS in a different CCX/CCD. I tried it and it makes a huge difference.

**An important fix for an issue I have been having for a year now**
- __Network Error on Twitch:__ Switching between sources that leave a black screen for a very short time, _e.g._ having the game in a virtual desktop then switching to another virtual desktop, makes the stream on twitch crash for whatever reason. To work around this, keep a background image behind all of your sources, so whenever nothing is shown, it's that background image.

#### Gnome

On Gnome, an experimental feature can be enabled: 
```shell
gsettings set org.gnome.mutter experimental-features '["dma-buf-screen-sharing"]'
```
That will enable window capturing through the ["dma-buf" sharing protocol](https://elinux.org/images/a/a8/DMA_Buffer_Sharing-_An_Introduction.pdf). Which enables `OBS` to work on Wayland but also not add as much input lag is with its `Xcomposite` backed. This feature can only be used by `obs-studio` version `27.0` onwards. If your distro doesn't provide that version, it can be installed via `flatpak`
```shell
flatpak install --user https://flathub.org/beta-repo/appstream/com.obsproject.Studio.flatpakref
```
On Gnome under X11, you need to run OBS with an extra environment variable, `OBS_USE_EGL=1`:
```shell
OBS_USE_EGL=1 com.obsproject.Studio
```
where `com.obsproject.Studio` is the name of the `obs-studio` executable, installed through flatpak, it may have another name in your specific distro.

#### obs-vkcapture

[obs-vkcapture](https://github.com/nowrep/obs-vkcapture) implements the ["dma-buf" sharing protocol](https://elinux.org/images/a/a8/DMA_Buffer_Sharing-_An_Introduction.pdf) for capturing games: it needs the version `27.0` of `obs-studio`, or newer, to be installed in the regular way because it needs headers from it (it must be possible to use the flatpak version too but I don't know how). If your distro doesn't ship that version of `obs-studio`, you can compile from source ([documentation here](https://github.com/obsproject/obs-studio/wiki/Install-Instructions#linux-build-directions)).

Once you have a working `obs-studio` version `27.0` or higher, you need to compile `obs-vkcapture` form source then install it, documentation in its Github page. After that, you need to run `obs-studio` with the environment variable, `OBS_USE_EGL=1`:
```shell
OBS_USE_EGL=1 obs
```
And you will see a `game capture` new source entry. It works great and fixed my issues with added input lag and stuttering `obs-studio` used to have.

### Replay sorcery

[Replay sorcery](https://github.com/matanui159/ReplaySorcery) is a tool to save small replays of your gaming sessions, without the need to be streaming. It saves a "video" of your play for the past `x` seconds in RAM: it is saved as sequence of JPEG images (small footprint on the computer's ressources). And these images are only converted to a video when you want to actually save a replay (more ressource heavy). I haven't given it a try, if you want to add hints and tips about it, please feel free to PR something or open an issue!

### Stream only the game sounds

You are in a Discord call and streaming at the same time, but you only want OBS to stream the game's sounds ? Search no more. The solution is here (that I found [here](https://unix.stackexchange.com/questions/384220/how-to-create-a-virtual-audio-output-and-route-it-in-ubuntu-based-distro)): the idea is to create some kind of virutal soundcard, let's call it `Game-Sink`, where the game will output it sound on. Then you redirect the sound from `Game-Sink` to your actual soundcard.

Create `Game-Sink`:
```shell
pacmd load-module module-null-sink sink_name=game_sink sink_properties=device.description=Game-Sink
```
Find the actual name of `$OriginalSoundcard`: you do this command and look at its output, you should recognize your card's name there:
```shell
pacmd list-sinks | grep name:
```
For example, for me I have a SteelSeries Arctis PRO with the Game DAC (with cable), the name of my card is `alsa_output.usb-SteelSeries_SteelSeries_GameDAC_000000000000-00.iec958-stereo`. So here's how you do the loopback from `Game-Sink`:
```shell
pacmd load-module module-loopback source="game_sink.monitor" sink="alsa_output.usb-SteelSeries_SteelSeries_GameDAC_000000000000-00.iec958-stereo"
```
Then, all what's left is to do is to open `pavucontrol` (google how to install it if you don't have it) and select `Game-Sink` for where `obs-studio` picks its audio from. And select `Game-Sink` for where the game outputs its audio to.

## Sound improvements with PulseAudio

### Improve the sound of your headset

There is a nice Github repository, called [AutoEq](https://github.com/jaakkopasanen/AutoEq), that references the frequency responses of various headsets that have been reviewed by websites like [rtings.com](rtings.com) and others. The frequency responses are made available as `.wav` files in that repository.

A headset with high fidelity should have a flat frequency response, but affordable/real life headsets do not exhibit a flat one. What one can do with those `.wav` files is to use them and correct what is fed to the headset with software and improve the perceived sound. Although, one must know that the frequency response of one's own headset is for sure different from the ones available in [AutoEq](https://github.com/jaakkopasanen/AutoEq). But it may still improve one's audio experience if, let's say, all the headsets from your specific model have a similar frequency response.

#### The Graphical way

Install `pulseeffects` (`pulseeffects-legacy-git` from the AUR if on Archlinux) and enable the "Convolver" plugin for your ouput sound:

![PulseEffects mic noise suppression](./images/headset-auto-eq-gui.png)

You need to download the corresponding `.wav` file to your headset, from the [AutoEq](https://github.com/jaakkopasanen/AutoEq) github repository. For example the files related to my headset are [these ones](https://github.com/jaakkopasanen/AutoEq/tree/master/results/rtings/rtings_harman_over-ear_2018/SteelSeries%20Arctis%20Pro%20GameDAC). There's a 44.1kHz and a 48kHz version for those `.wav` files. Pick the highest frequency your soundcard can handle, or just try both if you are too lazy to figure that out haha.

*Note:* the `pulseeffects` app must remain open for this to keep on working, except if you enable the "start as a service on login" menu option then log out and back in.
### Mic noise suppression

You have cherry blue mechanical keyboard, your friends and teammates keep on complaining/sending death threats about you being too noisy with your keyboard ? Fear no more.

**A bit of history:** People from Mozilla made some research to apply neural networks to noise suppression from audio feeds, they [published](https://jmvalin.ca/demo/rnnoise/) everything about it, including the code. Another person, "Werman", picked up their work and made it work as a [PulseAudio plugin](https://github.com/werman/noise-suppression-for-voice).

#### The Graphical way

Install `pulseeffects` (`pulseeffects-legacy-git` from the AUR if on Archlinux) and enable the "Noise Reduction" plugin for your mic:

![PulseEffects mic noise suppression](./images/mic-noise-suppression-gui.png)

*Note:* the `pulseeffects` app must remain open for this to keep on working, except if you enable the "start as a service on login" menu option then log out and back in.
#### The command line way

All this is explained in [Werman's Git repository](https://github.com/werman/noise-suppression-for-voice). I will put it back here.

1- Clone, build and install the plugin
```shell
git clone https://github.com/werman/noise-suppression-for-voice.git noise-suppression
cd noise-suppression
cmake -Bbuild-x64 -H. -DCMAKE_BUILD_TYPE=Release
cd build-x64
make
sudo make install
```
2- At each login, one needs to do this: create a virtual mic, instance the denoiser module and make it output to the virtual mic, and be fed from the actual mic. This can be saved in a bash script so it can be easilly run.

For Stereo mics
```shell
#!/bin/bash

pacmd load-module module-null-sink sink_name=denoised_mic_stereo sink_properties=device.description=Denoised-Mic-Stereo rate=48000

pacmd load-module module-ladspa-sink sink_name=denoiser_stereo sink_properties=device.description=Denoiser-Stereo sink_master=denoised_mic_stereo label=noise_suppressor_stereo plugin=librnnoise_ladspa control=50

pacmd load-module module-loopback source="alsa_input.usb-SteelSeries_SteelSeries_GameDAC_000000000000-00.multichannel-input" sink=denoiser_stereo channels=2 source_dont_move=true sink_dont_move=true
```

For mono mics
```shell
#!/bin/bash

pacmd load-module module-null-sink sink_name=denoised_mic_mono sink_properties=device.description=Denoised-Mic-Mono rate=48000

pacmd load-module module-ladspa-sink sink_name=denoiser_mono sink_properties=device.description=Denoiser-Mono sink_master=denoised_mic_mono label=noise_suppressor_mono plugin=librnnoise_ladspa control=50

pacmd load-module module-loopback source="alsa_input.usb-SteelSeries_SteelSeries_GameDAC_000000000000-00.multichannel-input" sink=denoiser_mono channels=1 source_dont_move=true sink_dont_move=true
```

Where `alsa_input.usb-SteelSeries_SteelSeries_GameDAC_000000000000-00.multichannel-input` is the name of my mic input. You can obtain the name of your mic input with:
```shell
pactl list sources short
```

## Game render tweaks: vkBasalt

[vkBasalt](https://github.com/DadSchoorse/vkBasalt) uses the layered approach to Vulkan to enable post processing to any Vulkan game you'd like to play. The currently proposed tweaks include `Contrast Adaptive Sharpening`, `Denoised Luma Sharpening`, `Fast Approximate Anti-Aliasing`... Check out the Git repository for more information. I haven't given it a try yet (Any PR/issue about it is welcome!)

## Compositor / desktop effects

The compositor is the part of your DE that adds desktop transparency effects and animations. In games, this can result in a noticeable loss in fps and added input lag. Some DEs properly detect the fullscreen application and disable compositing for that window, others don't. Gnome, if recent enough, disables the compisitor for fullscreen apps. Luckily, apparently, Lutris has a system option called Disable desktop effects which will disable compositing when you launch the game and restore it when you close it.

## Benchmarks

Benchmarks are welcome: If you happen to do some you are welcome to PR them. I sugggest to use MangoHud and upload the results to its corresponding website (https://flightlessmango.com), more information [here](https://github.com/flightlessmango/MangoHud), before uploading the results make sure to include as many information as possible to be able to "reproduce"
  - hardware: CPU, GPU, RAM (with timings)
  - Software: version of the distro, Kernel (if linux-tkg, the modified options in `customization.cfg`), Wine (if wine-tkg, the modified options too), DXVK, Mesa/AMDVLK/Nvidia, compilation process (if manually compiled)
  - Game: how to reproduce the measured benchmarks: Fsync/Esync ? is it a benchmark tool ingame ? a saved play ? Can it be shared so other can benchmark against the same thing with different hardware/software ?

**Benchmarks done:**

- [`cpuset` trick](#amd-ryzen-the-cpuset-trick)
  - Overwatch
    - [Benchmark 1](https://flightlessmango.com/games/15751/logs/1343): `cpuset` on vs off, with both ccx separation and smt separation.

**Possible benchmarks:**
- Fysnc/Esync on vs Fsync/Esync off
- Different wine versions
- Kernel schedulers (CFS, PDS, BMQ, MuQSS) in various conditions.
- Compiler optimisations: Wine, DXVK, Kernel, Mesa.


## Misc
* There is very nice documentation on the [Archlinux wiki about improving performance](https://wiki.archlinux.org/index.php/Improving_performance)
* Firefox on Wayland with high refresh rate monitors: [smooth scrolling](https://www.reddit.com/r/linux/comments/l1re17/psa_by_default_firefox_on_linux_doesnt_match_with/)
* [Another github repository](https://github.com/LinuxCafeFederation/awesome-gnu-linux-gaming) that references nice tools for gaming.
* Background YT videos: If you have youtube music in the background, try to switch to an empty tab and not leave the tab on the video. I noticed that like this the video doesn't get rendered and helps freeing your GPU or CPU (depending on who is doing the decoding).
* KDE file indexer : If you're using KDE, you may consider disabling the file indexer. This is either done in the KDE settings or with `balooctl disable` (requires a reboot).
