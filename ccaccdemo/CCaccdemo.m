#import "CCaccdemo.h"

@implementation CCaccdemo

//Return the icon of your module here
- (UIImage *)iconGlyph
{
  return [UIImage imageNamed:@"Smiley-Meh" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

- (UIImage *)selectedIconGlyph
{
  return [UIImage imageNamed:@"Smiley-Happy" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

//Return the color selection color of your module here
- (UIColor *)selectedColor
{
	return [UIColor blueColor];
}

- (BOOL)isSelected
{
  NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.brend0n.accdemo.plist"];
  if(!prefs) return NO;
  BOOL buttonEnabled=prefs[@"buttonEnabled"]?[prefs[@"buttonEnabled"] boolValue]:NO;
  return buttonEnabled;
}

- (void)setSelected:(BOOL)selected
{
	NSString* path=@"/var/mobile/Library/Preferences/com.brend0n.accdemo.plist";
  NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
  prefs[@"buttonEnabled"]=[NSNumber numberWithBool:selected];
  [prefs writeToFile:path atomically:YES];
  notify_post("com.brend0n.accDemo/loadPref");

  _selected = selected;
  [super refreshState];  
}

@end
