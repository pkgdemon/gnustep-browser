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

include $(GNUSTEP_MAKEFILES)/application.make
