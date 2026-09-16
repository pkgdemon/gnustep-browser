#import <AppKit/AppKit.h>
#import "BrowserWindowController.h"

@interface AppDelegate : NSObject
{ NSString *_startURL; BOOL _headless; NSString *_shotPath; }
- (void)setStartURL:(NSString *)u;
- (void)setShotPath:(NSString *)p;
@end

static NSMenu *buildMenu(void)
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Browser"];

    [menu addItemWithTitle:@"New Window" action:@selector(newWindow:) keyEquivalent:@"n"];
    [menu addItemWithTitle:@"New Tab"    action:@selector(newTab:)    keyEquivalent:@"t"];
    [menu addItemWithTitle:@"Close Tab"  action:@selector(closeTab:)  keyEquivalent:@"w"];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Open Location..." action:@selector(focusURLField:) keyEquivalent:@"l"];
    [menu addItemWithTitle:@"Reload"     action:@selector(reloadOrStop:) keyEquivalent:@"r"];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Back"       action:@selector(goBack:)    keyEquivalent:@"["];
    [menu addItemWithTitle:@"Forward"    action:@selector(goForward:) keyEquivalent:@"]"];
    [menu addItem:[NSMenuItem separatorItem]];

    NSMenu *edit = [[NSMenu alloc] initWithTitle:@"Edit"];
    [edit addItemWithTitle:@"Cut"       action:@selector(cut:)       keyEquivalent:@"x"];
    [edit addItemWithTitle:@"Copy"      action:@selector(copy:)      keyEquivalent:@"c"];
    [edit addItemWithTitle:@"Paste"     action:@selector(paste:)     keyEquivalent:@"v"];
    [edit addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    NSMenuItem *editItem = [menu addItemWithTitle:@"Edit" action:NULL keyEquivalent:@""];
    [menu setSubmenu:edit forItem:editItem];
    [edit release];

    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    return [menu autorelease];
}

@implementation AppDelegate
- (void)setStartURL:(NSString *)u { _startURL = [u copy]; }
- (void)setShotPath:(NSString *)p { _shotPath = [p copy]; _headless = YES; }

- (void)openFirstWindow
{
    [BrowserWindowController openNewWindowWithURL:_startURL];
    if (_headless)
        [self performSelector:@selector(snapshot) withObject:nil afterDelay:8.0];
}
- (BOOL)isHeadless { return _headless; }
- (void)applicationDidFinishLaunching:(NSNotification *)n { (void)n; }

/* Capture the whole window (chrome + page) so we can see the real UI. */
- (void)snapshot
{
    NSWindow *win = [[NSApp windows] count] ? [[NSApp windows] objectAtIndex:0] : nil;
    NSView *cv = [win contentView];
    if (!cv) { NSLog(@"no window to capture"); [NSApp terminate:nil]; return; }

    [cv lockFocus];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
        initWithFocusedViewRect:[cv bounds]];
    [cv unlockFocus];

    NSData *png = [rep representationUsingType:NSPNGFileType properties:nil];
    [png writeToFile:_shotPath atomically:YES];
    NSLog(@"wrote %@ (%lu bytes)", _shotPath, (unsigned long)[png length]);
    [rep release];
    [NSApp terminate:nil];
}

/* Route menu actions to the key window's controller. */
- (BrowserWindowController *)_controller
{
    NSWindow *w = [NSApp keyWindow];
    if (!w) w = [[NSApp windows] count] ? [[NSApp windows] objectAtIndex:0] : nil;
    return (BrowserWindowController *)[w delegate];
}
- (void)newWindow:(id)s   { (void)s; [BrowserWindowController openNewWindowWithURL:nil]; }
- (void)newTab:(id)s      { [[self _controller] newTab:s]; }
- (void)closeTab:(id)s    { [[self _controller] closeTab:s]; }
- (void)goBack:(id)s      { [[self _controller] goBack:s]; }
- (void)goForward:(id)s   { [[self _controller] goForward:s]; }
- (void)reloadOrStop:(id)s { [[self _controller] reloadOrStop:s]; }
- (void)focusURLField:(id)s { [[self _controller] focusURLField:s]; }
@end

int main(int argc, const char **argv)
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSApplication *app = [NSApplication sharedApplication];

    AppDelegate *d = [AppDelegate new];
    NSString *url = nil, *shot = nil;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--snapshot") && i + 1 < argc)
            shot = [NSString stringWithUTF8String:argv[++i]];
        else
            url = [NSString stringWithUTF8String:argv[i]];
    }
    [d setStartURL:url ? url : @"https://example.com"];
    if (shot) [d setShotPath:shot];

    [app setMainMenu:buildMenu()];
    [app setDelegate:d];

    /* Create the window up front rather than waiting for
     * -applicationDidFinishLaunching:, which does not fire reliably here. */
    [d openFirstWindow];

    if ([d isHeadless]) {
        /* Drive the run loop ourselves so the snapshot path is deterministic. */
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:45];
        while ([deadline timeIntervalSinceNow] > 0) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
        }
    } else {
        [app run];
    }

    [pool release];
    return 0;
}
