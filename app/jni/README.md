### SDL Folder

Download and extract the SDL2 source zip-files: 
- [SDL2](https://www.libsdl.org/download-2.0.php), 
- [SDL2_image](https://www.libsdl.org/projects/SDL_image/), 
- [SDL_net](https://www.libsdl.org/projects/SDL_net/), 
- [SDL_ttf](https://www.libsdl.org/projects/SDL_ttf/), 
- [SDL_mixer](https://www.libsdl.org/projects/SDL_mixer/)

Create symlinks (e.g. using mklink for windows, or ln -s in linux) into 
this folder and link to the extracted SDL source packages. 
Change PATHTO to where your cloned CalderaD, and PATHSDL to where the 
downloaded the SDL libraries are:

```
mklink /d "PATHTO\CalderaD\app\jni\SDL" "PATHSDL\SDL2-2.0.14"
mklink /d "PATHTO\CalderaD\app\jni\SDL2_image" "PATHSDL\SDL2_image-2.0.5"
mklink /d "PATHTO\CalderaD\app\jni\SDL2_net" "PATHSDL\SDL2_net-2.0.1"
mklink /d "PATHTO\CalderaD\app\jni\SDL2_ttf" "PATHSDL\SDL2_ttf-2.0.15"
mklink /d "PATHTO\CalderaD\app\jni\SDL2_mixer" "PATHSDL\SDL2_mixer-2.0.4"
```
