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
//	DOOM graphics stuff for X11, UNIX.
//
//-----------------------------------------------------------------------------

#include "i_system.h"
#include "v_video.h"
#include "z_zone.h"

@import MetalKit;

MTKView* view;
id<MTLCommandQueue> commandQueue;
int pixelByteCount = sizeof(uint32_t) * SCREENWIDTH * SCREENHEIGHT;
uint32_t* pixels;
uint8_t* palette;
MTLRegion region;

void I_ShutdownGraphics(void)
{
    fprintf(stderr, "I_ShutdownGraphics\n");
}

void I_StartFrame (void)
{
    //fprintf(stderr, "I_StartFrame\n");
}

void I_StartTic (void)
{
    fprintf(stderr, "I_StartTic\n");
    NSEvent *event;
    while ((event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES])) {
        
        NSLog(@"%@", event);
        
        [NSApp sendEvent:event];
        [NSApp updateWindows];
    }
}

void I_UpdateNoBlit (void)
{
}

void I_FinishUpdate (void)
{
    fprintf(stderr, "I_FinishUpdate\n");
    [view draw];
}

void I_ReadScreen (byte* scr)
{
    memcpy(scr, screens[0], SCREENWIDTH*SCREENHEIGHT);
}

void I_SetPalette (byte* aPalette)
{
    fprintf(stderr, "I_SetPalette\n");
    palette = aPalette;
}

@interface DoomWindowDelegate : NSObject<NSWindowDelegate>
@end

@implementation DoomWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)notification {
    NSLog(@"Window: become key");
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    NSLog(@"Window: become main");
}

- (void)windowDidResignKey:(NSNotification *)notification {
    NSLog(@"Window: resign key");
}

- (void)windowDidResignMain:(NSNotification *)notification {
    NSLog(@"Window: resign main");
}

// This will close/terminate the application when the main window is closed.
- (void)windowWillClose:(NSNotification *)notification {
    NSWindow *window = notification.object;
    if (window.isMainWindow) {
        [NSApp terminate:nil];
        I_Quit();
    }
}
@end

@interface DoomViewController : NSViewController <MTKViewDelegate>
@end

@implementation DoomViewController
- (void)drawInMTKView:(nonnull MTKView *)view {
    if (palette == NULL)
    {
        fprintf(stderr, "No palette set.\n");
        return;
    }
    
    int j = 0;
    for (int i = 0; i < pixelByteCount; i += 4)
    {
        uint8_t index = screens[0][j];
        uint8_t* c = palette + (3 * index);
        uint8_t r = gammatable[usegamma][*c++];
        uint8_t g = gammatable[usegamma][*c++];
        uint8_t b = gammatable[usegamma][*c++];
        ((uint8_t*)pixels)[i] = b;
        ((uint8_t*)pixels)[i + 1] = g;
        ((uint8_t*)pixels)[i + 2] = r;
        ((uint8_t*)pixels)[i + 3] = UCHAR_MAX;
        ++j;
    }
    
    id<CAMetalDrawable> drawable = view.currentDrawable;
    id<MTLTexture> texture = drawable.texture;
    [texture replaceRegion:region
               mipmapLevel:0
                 withBytes:pixels
               bytesPerRow:SCREENWIDTH*sizeof(uint32_t)];
    
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    fprintf(stderr, "drawableSizeWillChange\n");
}

- (BOOL)commitEditingAndReturnError:(NSError * _Nullable * _Nullable)error {
    fprintf(stderr, "commitEditingAndReturnError\n");
    return TRUE;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    fprintf(stderr, "encodeWithCoder\n");
}
@end

void I_InitGraphics(void)
{
    fprintf(stderr, "I_InitGraphics\n");
    pixels = Z_Malloc(pixelByteCount, PU_STATIC, 0);
    
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp setPresentationOptions:NSApplicationPresentationDefault];
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp finishLaunching];
    
    int multiplier = 2;
    int w = SCREENWIDTH * multiplier;
    // Account for 4:3 aspect ratio. See Doom book appendix C.4.
    int h = (w * 3) / 4;
    NSRect graphicsRect = NSMakeRect(10, 10, w, h);
    NSWindow* window = [ [NSWindow alloc]
    initWithContentRect: graphicsRect
              styleMask: NSWindowStyleMaskTitled
                    |NSWindowStyleMaskClosable
                    |NSWindowStyleMaskMiniaturizable
                backing: NSBackingStoreBuffered
                  defer: NO ];
    [window setTitle: @"DOOM"];
    

    CGRect frame = { 0, 0, w, h };
    id<MTKViewDelegate> renderer = [DoomViewController alloc];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    view = [[MTKView alloc] initWithFrame:frame];
    view.device = device;
    view.delegate = renderer;
    view.paused = YES;
    view.enableSetNeedsDisplay = NO;
    view.drawableSize = CGSizeMake(SCREENWIDTH, SCREENHEIGHT);
    view.framebufferOnly = NO;
    
    region = MTLRegionMake2D(0, 0, SCREENWIDTH, SCREENHEIGHT);
    
    commandQueue = [device newCommandQueue];

    [window setContentView:view ];
    DoomWindowDelegate* windowDelegate = [[DoomWindowDelegate alloc] init];
    [window setDelegate:windowDelegate ];
    [window makeKeyAndOrderFront: nil];
}
