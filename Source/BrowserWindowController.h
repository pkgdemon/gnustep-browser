/* Copyright (C) 2026 Joseph Maloney

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, see
   <https://www.gnu.org/licenses/>.  */

#import <AppKit/AppKit.h>

@class BrowserTab;

@interface BrowserWindowController : NSObject
{
    NSWindow            *_window;
    NSTabView           *_tabView;
    NSView              *_barView;
    NSButton            *_backButton;
    NSButton            *_forwardButton;
    NSButton            *_reloadButton;
    NSTextField         *_urlField;
    NSProgressIndicator *_progress;
    NSTextField         *_status;
    NSMutableArray      *_tabs;
}

+ (BrowserWindowController *)openNewWindowWithURL:(NSString *)url;

- (id)init;
- (NSWindow *)window;
- (void)newTab:(id)sender;
- (BrowserTab *)newTabReturningTab;   /* the tab, for window.open */
- (void)closeTab:(id)sender;
- (void)goBack:(id)sender;
- (void)goForward:(id)sender;
- (void)reloadOrStop:(id)sender;
- (void)focusURLField:(id)sender;
- (void)urlEntered:(id)sender;
- (void)loadURLString:(NSString *)s;

/* Called by tabs when their state changes. */
- (void)tabDidChangeState:(BrowserTab *)tab;
@end
