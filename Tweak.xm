#define TWEAK
#import "Tweak.h"

UIColor *domColor;

%hook UILabel

-(void)layoutSubviews {
	%orig;
	NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	if (![bundleIdentifier isEqualToString:@"com.apple.springboard"]|![bundleIdentifier isEqualToString:@"com.apple.mobiletimer"]) {
		NSString *bundleRootPath = [[NSBundle mainBundle] bundlePath];
		NSArray *bundleRootContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundleRootPath error:nil];
		NSArray *files = [bundleRootContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self beginswith 'AppIcon' OR self beginswith 'Icon' OR self beginswith 'Image'"]];
		NSString *iconPath;
		if ([files count] == 0) {
			//some apps break the rules
			NSArray *altFiles = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIconFiles"];
			iconPath = [NSString stringWithFormat:@"%@/%@", bundleRootPath, altFiles[0]];
		} else {
			iconPath = [NSString stringWithFormat:@"%@/%@", bundleRootPath, files[0]];
		}

		BOOL hasFileExtension;
		hasFileExtension = [iconPath hasSuffix:@".png"];
		if (!hasFileExtension) {
			iconPath = [iconPath stringByAppendingString:@".png"];
		}

		UIImage *appIconForCurrentBundle = [UIImage imageWithContentsOfFile:iconPath];

		domColor = ALDominantColor(appIconForCurrentBundle);

		CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();

	     UIColor *(^convertColorToRGBSpace)(UIColor*) = ^(UIColor *color) {
	         if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
	             const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
	             CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
	             CGColorRef colorRef = CGColorCreate( colorSpaceRGB, components );

	             UIColor *color = [UIColor colorWithCGColor:colorRef];
	             CGColorRelease(colorRef);
	             return color;
	         } else
	             return color;
	     };

	     UIColor *rgbDomColor = convertColorToRGBSpace(domColor);
	     UIColor *otherColor = convertColorToRGBSpace([UIColor blackColor]);

		BOOL areColorsEqual = [rgbDomColor isEqual:otherColor];
		if (areColorsEqual) {
			%orig;
			NSLog(@"AdaptiveLabels - Colours NOT applied, error fetching. No changes will be made.");
		} else {
			self.textColor = domColor;
			NSLog(@"AdaptiveLabels - Colours applied");
		}


	}

}
%end
