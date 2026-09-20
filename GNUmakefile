include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Browser
Browser_OBJC_FILES = \
	Source/main.m \
	Source/BrowserWindowController.m \
	Source/BrowserTab.m

# Builds against WebKit.framework installed in /System/Library/Frameworks.
ADDITIONAL_OBJCFLAGS += -fblocks -Wall

ADDITIONAL_GUI_LIBS += -lWebKit
Browser_LIBRARIES_DEPEND_UPON += -lgnustep-gui -lgnustep-base -lBlocksRuntime

# Application icon: one TIFF holding 48, 64, 128 and 256 pixel versions.
Browser_APPLICATION_ICON = Browser.tiff
Browser_RESOURCE_FILES = Resources/Browser.tiff

include $(GNUSTEP_MAKEFILES)/application.make
