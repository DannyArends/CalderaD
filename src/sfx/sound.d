// Copyright Danny Arends 2021
// Distributed under the GNU General Public License, Version 3
// See accompanying file LICENSE.txt or copy at https://www.gnu.org/licenses/gpl-3.0.en.html

import calderad, io;

// WAV format sound effects
struct WavFMT {
  string path;
  Mix_Chunk* chunk;
  float pitch = 1.0;
  float gain = 0.5;
  bool loaded = false;
  bool looping = false;
}

// Print out info on the audio device and it's capabilities
@nogc void printSoundDecoders() nothrow {
  int nChunk = Mix_GetNumChunkDecoders();
  int nMusic = Mix_GetNumMusicDecoders();

  toStdout("Decoders (chunk):");
  for(int i =  0; i < nChunk; ++i){ toStdout(" %s", Mix_GetChunkDecoder(i)); }
  toStdout("Decoders (music):");
  for(int i = 0; i < nMusic; ++i){ toStdout(" %s", Mix_GetMusicDecoder(i)); }

  int bits, sample_size, rate, audio_rate,audio_channels;
  Uint16 audio_format;
  Mix_QuerySpec(&audio_rate, &audio_format, &audio_channels);
  bits = audio_format & 0xFF;
  sample_size = bits/8+audio_channels;
  rate = audio_rate;
  toStdout("Audio @ %d Hz %d bit %s, %d bytes audio buffer\n", audio_rate, bits, audio_channels>1?"stereo".ptr:"mono".ptr, 1024 );
}

// Load a WAV formatted file
WavFMT loadWav(string path, float pitch = 1.0, float gain = 0.5, bool looping = false) {
  WavFMT sfx = { path: path, 
                 chunk: Mix_LoadWAV(toStringz(path)),
                 pitch: pitch, gain: gain, loaded: false, looping: looping
                };
  if (!sfx.chunk) {
    toStdout("Unable to create buffer for '%s' cause '%s'\n", toStringz(path), Mix_GetError());
    return sfx;
  }
  sfx.loaded = true;
  Mix_VolumeChunk(sfx.chunk, cast(int)(sfx.gain * MIX_MAX_VOLUME));
  return(sfx);
}

// Load all CasualGameSounds WAV sound effects
void loadAllSoundEffect(ref App app, string path = "data/sounds/CasualGameSounds", float pitch = 1.0, float gain = 0.5, bool looping = false, bool play = false) {
  version(Android){ }else{ //version(SDL)
    path = "app/src/main/assets/" ~ path;
  }
  printSoundDecoders();
  auto files = dir(path, "*.wav");
  foreach(file; files) { // toStdout("loading: %s", toStringz(file));
    WavFMT sfx = loadWav(file, pitch, gain, looping);
    if(play) app.play(sfx);
    app.soundfx ~= sfx;
  }
  toStdout("Loaded %d sounds effects from: %s", app.soundfx.length, toStringz(path));
}

// Play a sound effect
@nogc int play(FMT)(ref App app, FMT sfx) { 
  if(!sfx.loaded) return(-1);
  Mix_VolumeChunk(sfx.chunk, cast(int)(sfx.gain * app.soundEffectGain * MIX_MAX_VOLUME));
  return(Mix_PlayChannel(-1, cast(Mix_Chunk*)(sfx.chunk), 0));
}
