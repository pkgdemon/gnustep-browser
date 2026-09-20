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

/* One browser tab: a WebView plus the chrome state that belongs to it. */
#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

@class BrowserWindowController;

@interface BrowserTab : NSObject <WebFrameLoadDelegate, WebUIDelegate>
{
    WebView                *_webView;
    NSTabViewItem          *_item;
    NSString               *_title;
    double                  _progress;
    BOOL                    _loading;
    BrowserWindowController *_controller;  /* unretained */
}

- (id)initWithController:(BrowserWindowController *)controller;
- (WebView *)webView;
- (NSTabViewItem *)tabViewItem;
- (NSString *)title;
- (double)progress;
- (BOOL)isLoading;
- (void)loadURLString:(NSString *)s;
@end
