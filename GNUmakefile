# Copyright (C) 2026 Joseph Maloney
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, see
# <https://www.gnu.org/licenses/>.

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
