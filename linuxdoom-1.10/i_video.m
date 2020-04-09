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

#include "d_main.h"
#include "i_system.h"
#include "v_video.h"
#include "z_zone.h"

@import Carbon;
@import MetalKit;

MTKView* view;
id<MTLCommandQueue> commandQueue;
int pixelByteCount = sizeof(uint32_t) * SCREENWIDTH * SCREENHEIGHT;
uint32_t* pixels;
uint8_t* palette;
MTLRegion region;
NSEventModifierFlags currentModifierFlags = 0;

void I_ShutdownGraphics(void)
{
    fprintf(stderr, "I_ShutdownGraphics\n");
}

void I_StartFrame (void)
{
    //fprintf(stderr, "I_StartFrame\n");
}

int translateKey(unsigned short keyCode, NSString* characters)
{
    switch (keyCode) {
        case kVK_UpArrow:
            return KEY_UPARROW;
        case kVK_LeftArrow:
            return KEY_LEFTARROW;
        case kVK_RightArrow:
            return KEY_RIGHTARROW;
        case kVK_DownArrow:
            return KEY_DOWNARROW;
        case kVK_Return:
            return KEY_ENTER;
        case kVK_Escape:
            return KEY_ESCAPE;
        case kVK_Tab:
            return KEY_TAB;
        case kVK_ANSI_Minus:
            return KEY_MINUS;
        case kVK_F1:
            return KEY_F1;
        case kVK_F2:
            return KEY_F2;
        case kVK_F3:
            return KEY_F3;
        case kVK_F4:
            return KEY_F4;
        case kVK_F5:
            return KEY_F5;
        case kVK_F6:
            return KEY_F6;
        case kVK_F7:
            return KEY_F7;
        case kVK_F8:
            return KEY_F8;
        case kVK_F9:
            return KEY_F9;
        case kVK_F10:
            return KEY_F10;
        case kVK_F11:
            return KEY_F11;
        case kVK_F12:
            return KEY_F12;
        default:
        {
            unichar c = [characters characterAtIndex:0];
            if (c >= ' ' && c <= 'z')
            {
                return c;
            }
            fprintf(stderr, "Unknown key code: %d", keyCode);
            return keyCode;
        }
    }
}

void checkModifierKey(NSEventModifierFlags flags, NSEventModifierFlags modifier, int doomKey)
{
    if (flags & modifier)
    {
        if (!(currentModifierFlags & modifier))
        {
            event_t doomEvent;
            doomEvent.type = ev_keydown;
            doomEvent.data1 = doomKey;
            D_PostEvent(&doomEvent);
        }
    }
    else
    {
        if (currentModifierFlags & modifier)
        {
            event_t doomEvent;
            doomEvent.type = ev_keyup;
            doomEvent.data1 = doomKey;
            D_PostEvent(&doomEvent);
        }
    }
}

void I_StartTic (void)
{
    fprintf(stderr, "I_StartTic\n");
    NSEvent *event;
    while ((event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES])) {

        NSLog(@"%@", event);
        switch (event.type) {
            case NSEventTypeKeyDown:
            {
                event_t doomEvent;
                doomEvent.type = ev_keydown;
                doomEvent.data1 = translateKey(event.keyCode, event.characters);
                D_PostEvent(&doomEvent);
            }
                break;
            case NSEventTypeKeyUp:
            {
                event_t doomEvent;
                doomEvent.type = ev_keyup;
                doomEvent.data1 = translateKey(event.keyCode, event.characters);
                D_PostEvent(&doomEvent);

            }
                break;
            case NSEventTypeFlagsChanged:
                checkModifierKey(event.modifierFlags, NSEventModifierFlagControl, KEY_RCTRL);
                checkModifierKey(event.modifierFlags, NSEventModifierFlagOption, KEY_LALT);
                checkModifierKey(event.modifierFlags, NSEventModifierFlagShift, KEY_RSHIFT);
                currentModifierFlags = event.modifierFlags;
                break;
            default:
                [NSApp sendEvent:event];
                break;
        }
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
