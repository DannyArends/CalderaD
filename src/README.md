CalderaD source code highlights

- [src/main.d](./main.d) contains the main entry function, and SDL event loop
- [src/sdl.d](./sdl.d) loads and inititalizes the SDL library, creates a window
- [src/vulkan.d](./vulkan.d) deals with initializing Vulkan, and swapchain re-creation
- [src/application.d](./application.d) CalderaD application structure, and structure cleanup() function
- [src/physicaldevice.d](./physicaldevice.d) the physical device setup used by Vulkan
- [src/render.d](./render.d) Vulkan render function for graphics output
- [src/log.d](./log.d) OS agnostic layer for stdout
- [src/io.d](./io.d) OS agnostic layer for I/O

All code files here originally started as a rough translation of the [vulkan-tutorial](https://vulkan-tutorial.com/), 
an excelent tutorial to learn how Vulkan works.
