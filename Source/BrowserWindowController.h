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
