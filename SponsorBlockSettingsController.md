#import "Headers/YouTubeHeader/YTSettingsViewController.h"
#import "Headers/YouTubeHeader/YTSettingsSectionItem.h"
#import "Headers/YouTubeHeader/YTSettingsPickerViewController.h"
#import "Headers/YouTubeHeader/YTSettingsSectionItemManager.h"
#import "Headers/YouTubeHeader/YTSettingsTextViewController.h"
#import "Headers/YouTubeHeader/YTAppSettingsSectionItemActionController.h"
#import "Headers/YouTubeHeader/YTSettingsMultiplePickersViewController.h"
#import "Headers/YouTubeHeader/YTBrowseViewController.h"
#import "Headers/YouTubeHeader/YTSettings.h"
#import "Headers/YouTubeHeader/YTLiveServices.h"
#import "Headers/YouTubeHeader/YTNotificationSettingsViewController.h"
#import "Headers/YouTubeHeader/YTLiveChatSettingsViewController.h"
#import "Headers/YouTubeHeader/_ASCollectionViewCell.h"
#import "Headers/YouTubeHeader/YTInnerTubeCollectionViewController.h"
#import "Headers/YouTubeHeader/YTAccountPanelViewController.h"
#import "Headers/YouTubeHeader/YTSettingsSectionController.h"

NSBundle *iSponsorBlockBundle();

#define LOC(x) [tweakBundle localizedStringForKey:x value:nil table:nil]

static const NSInteger TweakSection = 9999;

@interface YTSettingsSectionItemManager (Tweak)
- (YTSettingsSectionItem *)createPickerSectionWithKey:(NSString *)key title:(NSString *)title description:(NSString *)description;
- (YTSettingsSectionItem *)createTextSectionWithKey:(NSString *)key title:(NSString *)title description:(NSString *)description isFloat:(BOOL)isFloat;
- (YTSettingsSectionItem *)createSwitchSectionWithKey:(NSString *)key title:(NSString *)title description:(NSString *)description;
- (void)updateTweakSectionWithEntry:(id)entry;
@end

%hook YTAppSettingsPresentationData

+ (NSArray *)settingsCategoryOrder {
    NSArray *order = %orig;
    NSMutableArray *mutableOrder = [order mutableCopy];

    // Choose your settings insertion index
    NSUInteger insertIndex = [order indexOfObject:@(1)]; // "General" index is 1
    if (insertIndex != NSNotFound)
        [mutableOrder insertObject:@(TweakSection) atIndex:insertIndex + 1];

    return mutableOrder;
}

%end

// This hook is specific to Boolean option (group)
// If your tweak does not need that setting type, you don't need this hook
%hook YTSettingsSectionController

- (void)setSelectedItem:(NSUInteger)selectedItem {
    if (selectedItem != NSNotFound) %orig;
}

%end

%hook YTSettingsSectionItemManager

%new(@@:@@@)
- (YTSettingsSectionItem *)createPickerSectionWithKey:(NSString *)key title:(NSString *)title description:(NSString *)description {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *settingsPath = [documentsDirectory stringByAppendingPathComponent:@"iSponsorBlock.plist"];
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    NSBundle *tweakBundle = iSponsorBlockBundle();
    NSDictionary *categorySettings = [settings objectForKey:@"categorySettings"];
    YTSettingsViewController *settingsViewController = [self valueForKey:@"_settingsViewControllerDelegate"];
    YTSettingsSectionItem *section = [%c(YTSettingsSectionItem) itemWithTitle:title titleDescription:description accessibilityIdentifier:nil
        detailTextBlock:^NSString *() {
            switch ([[categorySettings objectForKey:key] intValue]) {
                case 0:
                default:
                    return LOC(@"Disable");
                case 1:
                    return LOC(@"AutoSkip");
                case 2:
                    return LOC(@"ShowInSeekBar");
                case 3:
                    return LOC(@"ManualSkip");
            }
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSArray <YTSettingsSectionItem *> *rows = @[
                [%c(YTSettingsSectionItem) checkmarkItemWithTitle:LOC(@"Disable") titleDescription:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    [categorySettings setValue:@(0) forKey:key];
                    [settings writeToFile:settingsPath atomically:YES];
                    [settingsViewController reloadData];
                    return YES;
                }],
                [%c(YTSettingsSectionItem) checkmarkItemWithTitle:LOC(@"AutoSkip") titleDescription:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    [categorySettings setValue:@(1) forKey:key];
                    [settings writeToFile:settingsPath atomically:YES];
                    [settingsViewController reloadData];
                    return YES;
                }],
                [%c(YTSettingsSectionItem) checkmarkItemWithTitle:LOC(@"ShowInSeekBar") titleDescription:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    [categorySettings setValue:@(2) forKey:key];
                    [settings writeToFile:settingsPath atomically:YES];
                    [settingsViewController reloadData];
                    return YES;
                }],
                [%c(YTSettingsSectionItem) checkmarkItemWithTitle:LOC(@"ManualSkip") titleDescription:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    [categorySettings setValue:@(3) forKey:key];
                    [settings writeToFile:settingsPath atomically:YES];
                    [settingsViewController reloadData];
                    return YES;
                }]
            ];
            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:title pickerSectionTitle:@"Category Options" rows:rows selectedItemIndex:[[categorySettings objectForKey:key] intValue] parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];

    return section;
}

