#import "AccLicenseViewController.h"

@implementation AccLicenseViewController
-(void)loadView{
	[super loadView];
    self.navigationItem.title = @"Licenses";
    UITextView*textView=[UITextView new];
    [textView setFrame:[self.view frame]];

    NSString*licenses=[NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/licenses.txt",kBundlePath] encoding:NSUTF8StringEncoding error:nil];
    [textView setText:licenses];

    [self.view addSubview:textView];
    
}
@end