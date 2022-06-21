#include "Tweak.h"

%hook SBIconView
- (void)setApplicationShortcutItems:(NSArray *)ShortcutItems {
	//bug with spotlight..
	//SBApplication *sbApp = [self.icon valueForKey:@"_application"];
	//SBApplication *sbApp = MSHookIvar<SBApplication *>((id)self.icon, "_application");
	//if (sbApp.isSystemApplication || [sbApp.bundleIdentifier containsString:@"com.apple"]) {
	//		return %orig;
	//}

	NSMutableArray *editedItems = [NSMutableArray arrayWithArray:ShortcutItems ? : @[]];
	if (![self.icon isKindOfClass:%c(SBFolderIcon)] && ![self.icon isKindOfClass:%c(SBWidgetIcon)]) { 
		SBSApplicationShortcutItem *ShortcutItems = [[%c(SBSApplicationShortcutItem) alloc] init];
		ShortcutItems.localizedTitle = @"Spoof App Version";
		ShortcutItems.type = SPOOF_VER_TWEAK_BUNDLE;
		NSData *ImageData = UIImagePNGRepresentation([UIImage imageNamed:@"/Library/Application Support/3DAppVersionSpoofer.bundle/fakever@2x.png"]);
		if (ImageData) {
			SBSApplicationShortcutCustomImageIcon *IconImage = [[%c(SBSApplicationShortcutCustomImageIcon) alloc] initWithImagePNGData:ImageData];
			ShortcutItems.icon = IconImage;
		}
		if (ShortcutItems) {
			[editedItems addObject:ShortcutItems];
		}
	}
 	%orig(editedItems);
}

+ (void)activateShortcut:(SBSApplicationShortcutItem *)item withBundleIdentifier:(NSString *)bundleID forIconView:(SBIconView *)iconView {
    if ([item.type isEqualToString:SPOOF_VER_TWEAK_BUNDLE]) {
		NSString *appName = [[NSBundle bundleWithIdentifier:bundleID] infoDictionary][@"CFBundleShortVersionString"];
		NSMutableDictionary *prefPlist = [NSMutableDictionary dictionary];
		[prefPlist addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:SPOOF_VER_PLIST]];
		NSString *currentVer = prefPlist[bundleID];
		if (currentVer == nil || [currentVer isEqualToString:@"0"]) {
			currentVer = @"Default";
		}
	    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"3DAppVersionSpoofer"
																	message:[NSString stringWithFormat:@"WARNING: This can cause unexpected behavior in your app.\nBundle ID: %@\nCurrent Spoofed Version: %@\nDefault App Version: %@\n\nWhat is the version number you want to spoof?",bundleID,currentVer,appName]
																	preferredStyle:UIAlertControllerStyleAlert];

		[alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {textField.placeholder = @"Enter Version Number"; textField.keyboardType = UIKeyboardTypeDecimalPad;}];
		UIAlertAction *setNewValue = [UIAlertAction actionWithTitle:@"Set Spoofed Version" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
			[prefPlist setObject:[[alertController textFields][0] text] forKey:bundleID];
			[prefPlist writeToFile:SPOOF_VER_PLIST atomically:YES];
		}];

		[alertController addAction:setNewValue];

		UIAlertAction *setDefaultValue = [UIAlertAction actionWithTitle:@"Set Default Version" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			//0 means use original version!
			CGFloat defaultValue = 0.0f;
			NSNumber *numberFromFloat = [NSNumber numberWithFloat:defaultValue];
			[prefPlist setObject:[numberFromFloat stringValue] forKey:bundleID];
			[prefPlist writeToFile:SPOOF_VER_PLIST atomically:YES];
		}];
		[alertController addAction:setDefaultValue];

		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
		[alertController addAction:cancelAction];
		UIWindow* tempWindowForPrompt = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
		tempWindowForPrompt.rootViewController = [UIViewController new];
		tempWindowForPrompt.windowLevel = UIWindowLevelAlert+1;
		tempWindowForPrompt.hidden = NO;
		[tempWindowForPrompt makeKeyAndVisible];
		tempWindowForPrompt.tintColor = [[UIWindow valueForKey:@"keyWindow"] tintColor];
		[tempWindowForPrompt.rootViewController presentViewController:alertController animated:YES completion:nil];
	}
}
%end

%hook NSBundle
NSString *versionToSpoof = nil;
-(NSDictionary *)infoDictionary {
	if (!self || ![self isLoaded] || ![[self bundleURL].absoluteString containsString:@"Application"]) {
		return %orig;
	} else {	
	    NSDictionary *dictionary = %orig;
	    NSMutableDictionary *moddedDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
		NSString *appBundleID = moddedDictionary[@"CFBundleIdentifier"];
		NSDictionary* modifiedBundlesDict = [[NSDictionary alloc] initWithContentsOfFile:SPOOF_VER_PLIST];
		if (appBundleID && [modifiedBundlesDict objectForKey:appBundleID] && ![modifiedBundlesDict[appBundleID] isEqualToString:@"0"]) {
			versionToSpoof = [[NSString alloc] init];
			versionToSpoof = modifiedBundlesDict[appBundleID];
			[moddedDictionary setValue:versionToSpoof forKey:@"CFBundleShortVersionString"];
		}
		return moddedDictionary;
	}
}
%end