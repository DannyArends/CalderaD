import bindbc.sdl;

@nogc void toStdout(A...)(const string fmt, auto ref A args) nothrow {
  SDL_Log(fmt.ptr, args);
}

