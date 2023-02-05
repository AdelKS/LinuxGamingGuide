# A linux gaming guide

This is some kind of guide/compilation of things, that I got to do/learn about while on my journey of gaming on linux. I am putting it here so it can be useful to others! If you want to see something added here, or to correct something where I am wrong, you are welcome to open an issue or a PR !

## Table of Content

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [A linux gaming guide](#-a-linux-gaming-guide)
  - [Table of Content](#-table-of-content)
  - [Linux distribution](#-linux-distribution)
  - [Self-compiling](#-self-compiling)
    - [Flags to try](#-flags-to-try)
  - [DXVK](#-dxvk)
    - [Custom compile flags](#-custom-compile-flags)
  - [GPU](#-gpu)
    - [Nvidia](#-nvidia)
    - [AMD](#-amd)
      - [RADV](#-radv)
        - [Self-compile](#-self-compile)
  - [Kernel](#-kernel)
    - [Command line options](#-command-line-options)
    - [Custom/self compiled kernels](#-customself-compiled-kernels)
      - [Threading synchronization](#-threading-synchronization)
    - [Game mode](#-game-mode)
    - [AMD Ryzen: the `cpuset` trick](#-amd-ryzen-the-cpuset-trick)
      - [A small intro to CPU cache](#-a-small-intro-to-cpu-cache)
      - [What can we do with this information ?](#-what-can-we-do-with-this-information-)
      - [Using `cpuset`](#-using-cpuset)
      - [Benchmark](#-benchmark)
  - [Wine](#-wine)
      - [Environment variables](#-environment-variables)
    - [Wine-tkg](#-wine-tkg)
      - [Esync-Fsync-Futex2](#-esync-fsync-futex2)
      - [Fastsync](#-fastsync)
      - [compiler optimizations](#-compiler-optimizations)
  - [Game / "Wine prefix" manager](#-game--wine-prefix-manager)
    - [Lutris](#-lutris)
    - [Bottles](#-bottles)
    - [Heroic Games Launcher](#-heroic-games-launcher)
    - [Steam](#-steam)
  - [Overclocking](#-overclocking)
    - [CPU and GPU](#-cpu-and-gpu)
    - [RAM](#-ram)
  - [X11/Wayland](#-x11wayland)
  - [Performance overlays](#-performance-overlays)
  - [Streaming - Saving replays](#-streaming---saving-replays)
    - [OBS](#-obs)
      - [Desktop environments](#-desktop-environments)
        - [Gnome](#-gnome)
      - [Encoders](#-encoders)
      - [Using `cpuset` with software encoder on Ryzen CPUs](#-using-cpuset-with-software-encoder-on-ryzen-cpus)
      - [obs-vkcapture](#-obs-vkcapture)
    - [Replay sorcery](#-replay-sorcery)
  - [Sound tweaks with Pipewire/Pulseaudio](#-sound-tweaks-with-pipewirepulseaudio)
    - [Stream only the game sounds](#-stream-only-the-game-sounds)
    - [Improve the sound of your headset](#-improve-the-sound-of-your-headset)
      - [The Graphical way](#-the-graphical-way)
    - [Mic noise suppression](#-mic-noise-suppression)
      - [The Graphical way](#-the-graphical-way-1)
      - [The command line way](#-the-command-line-way)
  - [Game render tweaks: vkBasalt](#-game-render-tweaks-vkbasalt)
  - [Compositor / desktop effects](#-compositor--desktop-effects)
  - [Benchmarks](#-benchmarks)
  - [Misc](#-misc)

<!-- /code_chunk_output -->


## Linux distribution

I have seen many reddit posts asking which linux distributions is "best" for gaming. My thoughts on the matter is that, to get the best performance, one simply needs the latest updates. All linux distributions provide the sames packages and provide updates. Some provide them faster than others. So any distribution that updates its packages the soonest after upstream (aka the original developers), is good in my opinion. Some distributions can take longer, sometimes 6 months after, for big projects (which is acceptable too, since one would get the updates without the initial bugs).

## Self-compiling

Compiling is the process of transforming human written code (like C/C++/Rust/... etc) to machine runnable programs (the `.exe` files on Windows, on Linux they usually have no extension :P). Compiling is actually done by a program, a compiler, on linux it's `gcc` or `clang`. There is not a unique way to translate/compile code to machine runnable programs, the compiler has lots of freedom on how to implement that, and we can influence them by telling them to try "harder" to optimize the machine code, by giving them the so called "flags": a set of command line options given to the compiler, an example is
```shell
gcc main.c -O2 -march=native -pipe
```
where `-O2`, `-march=native` and `-pipe` are compiler flags. There are many flags that compilers accept, the ones specific to optimization are given in [GCC's documentation](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html). A few important (meta)flags
- The `-Ox`, where `x=1,2,3`, is a generic flag that sets the generic level optimization, it activates many other flags that actually do something. Distros compile the packages they ship usually with `-O2`
- The `-march` flag is a flag that tells the compiler to use additional features that aren't available for all CPUs: newer CPU implement some "instruction sets" (aka additional features) that enable them to perform some tasks faster, like [SIMD instructions](https://en.wikipedia.org/wiki/SIMD). It makes some programs faster, like `ffmpeg` with video conversion. These instruction sets are not used by default in packages shipped by distros as they need to have them able to run on all machines, even those from 2001. So one can win some performance by just compiling with `-march=native` their computational heavy programs. Although some have embedded detection code to use additional instruction sets if detected. Some Linux Distributions like [Gentoo](https://www.gentoo.org/) enable you to compile every single package on your own machine so you can have ALL the apps built with `-march=native` (it may take several hours depending on your CPU)
- Link Time Optimizations (LTO) that involve the use of the flags `-flto`, `-fdevirtualize-at-ltrans` and `-flto-partition`
- Profile Guided Optimizations (PGO) that involve the use of `-fprofile-generate=/path/to/stats/folder`, `-fprofile-use=/path/to/stats/folder` flags. The idea behind is to produce a first version of the program, with performance counters added in with the `-fprofile-generate=/path/to/stats/folder` flag. Then you use the compiled program in your real life use-cases (it will be way slower than usual), the program meanwhile fills up some extra files with useful statistics in `/path/to/stats/folder`. Then you compile again your program with the `-fprofile-use=/path/to/stats/folder` flag with the folder `/path/to/stats/folder` filed with statistics files that have the `.gcda` extension.

A nice introduction to compiler optimizations `-Ox`, `LTO` and `PGO`, is made in a Suse Documentation that you can find here: https://documentation.suse.com/sbp/all/html/SBP-GCC-10/index.html

The Kernel, `Wine`, `RADV` and `DXVK` can be compiled on your own machine so you can use additional compile flags (up to a certain level) for the particular CPU you own and potentially faster with more "aggressive" compiler flags. I said potentially as you need to check for yourself if it is truly the case or not.

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
It is recommended to try them in the following order, if one fails (for whatever reasons: fails to compile or doesn't work), try the next one:
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
Where you can replace `... TO BE FILLED ...` with `BASE + GRAPHITE + MISC + LTO3` flags [defined here](#flags-to-try) if you don't enable `PGO`. If you want to use [PGO](#self-compiling), you can use the `BASE + GRAPHITE + MISC + LTO2` + `-fprofile-generate=/path/to/dxvk-pgo-data` or `-fprofile-use=/path/to/dxvk-pgo-data`, depending on the stage you are in. You can change the `=/path/to/dxvk-pgo-data` path. You also need to add `'-lgcov'` to `c_link_args` and `cpp_link_args`

**Note:** you need to respect the syntax of the `build-winXX.txt` files. Flags are quoted and separated with comas _e.g._ `c_args=['-O2', '-march=native']`.

These flag changes may improve performance or not, the best is to test with and without and see for oneself. If regressions happen or it doesn't want to compile you can try [other flags](#flags-to-try).

## GPU

1. Update to the latest possible driver for your GPU
2. If you are hesitating between AMD and Nvidia for your next GPU buy. As far as Linux is concerned: AMD all the way, because they are way more supported since they give out an open source driver.

### Nvidia

The least one can do is redirect to Arch's documentation about it: https://wiki.archlinux.org/index.php/NVIDIA

If you didn't install the proprietary driver your computer is likely to be running an open source driver called `nouveau`, but you wouldn't want that to play games with that as it works based off reverse engineering and doesn't offer much performance.

Once you have the proprietary driver installed, open `nvidia-settings`, make sure you have set your main monitor to its maximum refresh rate and have 'Force Full Composition Pipeline' disabled (advanced settings).

Also, in Lutris, you can disable the size limit of the NVidia shader cache by adding `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1` to the environnement variables.

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
- If you enabled the `LTO` flags you must set `-D b_lto=true`, otherwise `-D b_lto=false`
- With regards to PGO, first read [the bullet point about PGO](#self-compiling)
  1. Profile generation
      - you must set `-D b_pgo=generate`
      - append `-fprofile-generate=$HOME/radv-pgo-data` to `CFLAGS`, where you can replace `$HOME/radv-pgo-data` by another folder if you wish
  2. Profile use
      - you must set `-D b_pgo=use`
      - append `-fprofile-use=$HOME/radv-pgo-data` to `CFLAGS`, where you replace `$HOME/radv-pgo-data` with the same folder you used for profile generation
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

I ran across another protection that got added in the kernel that disables a certain set of cpu instructions from user space programs (`umip`), instructions from this set is used for example in Overwatch some other games. That protection broke those games then the kernel got [a patch that emulates those instructions](https://github.com/torvalds/linux/commit/1e5db223696afa55e6a038fac638f759e1fdcc01) with a certain overhead with a kernel message like this one:
```shell
kernel: umip: Overwatch.exe[5970] ip:140621a9a sp:21dea0: For now, expensive software emulation returns the result.
```
You can disable this protection with the following kernel parameter `clearcpuid=514`
### Custom/self compiled kernels

Using a self-compiled kernel can bring some improvements. There is a git repository called [linux-tkg](https://github.com/Frogging-Family/linux-tkg) that provides a script to compile the linux Kernel from source (takes about ~30mins, but can be stripped down with `modprobed-db`) with some customization options : the default [scheduler](https://en.wikipedia.org/wiki/Scheduling_(computing)) ([CFS](https://en.wikipedia.org/wiki/Completely_Fair_Scheduler)) can be changed to other ones (Project C UPDS, PDS, BMQ, MuQSS)  These changes help getting better performance in games. And also other patches. Linux-tkg needs to be compiled on your own machine, where you can use compiler optimizations such as `-O3` and `-march=native` (LTO is experimental and Clang only, PGO will come soon), with an interactive script and a config file, I worked on the script to install on many distros other than Arch

More information here: https://github.com/Frogging-Family/linux-tkg

#### Threading synchronization

`linux-tkg` offers patches that makes the kernel better mimic Windows' behavior with threads. And therefore get better performance for games meant to run on Windows: `winesync/fastsync`, `futex2`, `fsync`, `esync`.

`esync`, `fsync` and `futex2` names you may have heard about have been developed by CodeWeavers and Collabora. Chronologically, here's what happened
- `esync` is the oldest implementation and available in any non ancient kernel in any distro, since it uses the kernel's `eventfd` [system call](https://man7.org/linux/man-pages/man2/eventfd.2.html). Issues arise in some distros when a game opens a lot of the so called "file descriptors"
- `FUTEX_WAIT_MULTIPLE`, a special additional flag on the `futex` [system call](https://man7.org/linux/man-pages/man2/futex.2.html) was developed and originally called `fsync` (that we will also call `fsync1`). `linux-tkg` and `wine-tkg` were offering support for this work under the `fsync` naming. This work did not get upstreamed in the linux kernel (out-of-tree).
- `futex2` implementing  a new system call
  - Initially called `futex_wait`: `linux-tkg` and `wine-tkg` were offering support for this work under the `futex2` naming.
  - The system call then [got upstreamed](https://www.kernel.org/doc/html/latest/userspace-api/futex2.html) in kernel `5.16` with a slightly different name : `futex_waitv`. Since then, it is referred to as `fsync` (so basically an `fsync2`) or `futex2` interchangeably. Which leads to some confusions...

`linux-tkg` offers, through its `customization.cfg` file :
- In kernels 5.16+
  - builtin support for `futex_waitv`
  - Support for `fsync1` through `futex_waitv` to support `fsync1` with old wines.
- In kernels 5.15, 5.14 and 5.13
  - Back ported patches of `futex_waitv` thanks to [these efforts](https://github.com/andrealmeid/futex_waitv_patches) (the original author behind the upstreaming effort).
- For kernels < 5.16 : Support for "old" `futex2` and `fsync1`. Old `futex2` implementation exposed sysfs handles as its syscall number wasn't decided yet. On such kernels the following should output `futex2`: `ls /sys/kernel | grep futex`

`winesync/fastsync` is a new proposal of synchronization subsystem, similar to `futex` and `eventfd`, aimed to serve exclusively for mapping Windows API sync mechanisms. developed by wine developers. This implementation is put on hold since the upstreaming of `futex_waitv`. `winesync` is a kernel module that communicates with `fastsync` that should be in a patched wine (like `wine-tkg`). The performance should be similar or better than `esync`, but probably not better than `fsync`. To have the `winesync` module:
- The DKMS route
  - Archlinux: you need to install the following package from the AUR: `winesync`, `winesync`, `winesync-header` and `winesync-udev-rule`
  - other distros: follow the [README in this repository](https://github.com/Cat-Lady/winesync-dkms)
- Not offered by `linux-tkg` [any longer](https://github.com/Frogging-Family/linux-tkg/commit/b357a8c0486575083c59c4caa15ca8dc1ea54e87)

For a less efforts solution, you can look up Xanmod kernel, Liquorix, Linux-zen, Chaotic-AUR (Archlinux). That provide precompiled binaries. (`futex2` is afaik not available in them).

### Game mode

It's a small program that puts your computer in performance mode: as far as I know it puts the frequency scaling algorithm to `performance` and changes the scheduling priority of the game. It's available in most distro's repositories and I believe it helps in giving consistent FPS. Lutris uses it automatically if it's detected, otherwise you need to go, for any game in Lutris, to "Configure" > "System Options" > "Environment variables" and add `LD_PRELOAD="$GAMEMODE_PATH/libgamemodeauto.so.0"` where you should replace `$GAMEMODE_PATH` with the actual path (you can do a `locate libgamemodeauto.so.0` on your terminal to find it). Link here: https://github.com/FeralInteractive/gamemode.

You can check whether or not gamemode is running with the command `gamemoded -s`. For GNOME users, there's a status indicator shell extension that show a notification and a tray icon when gamemode is running: https://extensions.gnome.org/extension/1852/gamemode/


### AMD Ryzen: the `cpuset` trick

#### A small intro to CPU cache
The cache is the closest memory to the CPU, and data from RAM needs to go through the cache first before being processed by the CPU. The CPU doesn't read from RAM directly. This cache memory is very small (at maximum few hundred megabytes as of current CPUs) and this leads to some wait time in the CPU: when some data needs to be processed but isn't already in cache (a "cache miss"), it needs to be loaded from RAM. When the cache is "full", because it will always be, some "old" data in cache is synced back in RAM then replaced by some other data from RAM: this takes time.

There is usually 3 levels of cache memory in our CPUs: L1, L2, and L3. In Ryzen, the L1 and L2 are few hundred kilobytes and the L3 a (few) dozen megabytes. Each core has its own L1 and L2 cache, the L3 is shared: in zen/zen+/zen2 it is shared among each 4 cores (called a CCX). and CCX'es are grouped two by two in what is called CCDs. In zen 3, the L3 cache is shared  among the cores of an entire CCD, 8 cores. There's [this anandtech article](https://www.anandtech.com/show/16214/amd-zen-3-ryzen-deep-dive-review-5950x-5900x-5800x-and-5700x-tested/4) that gives a through analysis of cache topology in Zen 2 vs Zen 3:

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

Wine is a program that enables running windows executables on Linux. Through Wine, windows executables run natively on your linux machine (**W**ine **I**s **N**ot an **E**mulator xD), Wine will be there to remap all Windows specific behavior of the program to something Linux can handle, `DXVK` for example replaces the part of Wine that maps `DirectX` (Windows specific) calls of executables to Vulkan calls (That Linux can handle). Tweaking Wine can have quite the impact on games, both positive and negative.

#### Environment variables

Some [wine environment variables](https://wiki.winehq.org/Wine-Staging_Environment_Variables#Shared_Memory) can be set that can help with performance, given that they can break games, they can be added on a per-game basis as usual in Lutris. The variables are the following:

```shell
STAGING_SHARED_MEMORY=1
STAGING_WRITECOPY=1
```

### Wine-tkg
[wine-tkg](https://github.com/Frogging-Family/wine-tkg-git) is a set of scripts that clone and compile `wine`'s source code, on your own machine, with extra patches that offer better performance and better game compatibility. One of the interesting offered extra features are additional [threading synchronization](#threading-synchronization) primitives that work with the corresponding patched `linux-tkg` kernel. One can use `Esync+Fsync+Futex2` or `fastsync` (with its corresponding kernel module `winesync`).

#### Esync-Fsync-Futex2
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
1. Be running a `winesync` enabled `linux-tkg` kernel, more information [in this section](#threading-synchronization)
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
This command should also return few executables
```shell
lsof /dev/winesync
```
**Note:** even with this, sometimes `fatsync` does not correctly work. I am investigating and will update this guide accordingly. `fastsync` should have a similar performance to `Futex2` so far, so if it doesn't work for you, switch back to `Futex2` then try again a little bit later.
#### compiler optimizations

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

## Game / "Wine prefix" manager

To run games on Linux, wine creates a so-called "prefix" folder with an arbitrary user chosen name, let's say `game-prefix`. It contains all the configuration specific to wine and a folder structure, within the `drive_c` subfolder, that follows Windows' structure: you can find e.g. `Program Files` or `windows/system32` subfolders in it. The DLLs in the latter folder are actually created by wine, through reverse engineering. From a game's/window's app perspective, these DLLs to behave just like windows, and wine takes care of the rest (by implementing system calls itself, in the wineserver I believe, or redirecting to the linux kernel, correct me if I am wrong please).

Usually, one creates one prefix per game/app, as sometimes each game has some quirks that  wine doesn't handle well by default for which a tweak is needed. But that tweaks would break other games apps. And that's where a "game manager" / "wine prefix manager" comes into play to avoid tedious and repetitive manual configurations:
- Automatically creates prefixes for each of your game
- Ships various version of Wine to work with the various versions of your games
- Bundles various DXVK versions to chose from
- Offers various options that can be toggled (`fsync`, `dxvk-nvapi/dlss`, `fsr`, `latencyflex`...)
- May have built-in support for extra tools like FPS counters (see [Performance overlays](#-performance-overlays)), or other kinds of stuff (see e.g. [Game render tweaks: vkBasalt](#-game-render-tweaks-vkbasalt))


### Lutris
[Lutris](https://lutris.net/) is one of these Generic open source game managers, it offers a [database](https://lutris.net/games) of scripts to automatically install various games and the quirks and/or extra configuration (e.g. extra fonts) needed to run them. It also enables you to give it your own compiled wine version and that's why I am using it currently. It is however lagging a bit behind in integrating the new tools that are being developped (e.g. `latencyflex`) and offering newer versions of runtime components (`Wine`, `dxvk`, ...). To see the toggles Lutris offers, install a game, then click `Configure` > `Runner options` tab.

### Bottles
[Bottles](https://usebottles.com/) is a modern take on generic open source game managers, it has a more intuitive configuration UI, ships the latest builds of `wine`/`dxvk`, and tries to implement integration with all the latest other tools. I could however not find how to make it use my own compiled wine version.

### Heroic Games Launcher
[Heroic Games Launcher](https://heroicgameslauncher.com) is an opensource game manager for games you own on [GOG](gog.com) or [Epic Games](https://store.epicgames.com). I have not tried it at all so that's all I can say x)

### Steam
Steam's official closed source game manager handles Linux natively and offers to run windows specific games with Steam's own builds of `proton-wine`. It also accepts custom proton builds like e.g. `proton-tkg` ([wine-tkg](https://github.com/Frogging-Family/wine-tkg-git) repo) or GloriousEggroll's [proton-ge-custom](https://github.com/GloriousEggroll/proton-ge-custom) prebuilds.

## Overclocking

### CPU and GPU
Overclocking is possible on Linux, please refer to the Archlinux wiki on [Improving performance](https://wiki.archlinux.org/index.php/Improving_performance#Overclocking) for more information.

### RAM

I have found a super nice [guide on Github](https://github.com/integralfx/MemTestHelper/blob/oc-guide/DDR4%20OC%20Guide.md) on the matter.

## X11/Wayland

I use only X11 for now, and works nicely. Wayland is not as good as X11 for gaming, for now. Except maybe with a custom wine with Wayland patches: https://github.com/varmd/wine-wayland. I am unable to run Overwatch with it yet.

**Best DE for gaming:** In terms of input lag LXDE/LXQt (using OpenBox as a WM) has the lowest input lag and the smoothest feel, I heard KDE with its recent `5.22` update should be pretty competitive. `Gnome`, even though I like it for desktop work, sucks with gaming (frame drops, high input lag).

**Some X11 settings for gaming:**
- The `TearFree` option,  to enable it on `AMDGPU`, [follow this](https://wiki.archlinux.org/title/AMDGPU#Tear_free_rendering). Some may argue that it highers the input lag, I think that it's theoretically right and we want the lowest felt input lag. But with high refresh rate monitors, (e.g. 240Hz), I think image update smoothness is way more noticeable than the added input lag. This option entirely removes screen tearing with anything: for example scrolling on Firefox, on compositor-less DEs like LXDE, becomes super smooth.
- If you have a FreeSync/Gsync monitor and a GPU that supports it, [follow this documentation](https://wiki.archlinux.org/title/Variable_refresh_rate) on how to enable it on Linux. Reviews of monitors seem to show that enabling this actually adds input lag, but once again, it's better than tearing.

## Performance overlays

Performance overlays are small "widgets" that stack on top of your game view and show performance statistics (framerate, temperatures, frame times, CPU/RAM usages... etc). Two possibilities:

* MangoHud: It is available in the repositories of most linux distros, to activate it, you only need to add the environment variable `MANGOHUD=1`, and the stats you want to see in `MANGOHUD_CONFIG`. The interesting part of MangoHud is that it can also bechmark games: Record the entirety of the frame times, calculate frametime percentiles...etc Ideal to do benchmarks with. More information here: https://github.com/flightlessmango/MangoHud. It can be configured via a GUI with GOverlay - https://github.com/benjamimgois/goverlay
* DXVK has its own HUD and can be enabled by setting the variable `DXVK_HUD`, the possible values are explained in [its repository](https://github.com/doitsujin/dxvk)

## Streaming - Saving replays

### OBS

[OBS](https://obsproject.com/) is the famous open source streaming software: it helps streaming and recording your games, desktop, audio input/output, webcams, IP cameras... etc.

**An important fix for an issue I have been having for a year now**
- __Network Error on Twitch:__ Switching between sources that leave a black screen for a very short time, _e.g._ having the game in a virtual desktop then switching to another virtual desktop, makes the stream on twitch crash for whatever reason. To work around this, keep a background image behind all of your sources, so whenever nothing is supposed to be shown, it's that background image instead of a black background.

#### Desktop environments

It works nicely with X11 on AMD GPUs, especially LXDE/LXQt (when compared to Gnome) with respect to the added input lag.

##### Gnome

On Gnome, an experimental feature can be enabled:
```shell
gsettings set org.gnome.mutter experimental-features '["dma-buf-screen-sharing"]'
```
That will enable window capturing through the ["dma-buf" sharing protocol](https://elinux.org/images/a/a8/DMA_Buffer_Sharing-_An_Introduction.pdf). Which enables `OBS` to work on Wayland but also not add as much input lag is with its `Xcomposite` backend. This feature can only be used by `obs-studio` version `27.0` onwards. If your distro doesn't provide that version, it can be installed via `flatpak`
```shell
flatpak install --user https://flathub.org/beta-repo/appstream/com.obsproject.Studio.flatpakref
```
On Gnome under X11, you need to run OBS with an extra environment variable, `OBS_USE_EGL=1`:
```shell
OBS_USE_EGL=1 com.obsproject.Studio
```
where `com.obsproject.Studio` is the name of the `obs-studio` executable, installed through flatpak, it may have another name in your specific distro.

#### Encoders

With AMD GPUs, one can use `ffmpeg-vaapi` to leverage the GPU for encoding, which is offered out of the box. `ffmpeg-amf` contains additions from AMD's [AMF](https://github.com/GPUOpen-LibrariesAndSDKs/AMF) library, but [it needs some work](https://www.reddit.com/r/linux_gaming/comments/qwqxwd/how_to_enable_amd_amf_encoding_in_obs/) (I am working on streamlining all of this on Gentoo). Nvidia has been reported to work nicely on linux and on windows with their new `nvenc` encoder.

To compare between encoders with your particular game, you can record a short lossless video `lossless.avi` (the one I made is  [this one](https://github.com/AdelKS/LinuxGamingGuide/raw/master/videos/lossless.avi)) using this option on `obs`

![obs lossless recording setting](./images/obs-lossless-recording.png)

Then, you can transcode it, for example using `ffmpeg-vaapi` with the settings you want to use for streaming:

```shell
ffmpeg -i 'lossless.avi' -vcodec h264_vaapi -profile:v main -level 5.2 -vf 'format=nv12,hwupload' -vaapi_device '/dev/dri/renderD128' -b:v 4500000  'vaapi.mkv'
```

in this case `Main@5.2` at `4500kbps` (I obtain  [this video](./video/vaapi.mkv)). We can do the same with `ffmpeg-amf` (after getting it properly installed)

```shell
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/amd_pro_icd64.json ffmpeg -i 'lossless.avi' -vcodec h264_amf -profile:v main -level 5.2 -quality quality -b:v 4500000  'amf.mkv'
```

which in this case is `Main@5.2` (`High` doesn't seem to work) at `4500kbps` (I obtain  [this video](./video/amf.mkv)). Then, we can compare between both by using [Netflix's VMAF](https://github.com/Netflix/vmaf/) scoring for each encoded file:

```shell
➜ ffmpeg -i 'vaapi.mkv' -i 'lossless.avi' -filter_complex libvmaf -f null -

[... cropped output ...]

VMAF score: 73.419031

➜ ffmpeg -i 'amf.mkv' -i 'lossless.avi' -filter_complex libvmaf -f null -

[... cropped output ...]

VMAF score: 80.747651
```

This shows that `amf` gets me better quality videos thant `vaapi` on my `RDNA1` `RX 5700 XT` GPU. You can try for yourself using [the lossless video I used](./video/lossless.avi) and convert it with your encoder: I would love to know how much better nvidia's `nvenc` is, at the same `4.5mbps` bitrate; and also Intel's, issues/PRs welcome!

Notes:
- To know the details on how a video file `video.mkv` is encoded, you can use the `mediainfo` command (needs installing the related package): `mediainfo video.mkv`.
- To know the options offered by your encoder within `ffmpeg` you can write the following: `ffmpeg -h encoder=h264_amf`, where you replace `h264_amf` with the name of the encoder you want, that `ffmpeg` supports.
- The `'format=nv12,hwupload'` is due to `vaapi` not being able to handle the input color format and a translation is done on the CPU, and apparently this is done when using `ffmpeg-vaapi` for streaming on `obs`, when compared to `ffmpeg-amf`.
- The `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/amd_pro_icd64.json` at the beginning of the `AMF` transcoding overrides the vulkan driver with AMD's closed source one from their PRO series driver. The name `amd_pro_icd64.json` depends on the distro but the path should remain the same.
- `VAAPI`'s performance of mesa can be improved on `RDNA` (`RX 5000` series) and `RDNA2` (`RX 6000` series) by compiling your own mesa package (you will have to figure that out by yourself...) with [this patch](./patches/cabac-enable.patch): it enables the so called [CABAC](https://en.wikipedia.org/wiki/Context-adaptive_binary_arithmetic_coding) encoding method which improves the quality of videos at same bitrate (older AMD GPUs already have it enabled). For example I get this `VMAF` score with the patched `mesa` package, that gives out [this video file](./videos/vaapi-cabac.mkv) and this better `VMAF` score
  ```shell
  ➜ ffmpeg -i 'vaapi-cabac.mkv' -i 'lossless.avi' -filter_complex libvmaf -f null -

  [... cropped output ...]

  VMAF score: 77.724074
  ```


#### Using `cpuset` with software encoder on Ryzen CPUs

If you can't use your own GPU for encoding or prefer to use a software encoder, it's a very good idea to use the `cpuset` trick explained above to not affect your game's performance by running OBS in a different CCX/CCD. I benchmarked it and it makes a huge difference.
#### obs-vkcapture

[obs-vkcapture](https://github.com/nowrep/obs-vkcapture) implements the ["dma-buf" sharing protocol](https://elinux.org/images/a/a8/DMA_Buffer_Sharing-_An_Introduction.pdf) for capturing games: it needs the version `27.0` of `obs-studio`, or newer, to be installed in the regular way because it needs headers from it (it must be possible to use the flatpak version too but I don't know how). If your distro doesn't ship that version of `obs-studio`, you can compile from source ([documentation here](https://github.com/obsproject/obs-studio/wiki/Install-Instructions#linux-build-directions)).

Once you have a working `obs-studio` version `27.0` or higher, you need to compile `obs-vkcapture` form source then install it : documentation is in its [Github page](https://github.com/nowrep/obs-vkcapture) (it's also on the `AUR` on Arch, and in `GURU` on Gentoo). After that, you need to run `obs-studio` with the environment variable, `OBS_USE_EGL=1`:
```shell
OBS_USE_EGL=1 obs
```
And you will see a `game capture` as a new source entry. It works great and fixed my issues with added input lag and stuttering `obs-studio` used to have with `Xcomposite` sources. Games need to run with the environment variable `OBS_VKCAPTURE=1` or need to be run with the command `obs-vkcapture wine yourgame` (the command gets installed when installing `obs-vkcapture`).

### Replay sorcery

[Replay sorcery](https://github.com/matanui159/ReplaySorcery) is a tool to save small replays of your gaming sessions, without the need to be streaming. It saves a "video" of your play for the past `x` seconds in RAM: it is saved as sequence of JPEG images (small footprint on the computer's resources). And these images are only converted to a video when you want to actually save a replay (more resource heavy). I haven't given it a try, if you want to add hints and tips about it, please feel free to PR something or open an issue!

## Sound tweaks with Pipewire/Pulseaudio

This section is about some tweaks one can do with [Pulseaudio](https://www.freedesktop.org/wiki/Software/PulseAudio/) or [Pipewire](https://pipewire.org/) (will replace Pulseaudio and offers more features).
### Stream only the game sounds

You are in a Discord call and streaming at the same time, but you only want OBS to stream the game's sounds ? Search no more. The solution is here (that I found [here](https://unix.stackexchange.com/questions/384220/how-to-create-a-virtual-audio-output-and-route-it-in-ubuntu-based-distro)): the idea is to create some kind of virtual soundcard, let's call it `Game-Sink`, where the game will output it sound on. Then you redirect the sound from `Game-Sink` to your actual soundcard.

Create `Game-Sink`:
```shell
pactl load-module module-null-sink sink_name=game_sink sink_properties=device.description=Game-Sink
```
Find the actual name of `$OriginalSoundcard`: you do this command and look at its output, you should recognize your card's name there:
```shell
pactl list sinks | grep name:
```
For example, for me I have a SteelSeries Arctis PRO with the Game DAC (with cable), the name of my card is `alsa_output.usb-SteelSeries_SteelSeries_GameDAC_000000000000-00.iec958-stereo`. So here's how you do the loopback from `Game-Sink`:
```shell
pactl load-module module-loopback source="game_sink.monitor" sink="alsa_output.usb-SteelSeries_SteelSeries_GameDAC_000000000000-00.iec958-stereo" source_output_properties="stream.capture.sink=1"
```
Then, all what's left is to do is to open `pavucontrol` (google how to install it if you don't have it) and select `Game-Sink` for where `obs-studio` picks its audio from. And select `Game-Sink` for where the game outputs its audio to.

### Improve the sound of your headset

There is a nice Github repository, called [AutoEq](https://github.com/jaakkopasanen/AutoEq), that references the frequency responses of various headsets that have been reviewed by websites like [rtings.com](rtings.com) and others. The frequency responses are made available as `.wav` files in that repository.

A headset with high fidelity should have a flat frequency response, but affordable/real life headsets do not exhibit a flat one. What one can do with those `.wav` files is to use them and correct what is fed to the headset with software and improve the perceived sound. Although, one must know that the frequency response of one's own headset is for sure different from the ones available in [AutoEq](https://github.com/jaakkopasanen/AutoEq). But it may still improve one's audio experience if, let's say, all the headsets from your specific model have a similar frequency response.

#### The Graphical way

Install `easyeffects` (`pulseeffects-legacy-git` for `Pulseaudio` from the AUR if on Archlinux) and enable the "Convolver" plugin for your ouput sound:

![PulseEffects mic noise suppression](./images/headset-auto-eq-gui.png)

You need to download the corresponding `.wav` file to your headset, from the [AutoEq](https://github.com/jaakkopasanen/AutoEq) github repository. For example the files related to my headset are [these ones](https://github.com/jaakkopasanen/AutoEq/tree/master/results/rtings/rtings_harman_over-ear_2018/SteelSeries%20Arctis%20Pro%20GameDAC). There's a 44.1kHz and a 48kHz version for those `.wav` files. Pick the highest frequency your soundcard can handle, or just try both if you are too lazy to figure that out haha.

*Note:* the `easyeffects` app must remain open for this to keep on working, except if you enable the "start as a service on login" menu option then log out and back in.
### Mic noise suppression

You have cherry blue mechanical keyboard, your friends and teammates keep on complaining/sending death threats about you being too noisy with your keyboard ? Fear no more.

**A bit of history:** People from Mozilla made some research to apply neural networks to noise suppression from audio feeds, they [published](https://jmvalin.ca/demo/rnnoise/) everything about it, including the code. Another person, "Werman", picked up their work and made it work as a [PulseAudio plugin](https://github.com/werman/noise-suppression-for-voice).

#### The Graphical way

* If you are using Pipewire, install [easyeffects](https://github.com/wwmm/easyeffects), it probably is in your distro's repositories.
* If you are still on Pulseaudio, you can install a "legacy" version of `easyeffects`, called [pulseffects-legacy](https://github.com/wwmm/easyeffects/tree/pulseaudio-legacy). It may be available in your distro's repositories (e.g. `pulseeffects-legacy-git` from the AUR, on Archlinux) or you need to build it from source.

Enable the "Noise Reduction" plugin for your mic:

![PulseEffects mic noise suppression](./images/mic-noise-suppression-gui.png)

*Note:* the `easyeffects` app must remain open for this to keep on working, except if you enable the "start as a service on login" menu option then log out and back in.
#### The command line way

All this is explained in [Werman's Git repository](https://github.com/werman/noise-suppression-for-voice). I will put it back here. It works for both Pipewire and Pulseaudio

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

pactl load-module module-null-sink sink_name="denoised_mic_stereo" sink_properties="device.description=Denoised-Mic-Stereo" rate="48000"

pactl load-module module-ladspa-sink sink_name=denoiser_stereo sink_properties="device.description=Denoiser-Stereo" sink_master="denoised_mic_stereo" label="noise_suppressor_stereo" plugin="librnnoise_ladspa" control="50"

pactl load-module module-loopback source="alsa_input.usb-SteelSeries_SteelSeries_GameDAC_000000000000-00.multichannel-input" sink="denoiser_stereo" channels="2" source_dont_move="true" sink_dont_move="true" source_output_properties="stream.capture.sink=1"
```

For mono mics
```shell
#!/bin/bash

pactl load-module module-null-sink sink_name="denoised_mic_mono" sink_properties="device.description=Denoised-Mic-Mono" rate="48000"

pactl load-module module-ladspa-sink sink_name="denoiser_mono" sink_properties="device.description=Denoiser-Mono" sink_master="denoised_mic_mono" label="noise_suppressor_mono" plugin="librnnoise_ladspa" control="50"

pactl load-module module-loopback source="alsa_input.usb-SteelSeries_SteelSeries_GameDAC_000000000000-00.multichannel-input" sink="denoiser_mono" channels="1" source_dont_move="true" sink_dont_move="true" source_output_properties="stream.capture.sink=1"
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
- Compiler optimizations: Wine, DXVK, Kernel, Mesa.


## Misc
* There is very nice documentation on the [Archlinux wiki about improving performance](https://wiki.archlinux.org/index.php/Improving_performance)
* Firefox on Wayland with high refresh rate monitors: [smooth scrolling](https://www.reddit.com/r/linux/comments/l1re17/psa_by_default_firefox_on_linux_doesnt_match_with/)
* [Another github repository](https://github.com/LinuxCafeFederation/awesome-gnu-linux-gaming) that references nice tools for gaming.
* Background YT videos: If you have youtube music in the background, try to switch to an empty tab and not leave the tab on the video. I noticed that like this the video doesn't get rendered and helps freeing your GPU or CPU (depending on who is doing the decoding).
* KDE file indexer : If you're using KDE, you may consider disabling the file indexer. This is either done in the KDE settings or with `balooctl disable` (requires a reboot).
