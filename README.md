An SDL/Vulkan renderer for windows/linux/android in the D Programming Language (based on vulkan-tutorial.com)

## Compiling for windows
Install the [DMD compiler](https://dlang.org/download.html) for your OS, and compile the project:

```
    git clone https://github.com/DannyArends/VulcanoD.git
    cd VulcanoD
    dub
```

Make sure the glslc compiler (glslc.exe) is available to build the vertex and fragment shaders in app\src\main\assets\data\shaders.
The glslc compiler is included in the [LunarG Vulkan SDK](https://vulkan.lunarg.com/), as well as in the SDK provided by 
[Android Studio](https://developer.android.com/studio):

```
    cd VulcanoD
    glslc.exe app/src/main/assets/data/shaders/tiangle.vert -o app/src/main/assets/data/shaders/vert.spv
    glslc.exe app/src/main/assets/data/shaders/tiangle.frag -o app/src/main/assets/data/shaders/frag.spv
    dub
```

## Compiling for linux
For Linux a working [D compiler](https://dlang.org/download.html) (DMD, LDC2, GDC), and DUB package manager are required as well as the following 
dependencies (and corresponding -dev packages):

 * [SDL2](https://www.libsdl.org/)
 * [SDL2_image](https://www.libsdl.org/projects/SDL_image/)
 * [SDL_mixer](https://www.libsdl.org/projects/SDL_mixer/)
 * [SDL_net](https://www.libsdl.org/projects/SDL_net/)
 * [SDL_ttf](https://www.libsdl.org/projects/SDL_ttf/)

These can often be installed by using the build-in package manager such as apt.

## Compiling Android version

On android we need VulcanoD and a fix for Android relating to the loading SDL2 on Android using the bindbc-sdl library:

```
    git clone https://github.com/DannyArends/VulcanoD.git
    git clone https://github.com/DannyArends/bindbc-sdl.git
```

###  Install Android studio and prepare SDL
Download [Andriod Studio](https://developer.android.com/studio), and install it.

###  Install ldc and the android library

1) Install the [LDC compiler](https://dlang.org/download.html), install for your OS

2) Download, and extract the LDC aarch64 library for Android:
https://github.com/ldc-developers/ldc/releases/download/v1.23.0/ldc2-1.23.0-android-aarch64.tar.xz

Open the file PATHTOLDC/ldc-1.23.0/etc/ldc2.conf, where PATHTOLDC is where you installed LDC in step 1. 

To this file add the aarch64 compile target, make sure to change PATHTOSDK to the path of the Android Studio SDK&NDK, and to 
change the PATHTOLDCLIB to the path of the LDC aarch64 library (step 2):

```Gradle
"aarch64-.*-linux-android":
{
    switches = [
        "-defaultlib=phobos2-ldc,druntime-ldc",
        "-link-defaultlib-shared=false",
        "-gcc=PATHTOSDK/Android/Sdk/ndk/21.3.6528147/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang",
    ];
    lib-dirs = [
        "<PATHTOLDCLIB>/ldc2-1.23.0-android-aarch64/lib",
    ];
    rpath = "";
};
```

###  Install Android studio and prepare SDL
Download [Andriod Studio](https://developer.android.com/studio), and install it.

Download and extract the SDL2 source zip-files:
[SDL2](https://www.libsdl.org/download-2.0.php), 
[SDL2_image](https://www.libsdl.org/projects/SDL_image/), 
[SDL_net](https://www.libsdl.org/projects/SDL_net/), 
[SDL_ttf](https://www.libsdl.org/projects/SDL_ttf/), 
[SDL_mixer](https://www.libsdl.org/projects/SDL_mixer/), and extract them.

Create symlinks (e.g. using mklink for windows, or ln -s in linux) in tot VulcanoD\app\jni folder and 
link to the extracted SDL source packages. Change PATHTO to where your cloned VulcanoD, and PATHSDL to 
where your downloaded the SDL libraries:

```
mklink /d "PATHTO\VulcanoD\app\jni\SDL" "PATHSDL\SDL2-2.0.14"
mklink /d "PATHTO\VulcanoD\app\jni\SDL2_image" "PATHSDL\SDL2_image-2.0.5"
mklink /d "PATHTO\VulcanoD\app\jni\SDL2_net" "PATHSDL\SDL2_net-2.0.1"
mklink /d "PATHTO\VulcanoD\app\jni\SDL2_ttf" "PATHSDL\SDL2_ttf-2.0.15"
mklink /d "PATHTO\VulcanoD\app\jni\SDL2_mixer" "PATHSDL\SDL2_mixer-2.0.4"
```

### Compiling the D source code (Android version)

Compile the VulcanoD android aarch64 library with dub:

```
cd VulcanoD
dub --compiler=ldc2 --arch=aarch64-*-linux-android --config=android-64
```
this will produce a libmain.so in app/src/main/jniLibs/arm64-v8a

### Build APK, and run on Android

Open up the VulcanoD project in Android Studio, and build/run the APK