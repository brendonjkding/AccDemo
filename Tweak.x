#import <substrate.h>
#import <time.h>
#import <notify.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <dlfcn.h>

extern UIApplication* UIApp;

kern_return_t mach_vm_region
(
    vm_map_t target_task,
    mach_vm_address_t *address,
    mach_vm_size_t *size,
    vm_region_flavor_t flavor,
    vm_region_info_t info,
    mach_msg_type_number_t *infoCnt,
    mach_port_t *object_name
);

extern kern_return_t mach_vm_read
(
    vm_map_t        map,
    mach_vm_address_t   addr,
    mach_vm_size_t      size,
    pointer_t       *data,
    mach_msg_type_number_t  *data_size
);

#import "SuspendView/WQSuspendView.h"
#import "WHToast/WHToast.h"

typedef enum{
    kModeAuto=0,
    kModeGetTimeOfDay=1,
    kModeClockGetTime=2
}AccMode;


#pragma mark helper function
// thanks to https://reverseengineering.stackexchange.com/questions/15418/getting-function-address-by-reading-adrp-and-add-instruction-values

static inline uint64_t get_page_address_64(uint64_t addr, uint32_t pagesize)
{
    return addr&~0xfff;
}
static inline bool is_adrp(int32_t ins){
    return (((ins>>24)&0b11111)==0b10000) && (ins>>31);
}
static inline bool is_64add(int32_t ins){
    return ((ins>>23)&0b111111111)==0b100100010;
}
static inline uint64_t get_adrp_address(uint32_t ins,long pc){
    uint32_t instr, immlo, immhi;
    int32_t value;
    bool is_adrp=((ins>>31)&0b1)?1:0;


    instr = ins;
    immlo = (0x60000000 & instr) >> 29;
    immhi = (0xffffe0 & instr) >> 3;
    value = (immlo | immhi)|(1<<31);
    if((value>>20)&1) value|=0xffe00000;
    else value&=~0xffe00000;
    if(is_adrp) value<<= 12;
    //sign extend value to 64 bits
    if(is_adrp) return get_page_address_64(pc, PAGE_SIZE) + (int64_t)value;
    else return pc + (int64_t)value;
}
// static inline uint64_t get_b_address(uint32_t ins,long pc){
//     int32_t imm26=ins&(0x3ffffff);
//     if((ins>>25)&0b1) imm26|=0xfc000000;
//     else imm26&=~0xfc000000;
//     imm26<<=2;
//     return pc+(int64_t)imm26;
// }
static inline uint64_t get_add_value(uint32_t ins){
    uint32_t instr2=ins;

    //imm12 64 bits if sf = 1, else 32 bits
    uint64_t imm12;
    
    //get the imm value from add instruction
    instr2 = ins;
    imm12 = (instr2 & 0x3ffc00) >> 10;
    if(instr2 & 0xc00000)
    {
            imm12 <<= 12;

    }
    return imm12;
}
// static inline uint64_t get_str_imm12(uint32_t ins){
//     return 4*((ins&0x3ffc00)>>10);
// }
// helper function

static kern_return_t get_region_address_and_size(mach_vm_offset_t *address_p, mach_vm_size_t *size_p){
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name;
    kern_return_t ret = mach_vm_region(mach_task_self(), address_p, size_p, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name);
    vm_prot_t protection = info.protection;
    if(!protection){
        *address_p += *size_p;
        return get_region_address_and_size(address_p, size_p);
    }
    pointer_t buffer;
    mach_msg_type_number_t bufferSize = *size_p;
    if ((ret = mach_vm_read(mach_task_self(), *address_p, *size_p, &buffer, &bufferSize)) != KERN_SUCCESS) return ret;
    return ret;
}

#pragma mark global

static long aslr;
static WQSuspendView *button;

static float *rates;
static int rate_i;
static int rate_count;

static BOOL enabled;
static AccMode mode;
static BOOL buttonEnabled;
static BOOL toast;

