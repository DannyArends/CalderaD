CalderaD source code highlights

- [src/main.d](./main.d) main entry function, and SDL loop
- [src/sdl.d](./sdl.d) load and inititalize the SDL library
- [src/vulkan.d](./vulkan.d) inititalize Vulkan, and recreate the swapchain
- [src/application.d](./application.d) CalderaD application structure, and cleanup() function
- [src/render.d](./render.d) Vulkan render function for graphics output
- [src/log.d](./log.d) OS agnostic layer for stdout
- [src/io.d](./io.d) OS agnostic layer for I/O

All code files here originally started as a rough translation of the [vulkan-tutorial](https://vulkan-tutorial.com/), 
an excelent tutorial how Vulkan works.
