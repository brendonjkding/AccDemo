#import <Preferences/PSListController.h>
%group PSListController
%hook PSListController
%new
-(id)indexPathForSpecifier:(id)arg1{
    return [self indexPathForIndex:[self.specifiers indexOfObject:arg1]];
}
%new
-(id)specifierAtIndexPath:(id)arg1{
    return self.specifiers[[self indexForIndexPath:arg1]];
}
%end
%end// PSListController
%group UIImage
%hook UIImage
%new
+ (UIImage *)imageNamed:(NSString *)name 
               inBundle:(NSBundle *)bundle 
compatibleWithTraitCollection:(UITraitCollection *)traitCollection{
    return nil;
}
%end //UIImage
%end //UIImage

%hook NSString
%group localizedCaseInsensitiveContainsString
%new
-(BOOL)localizedStandardContainsString:(NSString*)string{
  return [self localizedCaseInsensitiveContainsString:string];
}
%end //localizedCaseInsensitiveContainsString
%group rangeOfString
%new
-(BOOL)localizedStandardContainsString:(NSString*)string{
  return [self rangeOfString:string].length!=0;
}
%end //rangeOfString
%end //NSString

%ctor{
    if(![[PSListController alloc] respondsToSelector:@selector(specifierAtIndexPath:)]){
        %init(PSListController);
    }
    if(![UIImage respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]){
        %init(UIImage);
    }
    if(![@"" respondsToSelector:@selector(localizedStandardContainsString:)]){
        if([@"" respondsToSelector:@selector(localizedCaseInsensitiveContainsString:)]){
          %init(localizedCaseInsensitiveContainsString);
        }
        else{
          %init(rangeOfString);
        }
    }
}