%new(@@:@@@@)
- (YTSettingsSectionItem *)createTextSectionWithKey:(NSString *)key title:(NSString *)title description:(NSString *)description isFloat:(BOOL)isFloat {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *settingsPath = [documentsDirectory stringByAppendingPathComponent:@"iSponsorBlock.plist"];
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    YTSettingsViewController *settingsViewController = [self valueForKey:@"_settingsViewControllerDelegate"];
    YTSettingsSectionItem *section = [%c(YTSettingsSectionItem) itemWithTitle:title titleDescription:description accessibilityIdentifier:nil
        detailTextBlock:^NSString *() {
            return isFloat ? [NSString stringWithFormat:@"%.1f", [[settings valueForKey:key] floatValue]] : [settings valueForKey:key];
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            YTSettingsTextViewController *textBlock = [[%c(YTSettingsTextViewController) alloc] initWithNavTitle:title textTitle:nil
                text:isFloat ? [NSString stringWithFormat:@"%.1f", [[settings valueForKey:key] floatValue]] : [settings valueForKey:key]
                textChangeBlock:^BOOL (YTSettingsCell *cell, NSString *arg1) {
                    [settings setValue:arg1 forKey:key];
                    [settings writeToFile:settingsPath atomically:YES];
                    [settingsViewController reloadData];
                    return YES;
                }
                parentResponder:[self parentResponder]];

            [settingsViewController pushViewController:textBlock];
            return YES;
        }];
    return section;
}

%new(@@:@@@)
- (YTSettingsSectionItem *)createSwitchSectionWithKey:(NSString *)key title:(NSString *)title description:(NSString *)description {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *settingsPath = [documentsDirectory stringByAppendingPathComponent:@"iSponsorBlock.plist"];
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    
    YTSettingsSectionItem *section = [%c(YTSettingsSectionItem) switchItemWithTitle:title titleDescription:description accessibilityIdentifier:nil
        switchOn:[[settings valueForKey:key] boolValue]
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [settings setValue:@(enabled) forKey:key];
            [settings writeToFile:settingsPath atomically:YES];
            return YES;
        }
        settingItemId:0];
    return section;
}

