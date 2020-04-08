// Emacs style mode select   -*- C++ -*- 
//-----------------------------------------------------------------------------
//
// $Id:$
//
// Copyright (C) 1993-1996 by id Software, Inc.
//
// This source is available for distribution and/or modification
// only under the terms of the DOOM Source Code License as
// published by id Software. All rights reserved.
//
// The source is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// FITNESS FOR A PARTICULAR PURPOSE. See the DOOM Source Code License
// for more details.
//
// $Log:$
//
// DESCRIPTION:
//	System interface for sound.
//
//-----------------------------------------------------------------------------

#include <stdio.h>

#include <sys/time.h>

#include <signal.h>

#include "z_zone.h"

#include "i_sound.h"
#include "w_wad.h"

#include "doomdef.h"

@import AudioToolbox;

#define SAMPLERATE		    11025	// Hz
#define DMX_HEADER_SIZE     8
#define DMX_PADDING_SIZE    16

// The actual lengths of all sound effects.
int 		lengths[NUMSFX];

AudioQueueRef* queues;
AudioQueueBufferRef** buffers;

void MyAudioQueueOutputCallback(
        void* inUserData,
        AudioQueueRef inAQ,
        AudioQueueBufferRef inBuffer)
{
    printf("AudioQueueOutputCallback");
}

//
// This function loads the sound data from the WAD lump,
//  for single sound.
//
void*
getsfx
( char*         sfxname,
  int*          len )
{
    // Get the sound data from the WAD, allocate lump
    //  in zone memory.
    char name[20];
    sprintf(name, "ds%s", sfxname);

    // Now, there is a severe problem with the
    //  sound handling, in it is not (yet/anymore)
    //  gamemode aware. That means, sounds from
    //  DOOM II will be requested even with DOOM
    //  shareware.
    // The sound list is wired into sounds.c,
    //  which sets the external variable.
    // I do not do runtime patches to that
    //  variable. Instead, we will use a
    //  default sound for replacement.
    int sfxlump;
    if ( W_CheckNumForName(name) == -1 )
      sfxlump = W_GetNumForName("dspistol");
    else
      sfxlump = W_GetNumForName(name);
    
    int size = W_LumpLength( sfxlump );

    unsigned char* sfx = (unsigned char*)W_CacheLumpNum( sfxlump, PU_STATIC );

    *len = size - DMX_HEADER_SIZE - DMX_PADDING_SIZE - DMX_PADDING_SIZE;

    // Return allocated padded data.
    return (void *) (sfx + DMX_HEADER_SIZE + DMX_PADDING_SIZE);
}

void I_SetChannels(int numChannels)
{
    queues = Z_Malloc((int)sizeof(AudioQueueRef) * numChannels, PU_STATIC, NULL);
    buffers = Z_Malloc((int)sizeof(AudioQueueBufferRef*) * numChannels, PU_STATIC, NULL);

    for (int i = 0; i < numChannels; ++i)
    {
        AudioStreamBasicDescription inFormat = {0};
        inFormat.mBitsPerChannel = 8;
        inFormat.mBytesPerFrame = 1;
        inFormat.mBytesPerPacket = 1;
        inFormat.mChannelsPerFrame = 1;
        inFormat.mFormatFlags = 0;
        inFormat.mFormatID = kAudioFormatLinearPCM;
        inFormat.mFramesPerPacket = 1;
        inFormat.mReserved = 0;
        inFormat.mSampleRate = SAMPLERATE;
        OSStatus s = AudioQueueNewOutput(
                &inFormat,
                MyAudioQueueOutputCallback,
                NULL,
                NULL,
                NULL,
                0,
                &queues[i]);
        assert(s == 0);

        buffers[i] = Z_Malloc(sizeof(AudioQueueBufferRef) * NUMSFX, PU_STATIC, NULL);
        for (int j = 1; j < NUMSFX; ++j)
        {
            OSStatus status = AudioQueueAllocateBuffer(queues[i], lengths[j], &buffers[i][j]);
            assert(status == 0);

            buffers[i][j]->mAudioDataByteSize = buffers[i][j]->mAudioDataBytesCapacity;
            memcpy(buffers[i][j]->mAudioData, S_sfx[j].data, buffers[i][j]->mAudioDataByteSize);
        }
    }
}

// MUSIC API - dummy. Some code from DOS version.
void I_SetMusicVolume(int volume)
{
  // Internal state variable.
  snd_MusicVolume = volume;
  // Now set volume on output device.
  // Whatever( snd_MusicVolume );
}

//
// Retrieve the raw data lump index
//  for a given SFX name.
//
int I_GetSfxLumpNum(sfxinfo_t* sfx)
{
    char namebuf[9];
    sprintf(namebuf, "ds%s", sfx->name);
    return W_GetNumForName(namebuf);
}

int
I_StartSound
(
  int       handle,
  int		id,
  int		vol,
  int		sep,
  int		pitch,
  int		priority )
{
    OSStatus s = AudioQueueEnqueueBuffer(queues[handle], buffers[handle][id], 0, NULL);
    if (s != 0)
    {
        fprintf(stderr, "Error enqueuing buffer: [%d] on channel: [%d]", s, handle);
    }

    s = AudioQueueStart(queues[handle], NULL);
    assert(s == 0);


    // UNUSED
    priority = 0;

    // Debug.
    fprintf( stderr, "I_StartSound id: [%d] on channel: [%d]\n", id, handle );

    return handle;
}

