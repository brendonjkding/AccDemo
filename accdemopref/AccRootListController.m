#import "AccRootListController.h"
#import "BDInfoListController.h"
#import "AccLicenseViewController.h"
#import <notify.h>
@implementation AccRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		    _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
        PSSpecifier* spec;

        NSInteger index=[self indexOfSpecifierID:@"ADD_SPEED"]+1;
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
        NSArray*speedKeys= prefs[@"speedKeys"];
        for(NSString*speedKey in speedKeys.reverseObjectEnumerator){
            spec = [PSSpecifier preferenceSpecifierNamed:@""
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSEditTextCell
                                                edit:Nil];
            [spec setProperty:@1 forKey:@"default"];
            [spec setProperty:@"com.brend0n.accdemo" forKey:@"defaults"];
            [spec setProperty:speedKey forKey:@"key"];
            [spec setProperty:@"com.brend0n.accdemo/loadPref" forKey:@"PostNotification"];
            [spec setProperty:@YES forKey:@"isDecimalPad"];
            
            [_specifiers insertObject:spec atIndex:index];
        }
        
        spec=[PSSpecifier emptyGroupSpecifier];
        [_specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Licenses"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(showLicenses);
        [_specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:[[NSBundle bundleForClass:[self class]] localizedStringForKey:@"AUTHOR" value:@"Author" table:@"Root"]
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(showInfo);
        [_specifiers addObject:spec];
	}

	return _specifiers;
}
// add
-(void)addSpeed{
    NSData *data = [NSData dataWithContentsOfFile:kPrefPath];
    NSMutableDictionary *prefs = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL];
    if(!prefs[@"speedKeys"]) prefs[@"speedKeys"]=[NSMutableArray new];
    NSMutableArray *speedKeys = prefs[@"speedKeys"];

    int i=1;
    NSString*speedKey=[NSString stringWithFormat:@"speed-%d",i];
    while(true){
      if(![speedKeys containsObject:speedKey]) break;
      speedKey=[NSString stringWithFormat:@"speed-%d",++i];
    }
    NSLog(@"new speedKey: %@",speedKey);

    [speedKeys addObject:speedKey];
    prefs[speedKey]=@1;
    [prefs writeToFile:kPrefPath atomically:YES];

    notify_post("com.brend0n.accDemo/loadPref");

    PSSpecifier* spec;
    spec = [PSSpecifier preferenceSpecifierNamed:@""
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSEditTextCell
                                                edit:Nil];
    [spec setProperty:@1 forKey:@"default"];
    [spec setProperty:@"com.brend0n.accdemo" forKey:@"defaults"];
    [spec setProperty:speedKey forKey:@"key"];
    [spec setProperty:@"com.brend0n.accdemo/loadPref" forKey:@"PostNotification"];
    [spec setProperty:@YES forKey:@"isDecimalPad"];

    NSInteger index=[self indexPathForSpecifier:[self specifierForID:@"SPEED_GROUP"]].section;
    [self insertSpecifier:spec atEndOfGroup:index animated:YES];
}
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
  PSSpecifier*spec=[self specifierAtIndexPath:indexPath];
  if([spec.properties[@"key"] hasPrefix:@"speed-"]) return YES;
  return NO;
}
// del
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
  NSLog(@"indexPath: %@",indexPath);
  PSSpecifier*spec=[self specifierAtIndexPath:indexPath];

  NSData *data = [NSData dataWithContentsOfFile:kPrefPath];
  NSMutableDictionary *prefs = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL];

  NSString*speedKey=spec.properties[@"key"];
  [prefs removeObjectForKey:speedKey];
  [prefs[@"speedKeys"] removeObject:speedKey];
  [prefs writeToFile:kPrefPath atomically:YES];

  notify_post("com.brend0n.accDemo/loadPref");

  [self removeSpecifier:spec animated:YES];
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];

    id origValue=value;
    if([specifier.properties[@"key"] hasPrefix:@"speed-"]&&[value floatValue]<0.f) value=@0.f;
    if([specifier.properties[@"key"] hasPrefix:@"speed-"]&&[value floatValue]>100.f) value=@100.f;


    [settings setObject:value forKey:specifier.properties[@"key"]];
    [settings writeToFile:path atomically:YES];

    if(value!=origValue) [self reloadSpecifier:specifier];

    CFStringRef notificationName = (__bridge CFStringRef )specifier.properties[@"PostNotification"];
    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
    }
}
-(void)showInfo{
  UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  self.navigationItem.backBarButtonItem = backItem; 
  [self.navigationController pushViewController:[[BDInfoListController alloc] init] animated:TRUE];
}
-(void)showLicenses{
  UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  self.navigationItem.backBarButtonItem = backItem; 
  [self.navigationController pushViewController:[[AccLicenseViewController alloc] init] animated:TRUE];
}
@end
