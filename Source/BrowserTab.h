/* One browser tab: a WebView plus the chrome state that belongs to it. */
#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

@class BrowserWindowController;

@interface BrowserTab : NSObject <WebFrameLoadDelegate>
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
