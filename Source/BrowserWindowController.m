#import "BrowserWindowController.h"
#import "BrowserTab.h"

#define BAR_HEIGHT   34.0
#define STATUS_HEIGHT 18.0

static NSMutableArray *sWindows = nil;

@implementation BrowserWindowController

+ (BrowserWindowController *)openNewWindowWithURL:(NSString *)url
{
    BrowserWindowController *c = [[self alloc] init];
    if (!sWindows) sWindows = [[NSMutableArray alloc] init];
    [sWindows addObject:c];
    [[c window] makeKeyAndOrderFront:nil];
    if ([url length])
        [c loadURLString:url];
    return c;
}

- (NSButton *)_barButton:(NSString *)title frame:(NSRect)f action:(SEL)sel
{
    NSButton *b = [[NSButton alloc] initWithFrame:f];
    [b setTitle:title];
    [b setBezelStyle:NSRegularSquareBezelStyle];
    [b setTarget:self];
    [b setAction:sel];
    [b setAutoresizingMask:NSViewMaxXMargin];
    return [b autorelease];
}

- (id)init
{
    self = [super init];
    if (!self) return nil;

    _tabs = [[NSMutableArray alloc] init];

    NSRect content = NSMakeRect(0, 0, 1100, 800);
    _window = [[NSWindow alloc]
        initWithContentRect:content
                  styleMask:NSTitledWindowMask | NSClosableWindowMask
                          | NSMiniaturizableWindowMask | NSResizableWindowMask
                    backing:NSBackingStoreBuffered
                      defer:NO];
    [_window setTitle:@"Browser"];
    [_window setDelegate:(id)self];
    [_window setAcceptsMouseMovedEvents:YES];

    NSView *cv = [_window contentView];
    NSRect b = [cv bounds];

    /* --- control bar across the top --- */
    _barView = [[NSView alloc] initWithFrame:
        NSMakeRect(0, NSMaxY(b) - BAR_HEIGHT, NSWidth(b), BAR_HEIGHT)];
    [_barView setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];

    CGFloat x = 6.0, bw = 34.0, by = 4.0, bh = 26.0;
    _backButton    = [self _barButton:@"<" frame:NSMakeRect(x, by, bw, bh)
                               action:@selector(goBack:)];              x += bw + 3;
    _forwardButton = [self _barButton:@">" frame:NSMakeRect(x, by, bw, bh)
                               action:@selector(goForward:)];           x += bw + 3;
    _reloadButton  = [self _barButton:@"Reload" frame:NSMakeRect(x, by, 60, bh)
                               action:@selector(reloadOrStop:)];        x += 63;
    [_barView addSubview:_backButton];
    [_barView addSubview:_forwardButton];
    [_barView addSubview:_reloadButton];

    CGFloat newTabW = 30.0;
    CGFloat fieldW = NSWidth(b) - x - newTabW - 12.0;
    _urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(x, by, fieldW, bh)];
    [_urlField setAutoresizingMask:NSViewWidthSizable];
    [_urlField setTarget:self];
    [_urlField setAction:@selector(urlEntered:)];
    [[_urlField cell] setPlaceholderString:@"Enter a URL or search term"];
    [_barView addSubview:_urlField];

    NSButton *plus = [self _barButton:@"+"
        frame:NSMakeRect(NSWidth(b) - newTabW - 6.0, by, newTabW, bh)
        action:@selector(newTab:)];
    [plus setAutoresizingMask:NSViewMinXMargin];
    [_barView addSubview:plus];

    /* Progress bar sits flush along the bottom edge of the control bar. */
    _progress = [[NSProgressIndicator alloc]
        initWithFrame:NSMakeRect(0, 0, NSWidth(b), 3.0)];
    [_progress setIndeterminate:NO];
    [_progress setMinValue:0.0];
    [_progress setMaxValue:1.0];
    [_progress setAutoresizingMask:NSViewWidthSizable];
    [_progress setHidden:YES];
    [_barView addSubview:_progress];

    [cv addSubview:_barView];

    /* --- status line along the bottom --- */
    _status = [[NSTextField alloc] initWithFrame:
        NSMakeRect(0, 0, NSWidth(b), STATUS_HEIGHT)];
    [_status setEditable:NO];
    [_status setSelectable:NO];
    [_status setBordered:NO];
    [_status setBezeled:NO];
    [_status setDrawsBackground:NO];
    [_status setFont:[NSFont systemFontOfSize:10.0]];
    [_status setStringValue:@""];
    [_status setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    [cv addSubview:_status];

    /* --- tabs fill the rest --- */
    _tabView = [[NSTabView alloc] initWithFrame:
        NSMakeRect(0, STATUS_HEIGHT,
                   NSWidth(b), NSHeight(b) - BAR_HEIGHT - STATUS_HEIGHT)];
    [_tabView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [_tabView setDelegate:(id)self];
    [cv addSubview:_tabView];

    /* Create the first tab empty: the caller loads the start URL into it.
     * Going through -newTab: would load the home page first and that load
     * would then be cancelled, which WebKit reports as an interrupted load. */
    [self newTabReturningTab];
    return self;
}

- (void)dealloc
{
    [_tabs release];
    [_window release];
    [super dealloc];
}

- (NSWindow *)window { return _window; }

- (BrowserTab *)_currentTab
{
    NSTabViewItem *item = [_tabView selectedTabViewItem];
    return item ? (BrowserTab *)[item identifier] : nil;
}

- (WebView *)_currentWebView
{
    return [[self _currentTab] webView];
}

/* ---- actions ---- */

- (BrowserTab *)newTabReturningTab
{
    BrowserTab *tab = [[BrowserTab alloc] initWithController:self];
    [_tabs addObject:tab];
    [_tabView addTabViewItem:[tab tabViewItem]];
    [_tabView selectTabViewItem:[tab tabViewItem]];
    [tab release];
    [self focusURLField:nil];
    [self tabDidChangeState:nil];
    return tab;
}

- (void)newTab:(id)sender
{
    (void)sender;
    BrowserTab *tab = [self newTabReturningTab];
    NSString *home = [[NSUserDefaults standardUserDefaults] stringForKey:@"Homepage"];

    if ([home length])
        [tab loadURLString:home];
}

- (void)closeTab:(id)sender
{
    (void)sender;
    BrowserTab *tab = [self _currentTab];
    if (!tab) return;
    if ([_tabs count] == 1) {
        [_window performClose:nil];
        return;
    }
    [_tabView removeTabViewItem:[tab tabViewItem]];
    [_tabs removeObject:tab];
    [self tabDidChangeState:nil];
}

- (void)goBack:(id)sender    { (void)sender; [[self _currentWebView] goBack:nil]; }
- (void)goForward:(id)sender { (void)sender; [[self _currentWebView] goForward:nil]; }

- (void)reloadOrStop:(id)sender
{
    (void)sender;
    WebView *w = [self _currentWebView];
    if (!w) return;
    if ([w isLoading]) [w stopLoading:nil];
    else               [w reload:nil];
}

- (void)focusURLField:(id)sender
{
    (void)sender;
    [_window makeFirstResponder:_urlField];
}

/* Turn whatever the user typed into something loadable. */
- (NSString *)_normalizeInput:(NSString *)s
{
    s = [s stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![s length]) return nil;

    NSRange scheme = [s rangeOfString:@"://"];
    if (scheme.location != NSNotFound)
        return s;
    if ([s hasPrefix:@"about:"] || [s hasPrefix:@"data:"] || [s hasPrefix:@"file:"])
        return s;

    /* A token with a dot and no spaces is probably a hostname. */
    BOOL hasSpace = ([s rangeOfString:@" "].location != NSNotFound);
    BOOL hasDot   = ([s rangeOfString:@"."].location != NSNotFound);
    if (!hasSpace && hasDot)
        return [@"https://" stringByAppendingString:s];

    /* Otherwise treat it as a search. */
    NSMutableString *q = [NSMutableString stringWithString:s];
    [q replaceOccurrencesOfString:@" " withString:@"+"
                          options:0 range:NSMakeRange(0, [q length])];
    return [@"https://duckduckgo.com/?q=" stringByAppendingString:q];
}

- (void)urlEntered:(id)sender
{
    (void)sender;
    NSString *u = [self _normalizeInput:[_urlField stringValue]];
    if (u) [self loadURLString:u];
}

- (void)loadURLString:(NSString *)s
{
    BrowserTab *tab = [self _currentTab];
    if (!tab) return;
    [_urlField setStringValue:s];
    [tab loadURLString:s];
}

/* ---- state sync ---- */

- (void)tabDidChangeState:(BrowserTab *)tab
{
    BrowserTab *cur = [self _currentTab];
    if (tab && tab != cur)
        return;  /* background tab: only its label needed updating */

    WebView *w = [cur webView];
    if (!w) return;

    [_backButton setEnabled:[w canGoBack]];
    [_forwardButton setEnabled:[w canGoForward]];
    [_reloadButton setTitle:[w isLoading] ? @"Stop" : @"Reload"];

    if ([w isLoading]) {
        [_progress setHidden:NO];
        [_progress setDoubleValue:[w estimatedProgress]];
        [_status setStringValue:@"Loading..."];
    } else {
        [_progress setHidden:YES];
        [_status setStringValue:@""];
    }

    NSString *u = [w mainFrameURL];
    if ([u length] && ![_urlField currentEditor])
        [_urlField setStringValue:u];

    NSString *t = [cur title];
    [_window setTitle:[t length] ? t : @"Browser"];
}

/* ---- NSTabView delegate ---- */

- (void)tabView:(NSTabView *)tv didSelectTabViewItem:(NSTabViewItem *)item
{
    (void)tv; (void)item;
    [self tabDidChangeState:nil];
}

/* ---- NSWindow delegate ---- */

- (void)windowWillClose:(NSNotification *)n
{
    (void)n;
    [sWindows removeObject:self];
    if ([sWindows count] == 0)
        [NSApp terminate:nil];
}

@end
