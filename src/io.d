// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import std.conv;
import std.string;
import std.path : globMatch;
import std.file : SpanMode;

import calderad, buffer, wavefront;

version(Android) { 
  import arsd.jni;

  // SDL does not provide the ability to scan folders, and on android we need to use the jni
  // dir() is the wrapper function provided
  string[] dir(string path, string pattern = "*", bool shallow = true) { return(listDirContent(path, pattern, shallow)); }

  // listDirContent uses SDL to get jni the environment, and obtain a link to the asset_manager via jni calls
  string[] listDirContent(string path = "", string pattern = "*", bool shallow = true, bool verbose = false) {
    JNIEnv* env = cast(JNIEnv*)SDL_AndroidGetJNIEnv();
    jobject activity = cast(jobject)SDL_AndroidGetActivity();
    jclass activity_class = (*env).GetObjectClass(env, activity);
    jobject asset_manager = (*env).CallObjectMethod(env, activity, (*env).GetMethodID(env, activity_class, "getAssets", "()Landroid/content/res/AssetManager;"));

    // Query the asset_manager for the list() method
    auto list_method = (*env).GetMethodID(env, (*env).GetObjectClass(env, asset_manager), "list", "(Ljava/lang/String;)[Ljava/lang/String;");
    jstring path_object = (*env).NewStringUTF(env, toStringz(path));
    auto files_object = cast(jobjectArray)(*env).CallObjectMethod(env, asset_manager, list_method, path_object);
    auto length = (*env).GetArrayLength(env, files_object);

    // List all files in the folder
    toStdout("Path %s, mngr: %X, list_method: %X, nObjects: %d \n", toStringz(path), asset_manager, list_method, length);
    string[] files;
    for (int i = 0; i < length; i++) {
      // Allocate the java string, and get the filename
      jstring jstr = cast(jstring)(*env).GetObjectArrayElement(env, files_object, i);
      const(char)* fn = (*env).GetStringUTFChars(env, jstr, null);
      if (fn) {
        string filename = to!string(fn);
        string filepath =  (path ~ (path[($-1)] == '/' ? "" : "/") ~ filename);
        if (globMatch(filepath, pattern)) { 
          toStdout("matching file: %s @ %s", toStringz(filename), toStringz(filepath));
          files ~= filepath;
        }
        if (!shallow && isDir(filepath)) files ~= listDirContent(filepath, pattern, shallow, verbose);
      }
      (*env).DeleteLocalRef(env, jstr); // De-Allocate the java string
    }
    (*env).DeleteLocalRef(env, asset_manager);
    (*env).DeleteLocalRef(env, activity_class);
    return(files);
  }

  // We shim ontop of our listDir some functions on Android
  bool isDir(string path){ return(dirExists(path)); }
  bool dirExists(string path){ return(listDirContent(path).length > 0); }

  // isFile uses SDL on Android
  bool isFile (string path) {
    SDL_RWops *rw = SDL_RWFromFile(toStringz(path), "rb");
    if (rw == null) return false;
    SDL_RWclose(rw);
    return true;
  }

  bool exists (string path) { return(isFile(path) | dirExists(path)); }

}else{ // Version SDL/OS, just use D to get the dir() functionality

  public import std.file : dirEntries;
  import std.algorithm : map, filter;

  string[] dir(string path, string pattern = "*", bool shallow = true) { 
    auto mode = SpanMode.shallow;
    if(!shallow) mode = SpanMode.depth;
    return(dirEntries(path, pattern, mode).filter!(a => a.isFile).map!(a => a.name).array);
  }

}

/* Load a file using SDL2 */
uint[] readFile(string path) {
  SDL_RWops *rw = SDL_RWFromFile(toStringz(path), "rb");
  if (rw == null){
    toStdout("readFile: couldn't open file '%s'\n", toStringz(path));
    return [];
  }
  uint[] res;

  res.length = cast(size_t)SDL_RWsize(rw);
  size_t nb_read_total = 0, nb_read = 1;
  uint* cpos = &res[0];
  while (nb_read_total < res.length && nb_read != 0) {
    nb_read = SDL_RWread(rw, cpos, 1, cast(size_t)(res.length - nb_read_total));
    nb_read_total += nb_read;
    cpos += nb_read;
  }
  SDL_RWclose(rw);
  if (nb_read_total != res.length) toStdout("readFile: loaded %db, expected %db\n", nb_read_total, res.length);
  toStdout("Loaded %d bytes\n", nb_read_total);
  return res;
}