static time_t pre_sec;
static suseconds_t pre_usec;
static time_t true_pre_sec;
static suseconds_t true_pre_usec;

#define USec_Scale (1000000LL)
#define NSec_Scale (1000000000LL)

#pragma mark gettimeofday
%group gettimeofday
%hookf(int, gettimeofday, struct timeval*tv, struct timezone *tz ) {
    int ret = %orig(tv,tz);
    if (!ret) {
        if(!pre_sec){
            pre_sec=tv->tv_sec;
            true_pre_sec=tv->tv_sec;
            pre_usec=tv->tv_usec;
            true_pre_usec=tv->tv_usec;
        }
        else{
            int64_t true_curSec= tv->tv_sec*USec_Scale + tv->tv_usec;
            int64_t true_preSec= true_pre_sec*USec_Scale + true_pre_usec;
            int64_t invl=true_curSec-true_preSec;
            invl*=rates[rate_i];
            
            int64_t curSec=pre_sec*USec_Scale + pre_usec;
            curSec+=invl;

            time_t used_sec = curSec/USec_Scale;
            suseconds_t used_usec = curSec%USec_Scale;

            true_pre_sec = tv->tv_sec;
            true_pre_usec = tv->tv_usec;
            tv->tv_sec = used_sec;
            tv->tv_usec = used_usec;
            pre_sec = used_sec;
            pre_usec = used_usec;
        }
    }
    return ret;
}
%end //gettimeofday

static void hook_gettimeofday(){
    void *libSystem = dlopen("/usr/lib/libSystem.dylib", RTLD_NOLOAD);
    void *gettimeofday = dlsym(libSystem, "gettimeofday");
    %init(gettimeofday,gettimeofday=gettimeofday);
}

#pragma mark clock_gettime
%group clock_gettime
%hookf(int, clock_gettime, clockid_t clk_id, struct timespec *tp){
    int ret=%orig(clk_id,tp);
    if(!ret){
        if(!pre_sec){
            pre_sec=tp->tv_sec;
            true_pre_sec=tp->tv_sec;
            pre_usec=tp->tv_nsec;
            true_pre_usec=tp->tv_nsec;
        }
        else{
            int64_t true_curSec= tp->tv_sec*NSec_Scale + tp->tv_nsec;
            int64_t true_preSec= true_pre_sec*NSec_Scale + true_pre_usec;
            int64_t invl=true_curSec-true_preSec;
            invl*=rates[rate_i];
            
            int64_t curSec=pre_sec*NSec_Scale + pre_usec;
            curSec+=invl;

            time_t used_sec = curSec/NSec_Scale;
            suseconds_t used_usec = curSec%NSec_Scale;

            true_pre_sec = tp->tv_sec;
            true_pre_usec = tp->tv_nsec;
            tp->tv_sec = used_sec;
            tp->tv_nsec = used_usec;
            pre_sec = used_sec;
            pre_usec = used_usec;

        }
    }
    return ret;
}
%end //clock_gettime

static void hook_clock_gettime(){
    void *libSystem = dlopen("/usr/lib/libSystem.dylib", RTLD_NOLOAD);
    void *clock_gettime = dlsym(libSystem, "clock_gettime");
    %init(clock_gettime,clock_gettime=clock_gettime);
}

#pragma mark unity

typedef void (*orig_t)(float);

%group unity
%hookf(void, set_timeScale, float arg1){
    NSLog(@"orig_scale: %f",arg1);
    
    arg1=rates[rate_i];
    %orig(arg1);

    NSLog(@"used scale:%f",arg1);
}
%end //unity

static long find_ad_set_timeScale(long ad_ref){
    ad_ref+=8;
    NSLog(@"ad_ref: 0x%lx",ad_ref-aslr);

    uint32_t ins=*(int*)ad_ref;
    long ad_set_timeScale=get_adrp_address(ins,ad_ref);
    NSLog(@"ad_set_timeScale: 0x%lx",ad_set_timeScale-aslr);

    return ad_set_timeScale;
}

