#import <substrate.h>
#import <time.h>
#import <notify.h>

#import "WQSuspendView/WQSuspendView.h"
#import "WHToast/WHToast.h"
#import "readmem/readmem.h"

extern intptr_t _dyld_get_image_vmaddr_slide(uint32_t image_index);

#define AUTO 0
#define GETTIMEOFDAY 1
#define CLOCKGETTIME 2

long aslr;
//conf
float rates[4];
int rate_i=0;
int rate_count=0;
bool toast=0;
bool enabled=0;
bool buttonEnabled=0;
int mode=0;

time_t pre_sec=0;
suseconds_t pre_usec=0;
time_t true_pre_sec=0;
suseconds_t true_pre_usec=0;

#define USec_Scale (1000000LL)
static int (*orig_gettimeofday)(struct timeval * __restrict, void * __restrict);
static int mygettimeofday(struct timeval*tv,struct timezone *tz ) {
	int ret = orig_gettimeofday(tv,tz);
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

static int (*orig_clock_gettime)(clockid_t clk_id, struct timespec *tp);
static int myclock_gettime(clockid_t clk_id, struct timespec *tp){
	//NSLog(@"clock_gettime called");
    int ret=orig_clock_gettime(clk_id,tp);
    if(!ret){
        if(!pre_sec){
			pre_sec=tp->tv_sec;
			true_pre_sec=tp->tv_sec;
			pre_usec=tp->tv_nsec;
			true_pre_usec=tp->tv_nsec;
		}
		else{
			int64_t true_curSec= tp->tv_sec*USec_Scale + tp->tv_nsec;
			int64_t true_preSec= true_pre_sec*USec_Scale + true_pre_usec;
			int64_t invl=true_curSec-true_preSec;
			invl*=rates[rate_i];
			
			int64_t curSec=pre_sec*USec_Scale + pre_usec;
			curSec+=invl;

			time_t used_sec = curSec/USec_Scale;
			suseconds_t used_usec = curSec%USec_Scale;

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

WQSuspendView *button=0;
float orig_scale=0;
long scale_arg1=0;
float last_scale=1;
// float cur_scale=1;

static long (*orig_get_scale)(void);
float my_get_scale(void){
	// NSLog(@"my scale called");
	return last_scale;
}

static long (*orig_time_init)(long arg1,long arg2, long arg3, long arg4, long arg5);
long my_time_init(long arg1,long arg2, long arg3, long arg4, long arg5){
	NSLog(@"my_time_init called");
	// NSLog(@"arg1=0x%lx arg2=0x%lx arg3=0x%lx arg4=0x%lx arg5=0x%lx",
		// arg1,arg1,arg3,arg4,arg5);
	scale_arg1=arg1;
	orig_scale=1;
	return orig_time_init(arg1,arg2,arg3,arg4,arg5);
}

static void (*orig_time_scale)(long arg1,float arg2)=0;
void my_time_scale(long arg1,float arg2){
	NSLog(@"my_time_scale called");
	NSLog(@"scale:%f",arg2);
	
	// if(!scale_arg1) scale_arg1=arg1;
	// if(!orig_scale&&arg2) orig_scale=arg2;
	if(arg2) arg2=orig_scale*rates[rate_i];
	// else orig_scale=0;
	orig_time_scale(arg1,arg2);

	NSLog(@"used scale:%f",arg2);
	
	last_scale=arg2;

	// NSLog(@"%lx",arg1);
	// float* p=(float*)(arg1+0xcc);
}

bool hook_gettimeofday(){
	void* gettimeofday=(void *)MSFindSymbol(NULL,"_gettimeofday");
	if(gettimeofday) {
		MSHookFunction(gettimeofday, (void *)mygettimeofday, (void **)&orig_gettimeofday);
		NSLog(@"11. hook gettimeofday success");
		return true;
	}
	else {
		NSLog(@"11. hook gettimeofday failed");
		return false;
	}
}
bool hook_clock_gettime(){
	void* clock_gettime=(void *)MSFindSymbol(NULL,"_clock_gettime");
	if(clock_gettime) {
		MSHookFunction(clock_gettime, (void *)myclock_gettime, (void **)&orig_clock_gettime);
		NSLog(@"11. hook clock_gettime success");
		return true;
	}
	else {
		NSLog(@"11. hook clock_gettime failed");
		return false;
	}
}
long is_time_init(long buffer,int size,long pc){
	if(size<8)return 0;
	if((*(uint64_t*)(buffer))==0xb900967f9100a260){
		for(int j=4;j<0x78;j+=4){
			if((*(uint16_t*)(buffer-j))==0x4ff4){
				long ad=pc-j;
				NSLog(@"time_init:0x%lx",ad-aslr);
				return ad;
			}
		}
	}
	return 0;
}
long is_time_scale(long buffer,int size,long pc){
	if(size<11) return 0;
	if((*(uint64_t*)(buffer))==0x5400006b1e202008&&(*(uint16_t*)(buffer+8))==0xcc00&&(*(char*)(buffer+10))==0x00){
		long ad=pc-0x10;
		NSLog(@"time_scale:0x%lx",ad-aslr);
		return ad;
	}
	return 0;
}
long is_time_init_18(long buffer,int size,long pc){
	if(size<20)return 0;
	if((*(uint64_t*)(buffer))==0xf900026891004108&&(*(uint64_t*)(buffer+8))==0xa9037e7fb9005a7f&&(*(uint32_t*)(buffer+16))==0xb9007a7f){
		long ad=pc-0x24;
		NSLog(@"time_init_18:0x%lx",ad-aslr);
		return ad;
	}
	return 0;
}
long is_time_scale_18(long buffer,int size,long pc){
	if(size<8) return 0;
	if((*(uint32_t*)(buffer))==0x1e202008&&(*(uint32_t*)(buffer+8))==0xf90003ff){
		long ad=pc-0x20;
		NSLog(@"time_scale_18:0x%lx",ad-aslr);
		return ad;
	}
	//2017
	if(size<10) return 0;
	if((*(uint64_t*)(buffer))==0x5400006b1e202008&&(*(uint8_t*)(buffer+8))==0x00&&(*(char*)(buffer+10))==0x00){
		long ad=pc-0x10;
		NSLog(@"time_scale_17:0x%lx",ad-aslr);
		return ad;
	}
	return 0;
}

mach_vm_offset_t main_address=0;
long main_size=0;
long scan(long (*op)(long,int,long)){
	kern_return_t kret;
	mach_port_t task=mach_task_self(); // type vm_map_t = mach_port_t in mach_types.defs
	mach_vm_offset_t address = 0;
	mach_vm_size_t size;
	mach_port_t object_name;
	vm_region_basic_info_data_64_t info;
	mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;

	address=main_address;
	while (mach_vm_region(task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS)
	{
		if(address-main_address>main_size) break;
		NSLog(@"mach_vm_region ad:0x%llx, %llu",address-aslr,size);
		pointer_t buffer;
		mach_msg_type_number_t bufferSize = size;
		if ((kret = mach_vm_read(task, (mach_vm_address_t)address, size, &buffer, &bufferSize)) == KERN_SUCCESS)
		{
			for(int i=0;i<size;i++){
				long ad=op(buffer+i,size-i,address+i);
				if(ad) return ad;
			}	
		}
		address+=size;
	}
	return 0;
}

bool hook_time_scale(){
	find_main_binary(mach_task_self(),&main_address);
	main_size=get_image_size(main_address,mach_task_self());
	NSLog(@"8. main: 0x%llx size: %ldMB",main_address-aslr,main_size/1024/1024);
	
	long time_init=0,time_scale=0;
	time_init=scan(is_time_init);
	time_scale=scan(is_time_scale);
	
	if(time_init&&time_scale) NSLog(@"9. Unity5");
	else{
		time_init=scan(is_time_init_18);
		time_scale=scan(is_time_scale_18);
		if(time_init&&time_scale) NSLog(@"9. Unity2018");
		else{
			NSLog(@"11. hook time_init/scale failed");
			return false;
		}
	}


	NSLog(@"10. time_init:0x%0lx, time_scale:0x%0lx",time_init-aslr, time_scale-aslr);
	MSHookFunction((void *)time_init, (void *)my_time_init, (void **)&orig_time_init);
	MSHookFunction((void *)time_scale, (void *)my_time_scale, (void **)&orig_time_scale);
	// MSHookFunction((void *)aslr+0x10251938c, (void *)my_get_scale, (void **)&orig_get_scale);
	NSLog(@"11. hook time_init/scale success");
	return true;
	
}
BOOL (*orig_application_didFinishLaunchingWithOptions)(id self, SEL _cmd,UIApplication* application,NSDictionary*launchOptions );
BOOL new_application_didFinishLaunchingWithOptions(id self, SEL _cmd,UIApplication* application,NSDictionary*launchOptions ){
	NSLog(@"12. %@ hooked", [self class]);
	BOOL ret=orig_application_didFinishLaunchingWithOptions(self, @selector(application:didFinishLaunchingWithOptions:),application,launchOptions);
	button=[WQSuspendView showWithType:WQSuspendViewTypeNone tapBlock:^{
		rate_i=(rate_i+1)%rate_count;
		NSLog(@"Now rates:%f",rates[rate_i]);
		if(orig_time_scale) orig_time_scale(scale_arg1,orig_scale*rates[rate_i]);
		if(toast)[WHToast showSuccessWithMessage:[NSString stringWithFormat:@"%f",rates[rate_i]] duration:0.5 finishHandler:^{}];
	}];
	if(!buttonEnabled) [button setHidden:YES];
	return ret;
}
%hook UIApplication
-(void) setDelegate:(id) delegate{
	// NSLog(@"setDelegate hooked");
	const char*class_name=[[NSString stringWithFormat:@"%@",[delegate class]] UTF8String];
	MSHookMessageEx(objc_getClass(class_name),
					@selector(application:didFinishLaunchingWithOptions:),
					(IMP)&new_application_didFinishLaunchingWithOptions,
					(IMP*)&orig_application_didFinishLaunchingWithOptions);
	%orig;
}
%end

%hook UIWindow
- (void)bringSubviewToFront:(UIView *)view{
	%orig;
	if(button&&view!=button)
		[self bringSubviewToFront:button];
}
- (void)addSubview:(UIView *)view{
	%orig;
	if(button&&view!=button)
		[self bringSubviewToFront:button];
}
%end //UIWindow

bool loadPref(){
	NSLog(@"loading pref...");
	NSString* bundleIdentifier=[[NSBundle mainBundle] bundleIdentifier];
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.brend0n.accdemo.plist"];
	
	NSArray *apps=prefs?prefs[@"apps"]:nil;
	if(!apps) return false;
	enabled=[prefs[@"enabled"] boolValue]==YES?1:0;
	if(!enabled) return false;
	toast=[prefs[@"toast"] boolValue]==YES?1:0;
	buttonEnabled=[prefs[@"buttonEnabled"] boolValue]==YES?1:0;
	mode=[prefs[@"mode"] intValue];
	if(![apps containsObject:bundleIdentifier]) return false;
	aslr=_dyld_get_image_vmaddr_slide(0);
	NSLog(@"0. start");
	NSLog(@"1. ASLR=0x%lx",aslr);
	NSLog(@"2. app: %@",bundleIdentifier);
	NSLog(@"3. mode(1-3): %d",mode+1);
	NSLog(@"4. button: %d",buttonEnabled);
	NSLog(@"5. toast: %d",toast);
	rate_i=0;
	rate_count=0;
	for(int i=0;i<3;i++){
		NSString *key=[[NSString alloc] initWithFormat:@"rate%d",i+1];
		NSString *item=prefs[key];
		if(item){
			float rate=[item floatValue];
			if(rate>=0&&rate<=100.0&&rate!=1.0){
				rates[rate_count++]=rate;
			}
		}
	}
	// if(!rate_count) return false;
	rates[rate_count++]=1.0;
	NSLog(@"6. rates:%f, %f, %f. num=%d",rates[0],rates[1],rates[2],rate_count);

	if(button) [button setHidden:buttonEnabled?NO:YES];
	return true;
}
%ctor {
	NSLog(@"-----construct------");
	if(loadPref()){
		%init(_ungrouped);
		if (objc_getClass("UnityAppController")) {
			NSLog(@"7. Unity app");
			if(mode==AUTO) {if(!hook_time_scale()) hook_gettimeofday();}
			else if(mode==GETTIMEOFDAY) hook_gettimeofday();
			else if(mode==CLOCKGETTIME) hook_clock_gettime();
		}
		else{
			if (objc_getClass("EAGLView")||objc_getClass("CCEAGLView")) NSLog(@"7. cocos2d app");
			else  NSLog(@"7. other app");
			if(mode==AUTO) {if(!hook_gettimeofday()) hook_clock_gettime();}
			else if(mode==GETTIMEOFDAY) hook_gettimeofday();
			else if(mode==CLOCKGETTIME) hook_clock_gettime();
		}
		int token = 0;
		notify_register_dispatch("com.brend0n.accDemo/loadPref", &token, dispatch_get_main_queue(), ^(int token) {
    		loadPref();
		});
	}
}