void I_StopSound (int handle)
{
    fprintf( stderr, "I_StopSound handle: [%d]\n", handle );

    OSStatus s = AudioQueueStop(queues[handle], 1);
    assert(s == 0);

    // UNUSED.
    handle = 0;
}

int I_SoundIsPlaying(int handle)
{
    UInt32 isRunning;
    UInt32 size = sizeof(isRunning);
    AudioQueueGetProperty(queues[handle], kAudioQueueProperty_IsRunning, &isRunning, &size);

    fprintf( stderr, "I_SoundIsPlaying handle: [%d], is playing: [%d]\n", handle, isRunning);

    return (isRunning != 0);
}

void I_UpdateSound( void )
{
    // TODO Delete?
}

void I_SubmitSound(void)
{
    // TODO Delete?
}

void I_UpdateSoundParams
( int	handle,
  int	vol,
  int	sep,
  int	pitch)
{
    // TODO
}

void I_ShutdownSound(void)
{
  // TODO Wait till all pending sounds are finished.
}

void
I_InitSound()
{
  // Secure and configure sound device first.
  fprintf( stderr, "I_InitSound: ");

  fprintf(stderr, " configured audio device\n" );

  // Initialize external data (all sounds) at start, keep static.
  fprintf( stderr, "I_InitSound: ");
  
  for (int i=1 ; i<NUMSFX ; i++)
  { 
    // Alias? Example is the chaingun sound linked to pistol.
    if (!S_sfx[i].link)
    {
      // Load data from WAD file.
      S_sfx[i].data = getsfx( S_sfx[i].name, &lengths[i] );
    }	
    else
    {
      // Previously loaded already?
      S_sfx[i].data = S_sfx[i].link->data;
      lengths[i] = lengths[(S_sfx[i].link - S_sfx)/sizeof(sfxinfo_t)];
    }
  }

  fprintf( stderr, " pre-cached all sound data\n");

  // Finished initialization.
  fprintf(stderr, "I_InitSound: sound module ready\n");
}

//
// MUSIC API.
// Still no music done.
// Remains. Dummies.
//
void I_InitMusic(void)		{ }
void I_ShutdownMusic(void)	{ }

static int	looping=0;
static int	musicdies=-1;

void I_PlaySong(int handle, int looping)
{
  // UNUSED.
  handle = looping = 0;
  musicdies = gametic + TICRATE*30;
}

void I_PauseSong (int handle)
{
  // UNUSED.
  handle = 0;
}

void I_ResumeSong (int handle)
{
  // UNUSED.
  handle = 0;
}

void I_StopSong(int handle)
{
  // UNUSED.
  handle = 0;
  
  looping = 0;
  musicdies = 0;
}

void I_UnRegisterSong(int handle)
{
  // UNUSED.
  handle = 0;
}

int I_RegisterSong(void* data)
{
  // UNUSED.
  data = NULL;
  
  return 1;
}

// Is the song playing?
int I_QrySongPlaying(int handle)
{
  // UNUSED.
  handle = 0;
  return looping || musicdies > gametic;
}

// We might use SIGVTALRM and ITIMER_VIRTUAL, if the process
//  time independend timer happens to get lost due to heavy load.
// SIGALRM and ITIMER_REAL doesn't really work well.
// There are issues with profiling as well.
static int /*__itimer_which*/  itimer = ITIMER_REAL;

static int sig = SIGALRM;

// Interrupt handler.
void I_HandleSoundTimer( int ignore )
{
     // UNUSED, but required.
    ignore = 0;
}

// Get the interrupt. Set duration in millisecs.
int I_SoundSetTimer( int duration_of_tick )
{
  // Needed for gametick clockwork.
  struct itimerval    value;
  struct itimerval    ovalue;
  struct sigaction    act;
  struct sigaction    oact;

  int res;
  
  // This sets to SA_ONESHOT and SA_NOMASK, thus we can not use it.
  //     signal( _sig, handle_SIG_TICK );
  
  // Now we have to change this attribute for repeated calls.
  act.sa_handler = I_HandleSoundTimer;
#ifndef sun    
  //ac	t.sa_mask = _sig;
#endif
  act.sa_flags = SA_RESTART;
  
  sigaction( sig, &act, &oact );

  value.it_interval.tv_sec    = 0;
  value.it_interval.tv_usec   = duration_of_tick;
  value.it_value.tv_sec       = 0;
  value.it_value.tv_usec      = duration_of_tick;

  // Error is -1.
  res = setitimer( itimer, &value, &ovalue );

  // Debug.
  if ( res == -1 )
    fprintf( stderr, "I_SoundSetTimer: interrupt n.a.\n");
  
  return res;
}

// Remove the interrupt. Set duration to zero.
void I_SoundDelTimer()
{
  // Debug.
  if ( I_SoundSetTimer( 0 ) == -1)
    fprintf( stderr, "I_SoundDelTimer: failed to remove interrupt. Doh!\n");
}