static long find_ref_to_str(long ad_str){
    mach_vm_offset_t address=0;
    mach_vm_size_t size=0;
    while(get_region_address_and_size(&address,&size)==KERN_SUCCESS){
        if(ad_str<address){
            return false;
        }
        // NSLog(@"ref: 0x%lx 0x%lx",(long)address-aslr,(long)address+(long)size-aslr);
        for(long ad=address;ad+4<address+size;ad+=4){
            int32_t ins=*(int32_t*)ad;
            int32_t ins2=*(int32_t*)(ad+4);
            if(is_adrp(ins)&&is_64add(ins2)){
                uint64_t ad_t=get_adrp_address(ins,ad)+get_add_value(ins2);;
                if(ad_t==ad_str) return ad;
            }
        }
        address+=size;
    }
    
    return false;
}
static long find_ad_ref(){
    mach_vm_offset_t address=0;
    mach_vm_size_t size=0;
    while(get_region_address_and_size(&address,&size)==KERN_SUCCESS){
        // NSLog(@"str: 0x%lx 0x%lx",(long)address-aslr,(long)address+(long)size-aslr);
        for(long ad=address;ad<address+size;ad++){
            static const char *t="UnityEngine.Time::set_timeScale";
            if(!strcmp((const char*)(ad),t)) {
                static int count=0;
                NSLog(@"ad_str candidate %d: 0x%lx",++count,ad-aslr);
                long ad_ref=find_ref_to_str(ad);
                if(ad_ref) return ad_ref;
            }
        }
        address+=size;
    }
    
    return false;
}

static void hook_time_scale(){
    #if TARGET_OS_SIMULATOR
    return;
    #endif
    long ad_ref=find_ad_ref();

    long ad_set_timeScale=find_ad_set_timeScale(ad_ref);

    NSLog(@"hook set_timeScale start");
    %init(unity, set_timeScale=(void*)ad_set_timeScale)
    NSLog(@"hook set_timeScale success");
}

#pragma mark ui
%group ui
%hook NSBundle
+ (NSBundle *)bundleForClass:(Class)aClass{
    if(aClass==[%c(WHToastView) class]){
        return [NSBundle bundleWithPath:kBundlePath];
    }
    return %orig;
}
%end //NSBundle

%hook WQSuspendView
- (instancetype)initWithFrame:(CGRect)frame showType:(WQSuspendViewType)type tapBlock:(void (^)(void))tapBlock{
    id ret=%orig;
    button=ret;
    return ret;
}
%end //WQSuspendView

%hook UIWindow
- (void)bringSubviewToFront:(UIView *)view{
    %orig;
    if(button&&view!=button){
        [self bringSubviewToFront:button];
    }
}
- (void)addSubview:(UIView *)view{
    %orig;
    if(button&&view!=button){
        [self bringSubviewToFront:button];
    }
}
%end //UIWindow

%end //ui

%group UIAppDelegate_window
%hook UIAppDelegateClass
%new
-(id)window{
    return nil;
}
%end //UIAppDelegateClass
%end //UIAppDelegate_window

static void initHook(){
    switch(mode){
        case kModeAuto:
            if(%c(UnityAppController)){
                hook_time_scale();
            }
            else {
                hook_gettimeofday();
            }
            break;
        case kModeGetTimeOfDay:
            hook_gettimeofday();
            break;
        case kModeClockGetTime:
            hook_clock_gettime();
            break;
        default:
            break;
    }
}

