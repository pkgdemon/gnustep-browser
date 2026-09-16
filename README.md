# Browser

A native GNUstep web browser built on `WebKit.framework` (real WebKit via WPE).

## Build & install

Requires `WebKit.framework` installed in `/System/Library/Frameworks`
(see `/root/gnustep-webkit`) and the WPE engine in `/System/Library/Libraries`.

```sh
make
make install GNUSTEP_INSTALLATION_DOMAIN=LOCAL   # -> /Local/Applications/Browser.app
```

## Run

```sh
/Local/Applications/Browser.app/Browser                       # default page
/Local/Applications/Browser.app/Browser https://example.com   # a URL
/Local/Applications/Browser.app/Browser URL --snapshot out.png  # headless capture
```

## Features

Tabs, back/forward, reload/stop, URL bar (bare hostnames get `https://`,
anything else becomes a DuckDuckGo search), load progress, status line,
per-tab titles, in-page error pages, and a menu with the usual shortcuts
(Cmd-N/T/W/L/R and Cmd-[ / Cmd-]).

## Notes

- `-applicationDidFinishLaunching:` does not fire reliably here, so the first
  window is created directly from `main()` rather than from that callback.
- `--snapshot` drives the run loop manually so captures are deterministic.
