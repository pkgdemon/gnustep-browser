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

#import "BrowserTab.h"
#import "BrowserWindowController.h"

@implementation BrowserTab

- (id)initWithController:(BrowserWindowController *)controller
{
    self = [super init];
    if (!self) return nil;

    _controller = controller;
    _title = [@"New Tab" copy];

    _webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 1024, 700)];
    [_webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [_webView setFrameLoadDelegate:self];
    [_webView setUIDelegate:self];

    _item = [[NSTabViewItem alloc] initWithIdentifier:self];
    [_item setLabel:_title];
    [_item setView:_webView];

    return self;
}

/* ---- WebUIDelegate ----
 * A page asked for a new window (target=_blank, window.open). Give it a new
 * tab; WebKit.framework loads the request into that tab's view. */
- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    (void)sender; (void)request;
    return [[_controller newTabReturningTab] webView];
}

- (void)dealloc
{
    [_webView setFrameLoadDelegate:nil];
    [_webView release];
    [_item release];
    [_title release];
    [super dealloc];
}

- (WebView *)webView          { return _webView; }
- (NSTabViewItem *)tabViewItem { return _item; }
- (NSString *)title           { return _title; }
- (double)progress            { return _progress; }
- (BOOL)isLoading             { return _loading; }

- (void)loadURLString:(NSString *)s
{
    [_webView setMainFrameURL:s];
}

- (void)_setTitle:(NSString *)t
{
    if (t == _title) return;
    [_title release];
    _title = [([t length] ? t : @"Untitled") copy];

    /* Keep tab labels short enough to stay readable. */
    NSString *label = _title;
    if ([label length] > 24)
        label = [[label substringToIndex:22] stringByAppendingString:@"..."];
    [_item setLabel:label];
    [_controller tabDidChangeState:self];
}

/* ---- WebFrameLoadDelegate ---- */

- (void)webView:(WebView *)s didStartProvisionalLoadForFrame:(id)f
{
    (void)s; (void)f;
    _loading = YES;
    _progress = 0.0;
    [_controller tabDidChangeState:self];
}

- (void)webView:(WebView *)s didChangeProgress:(double)p
{
    (void)s;
    _progress = p;
    [_controller tabDidChangeState:self];
}

- (void)webView:(WebView *)s didReceiveTitle:(NSString *)t forFrame:(id)f
{
    (void)s; (void)f;
    [self _setTitle:t];
}

- (void)webView:(WebView *)s didFinishLoadForFrame:(id)f
{
    (void)f;
    _loading = NO;
    _progress = 1.0;
    if (![_title length] || [_title isEqualToString:@"New Tab"]) {
        NSString *t = [s mainFrameTitle];
        if ([t length]) [self _setTitle:t];
    }
    [_controller tabDidChangeState:self];
}

- (void)webView:(WebView *)s didFailLoadWithError:(NSError *)e forFrame:(id)f
{
    (void)f;
    _loading = NO;
    _progress = 0.0;

    /* Show the failure in the page itself, the way a real browser does. */
    NSString *html = [NSString stringWithFormat:
        @"<html><head><meta charset='utf-8'><title>Failed to load</title></head>"
         "<body style=\"font:14px sans-serif;margin:3em;color:#333\">"
         "<h2 style='font-weight:600'>Could not open this page</h2>"
         "<p style='color:#666'>%@</p></body></html>",
        [e localizedDescription]];
    [s loadHTMLString:html baseURL:nil];
    [self _setTitle:@"Failed to load"];
    [_controller tabDidChangeState:self];
}

@end