static void initButton(){
    [WHToast setShowMask:NO];
    [WQSuspendView showWithType:WQSuspendViewTypeNone tapBlock:^{
        rate_i=(rate_i+1)%rate_count;
        NSLog(@"Now rates:%f",rates[rate_i]);
        if(_logos_orig$unity$set_timeScale) {
            ((orig_t)_logos_orig$unity$set_timeScale)(rates[rate_i]);
        }
        if(toast) {
            [WHToast showSuccessWithMessage:[NSString stringWithFormat:@"%f",rates[rate_i]] duration:0.5 finishHandler:^{}];
        }
    }];
    button.frame=CGRectMake(0, 200, 40, 40);
    button.backgroundColor = [UIColor blackColor];
    button.layer.cornerRadius = 20;
    button.layer.masksToBounds = YES;
    button.layer.borderWidth = 3.0;
    button.layer.borderColor = [UIColor whiteColor].CGColor;

    UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake(3,-2,34,40)];
    label.text=@"switch";
    label.textColor=[UIColor whiteColor];
    label.adjustsFontSizeToFitWidth=YES;
    [button addSubview:label];

    if(!button.superview&&[[UIApp delegate] respondsToSelector:@selector(window)]){
        [[[UIApp delegate] window] addSubview:button];
        [[[UIApp delegate] window] bringSubviewToFront:button];
    }

    if(!buttonEnabled) [button setHidden:YES];
}


static void loadFrameWork(){
    aslr=_dyld_get_image_vmaddr_slide(0);
    NSString*bundlePath=[NSString stringWithFormat:@"%@/Frameworks/UnityFramework.framework",[[NSBundle mainBundle] bundlePath]];
    NSBundle *bundle=[NSBundle bundleWithPath:bundlePath];
    [bundle load];
    if([bundle isLoaded]){
        for(int i=0;i<_dyld_image_count();i++){
            const char*image_name=_dyld_get_image_name(i);
            if(strstr(image_name, "UnityFramework.framework/UnityFramework")){
                aslr=_dyld_get_image_vmaddr_slide(i);
            }
        }
    }
    NSLog(@"aslr: 0x%lx",(long)aslr);
}

static BOOL isEnabledApp(){
    NSString* bundleIdentifier=[[NSBundle mainBundle] bundleIdentifier];
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
    enabled=prefs[@"enabled"]?[prefs[@"enabled"] boolValue]:YES;
    if(!enabled) return NO;

    return [prefs[@"apps"] containsObject:bundleIdentifier];
}
static void loadPref(){
    NSLog(@"loadPref...");
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];    
    toast=prefs[@"toast"]?[prefs[@"toast"] boolValue]:YES;
    buttonEnabled=prefs[@"buttonEnabled"]?[prefs[@"buttonEnabled"] boolValue]:YES;
    mode=prefs[@"mode"]?[prefs[@"mode"] intValue]:0;

    NSLog(@"2. app: %@",[[NSBundle mainBundle] bundleIdentifier]);
    NSLog(@"3. mode(1-3): %d",mode+1);
    NSLog(@"4. button: %d",buttonEnabled);
    NSLog(@"5. toast: %d",toast);

    NSMutableArray*speedKeys=prefs[@"speedKeys"]?:[NSMutableArray new];
    if(![speedKeys count]){
        [speedKeys addObject:@"tmp"];
        prefs[@"tmp"]=@1;
    }

    rate_i=0;
    rate_count=[speedKeys count];
    if(rates) free(rates);
    rates=malloc(sizeof(float)*rate_count);
    int i=0;
    for(NSString*speedKey in speedKeys){
        rates[i]=[prefs[speedKey] floatValue];
        NSLog(@"rate~%d: %f",i, rates[i]);
        i++;
    }

    if(button) [button setHidden:!buttonEnabled];
}
static void UIApplicationDidFinishLaunching(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
    if(![[UIApp delegate] respondsToSelector:@selector(window)]){
        %init(UIAppDelegate_window,UIAppDelegateClass=[[UIApp delegate] class]);
    }
    initButton();
    initHook();
}

#pragma mark ctor
%ctor {
    if(!isEnabledApp()) return;
    NSLog(@"-----------------");
    %init(ui);

    loadPref();
    loadFrameWork();

    int token = 0;
    notify_register_dispatch("com.brend0n.accdemo/loadPref", &token, dispatch_get_main_queue(), ^(int token) {
        loadPref();
    });
    CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, UIApplicationDidFinishLaunching, (CFStringRef)UIApplicationDidFinishLaunchingNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
}