%new(v@:@)
- (void)updateTweakSectionWithEntry:(id)entry {
    NSBundle *tweakBundle = iSponsorBlockBundle();
    NSMutableArray *sectionItems = [NSMutableArray array];
    YTSettingsViewController *settingsViewController = [self valueForKey:@"_settingsViewControllerDelegate"];

    // Master switch
    [sectionItems addObject:[self createSwitchSectionWithKey:@"enabled" title:LOC(@"Enabled") description:LOC(@"RestartFooter")]];

    // Picker section
    NSArray *sectionKey = @[@"sponsor", @"intro", @"outro", @"interaction", @"selfpromo", @"music_offtopic"];
    NSArray *sectionTitle = @[LOC(@"Sponsor"), LOC(@"Intermission/IntroAnimation"), LOC(@"Endcards/Credits"), LOC(@"InteractionReminder"), LOC(@"Unpaid/SelfPromotion"), LOC(@"Non-MusicSection")];
    NSArray *sectionDescription = @[LOC(@"Sponsor_Description"), LOC(@"Intermission/IntroAnimation_Description"), LOC(@"Endcards/Credits_Description"), LOC(@"InteractionReminder_Description"), LOC(@"Unpaid/SelfPromotion_Description"), LOC(@"Non-MusicSection_Description")];
    for (int i = 0; i < 6; i++) {
        [sectionItems addObject:[self createPickerSectionWithKey:sectionKey[i] title:sectionTitle[i] description:sectionDescription[i]]];
    }

    // Editable text section
    sectionKey = @[@"userID", @"apiInstance", @"minimumDuration", @"skipNoticeDuration"];
    sectionTitle = @[LOC(@"UserID"), LOC(@"API_URL"), LOC(@"MinimumSegmentDuration"), LOC(@"HowLongNoticeWillAppear")];
    sectionDescription = @[LOC(@"UserIDFooter"), LOC(@"APIFooter"), @"", @""];
    for (int i = 0; i < 4; i++) {
        [sectionItems addObject:[self createTextSectionWithKey:sectionKey[i] title:sectionTitle[i] description:sectionDescription[i] isFloat:i >= 2]];
    }

    // Button switch
    sectionKey = @[@"showSkipNotice", @"showButtonsInPlayer", @"hideStartEndButtonInPlayer", @"showModifiedTime", @"skipAudioNotification", @"enableSkipCountTracking"];
    sectionTitle = @[LOC(@"ShowSkipNotice"), LOC(@"ShowButtonsInPlayer"), LOC(@"HideStartEndButtonInPlayer"), LOC(@"ShowModifiedTime"), LOC(@"AudioNotificationOnSkip"), LOC(@"EnableSkipCountTracking")];
    sectionDescription = @[@"", @"", @"", @"", LOC(@"AudioFooter"), @""];
    for (int i = 0; i < 6; i++) {
        [sectionItems addObject:[self createSwitchSectionWithKey:sectionKey[i] title:sectionTitle[i] description:sectionDescription[i]]];
    }
/*
    NSMutableArray *testArray;

    YTSettingsSectionItem *donateSection1 = [%c(YTSettingsSectionItem) itemWithTitle:LOC(@"DonateOnVenmo") titleDescription:nil accessibilityIdentifier:nil
        detailTextBlock:^NSString *() {
            return @"";
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"venmo://"]]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"venmo://venmo.com/code?user_id=3178620965093376215"] options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://venmo.com/code?user_id=3178620965093376215"] options:@{} completionHandler:nil];
            }
            return YES;
        }];

    [testArray addObject:[[%c(YTSettingsSectionController) alloc] initWithTitle:@"test1" items:@[donateSection1]]];

    YTSettingsSectionItem *donateSection2 = [%c(YTSettingsSectionItem) itemWithTitle:LOC(@"DonateOnPayPal") titleDescription:nil accessibilityIdentifier:nil
        detailTextBlock:^NSString *() {
            return @"";
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/DBrett684"] options:@{} completionHandler:nil];
            return YES;
        }];
    
    [testArray addObject:[[%c(YTSettingsSectionController) alloc] initWithTitle:@"test1" items:@[donateSection2]]];
    
    //[[%c(YTSettingsMultiplePickersViewController) alloc] showSectionForSettings:testArray navTitle:@"oke" sectionTitles:nil defaultValues:@[@0, @1] selectBlocks:nil];


    YTSettingsMultiplePickersViewController *textBlock = [[%c(YTSettingsMultiplePickersViewController) alloc] initWithParentResponder:[self parentResponder]];
    [textBlock showSectionForSettings:testArray navTitle:@"oke" sectionTitles:testArray defaultValues:nil
        selectBlocks:nil];
    //[textBlock setValue:@"hello" forKey:@"_navTitle"];
    //[textBlock setValue:testArray forKey:@"_settingsControllers"];

    [settingsViewController pushViewController:textBlock];*/
    [settingsViewController setSectionItems:sectionItems forCategory:TweakSection title:@"iSponsorBlock" titleDescription:nil headerHidden:NO];
}

- (void)updateSectionForCategory:(NSUInteger)category withEntry:(id)entry {
    if (category == TweakSection) {
        [self updateTweakSectionWithEntry:entry];
        return;
    }
    %orig;
}

%end

%hook YTAccountPanelViewController

- (id)initWithRenderer:(id)arg1 helpContext:(id)arg2 parentResponder:(id)arg3 {
    return nil;
}

%end

/*
%hook YTSettingsMultiplePickersViewController

- (void)showSectionForSettings:(id)arg1 navTitle:(id)arg2 sectionTitles:(id)arg3 defaultValues:(id)arg4 selectBlocks:(id)arg5 {
    %orig;
    if ([arg1 count] == 1) return %orig;
}

%end
*/