#import "BDAppListController.h"
#import <Preferences/PSSpecifier.h>
#import <AppList/AppList.h>

extern UIApplication* UIApp;

@interface PSControlTableCell : PSTableCell
@end
@interface PSSwitchTableCell : PSControlTableCell
- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(PSSpecifier*)specifier;
@end
@interface BDAPPSwitchTableCell:PSSwitchTableCell
@end
@implementation BDAPPSwitchTableCell
-(id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(PSSpecifier*)specifier { //init method
  self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier]; //call the super init method
  if (self) {
    self.detailTextLabel.text=specifier.properties[@"detail"];
  }
  return self;
}

@end


@interface BDAppListController()<UISearchControllerDelegate,UISearchBarDelegate,UISearchResultsUpdating>

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSString*searchKey;
@property (strong, nonatomic) NSString*key;
@property (strong, nonatomic) NSString*defaults;

@end

@implementation BDAppListController
-(id)initWithDefaults:(NSString*)defaults andKey:(NSString*)key{
  self=[super init];
  if(!self) return self;
  _searchKey=@"";
  _key=key;
  _defaults=defaults;
  return self;
}
-(void)loadView{
  [super loadView];

  self.navigationItem.title = @"";
  
  self.searchController = [[UISearchController alloc]initWithSearchResultsController:nil];
  self.searchController.searchResultsUpdater = self;
  if(@available(iOS 9.1, *)) self.searchController.obscuresBackgroundDuringPresentation = NO;


  if (@available(iOS 11.0, *)) {
      self.navigationItem.searchController = self.searchController;
      self.navigationItem.hidesSearchBarWhenScrolling=NO;
  } else {
      self.table.tableHeaderView = self.searchController.searchBar;
  }
    
}
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController{
  _searchKey=searchController.searchBar.text;
  [self reloadSpecifiers];
}
- (NSArray *)specifiers {
  if (!_specifiers) {
    _specifiers = [NSMutableArray arrayWithCapacity:256];
    // sort the apps by display name. displayIdentifiers is an autoreleased object.
    NSArray *sortedDisplayIdentifiers;
    NSDictionary *applications = [[ALApplicationList sharedApplicationList] applicationsFilteredUsingPredicate:[NSPredicate predicateWithFormat:@"isInternalApplication = FALSE"]
      onlyVisible:YES titleSortedIdentifiers:&sortedDisplayIdentifiers];
    // NSLog(@"app count:%lu",[applications count]);

    PSSpecifier* spec;
    for(id displayIdentifier in sortedDisplayIdentifiers){
      UIImage *icon = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:displayIdentifier];
      NSString *displayName = applications[displayIdentifier];
      if(![displayIdentifier localizedStandardContainsString:_searchKey]&&![displayName localizedStandardContainsString:_searchKey]&&![_searchKey isEqualToString:@""]) continue;
      spec = [PSSpecifier preferenceSpecifierNamed:displayName
                                              target:self
                                              set:@selector(setPreferenceValue:specifier:)
                                              get:@selector(readPreferenceValue:)
                                              detail:Nil
                                              cell:PSSwitchCell
                                              edit:Nil];
      [spec setProperty:displayIdentifier forKey:@"displayIdentifier"];
      [spec setProperty:@YES forKey:@"hasIcon"];
      [spec setProperty:icon forKey:@"iconImage"];
      [spec setProperty:_defaults forKey:@"defaults"];
      [spec setProperty:displayIdentifier forKey:@"detail"];
      [spec setProperty:NSClassFromString(@"BDAPPSwitchTableCell") forKey:@"cellClass"];
      [spec setProperty:@"com.brend0n.accdemo/loadPref" forKey:@"PostNotification"];
      
      [_specifiers addObject:spec];
        
        
    }
}

  return _specifiers;
}
- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    NSArray*apps=settings[_key];
    if(!apps) return @NO;
    return [NSNumber numberWithBool:[apps containsObject:specifier.properties[@"displayIdentifier"]]];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    NSMutableArray*apps=[settings[_key] mutableCopy];
    if(!apps) apps=[NSMutableArray new];
    NSString*displayIdentifier=specifier.properties[@"displayIdentifier"];
    if([value boolValue]&&![apps containsObject:displayIdentifier]){
      [apps addObject:displayIdentifier];
    }
    else if ([apps containsObject:displayIdentifier]){
      [apps removeObjectAtIndex:[apps indexOfObject:displayIdentifier]];
    }

    [settings setObject:apps forKey:_key];

    [settings writeToFile:path atomically:YES];
    CFStringRef notificationName = (__bridge CFStringRef )specifier.properties[@"PostNotification"];
    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
    }
}
@end