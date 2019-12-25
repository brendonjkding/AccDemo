#import <substrate.h>
#import <time.h>
#import <Foundation/Foundation.h>
#import "WQSuspendView.h"
#import "WHToast/WHToast.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <mach/mach.h>
#include <sys/sysctl.h>

extern kern_return_t
mach_vm_read(
	vm_map_t		map,
	mach_vm_address_t	addr,
	mach_vm_size_t		size,
	pointer_t		*data,
	mach_msg_type_number_t	*data_size);

extern kern_return_t
mach_vm_write(
	vm_map_t			map,
	mach_vm_address_t		address,
	pointer_t			data,
	__unused mach_msg_type_number_t	size);

extern kern_return_t
mach_vm_region(
	vm_map_t		 map,
	mach_vm_offset_t	*address,
	mach_vm_size_t		*size,		
	vm_region_flavor_t	 flavor,
	vm_region_info_t	 info,		
	mach_msg_type_number_t	*count,	
	mach_port_t		*object_name);

extern kern_return_t mach_vm_protect(vm_map_t, mach_vm_address_t, mach_vm_size_t, boolean_t, vm_prot_t);
extern intptr_t _dyld_get_image_vmaddr_slide(uint32_t image_index);

#define AUTO 0
#define GETTIMEOFDAY 1
#define CLOCKGETTIME 2

float rates[4];
int rate_i=0;
int rate_count=0;
bool toast=0;
bool enabled=0;
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



			// time_t used_sec = pre_sec + (tv->tv_sec - true_pre_sec) * rates[rate_i];
			// suseconds_t used_usec = pre_usec + (tv->tv_usec - true_pre_usec) * rates[rate_i];
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
			// time_t used_sec = pre_sec + (tp->tv_sec - true_pre_sec) * rates[rate_i];
			// suseconds_t used_usec = pre_usec + (tp->tv_nsec - true_pre_usec) * rates[rate_i];
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

static long (*orig_time_init)(long arg1,long arg2, long arg3, long arg4, long arg5);
long my_time_init(long arg1,long arg2, long arg3, long arg4, long arg5){
	NSLog(@"my_time_init called");
	// NSLog(@"arg1=0x%lx arg2=0x%lx arg3=0x%lx arg4=0x%lx arg5=0x%lx",
	// 	arg1,arg1,arg3,arg4,arg5);
	return orig_time_init(arg1,arg2,arg3,arg4,arg5);
}

static void (*orig_time_scale)(long arg1,float arg2);
void my_time_scale(long arg1,float arg2){
	NSLog(@"my_time_scale called");
	NSLog(@"scale:%f",arg2);
	
	if(!scale_arg1) scale_arg1=arg1;
	if(!orig_scale&&arg2) orig_scale=arg2;
	if(arg2&&arg2!=1.0) arg2=orig_scale*rates[rate_i];
	else orig_scale=0;
	orig_time_scale(arg1,arg2);

	if(arg2)NSLog(@"used scale:%f",arg2);
	
	
	// float* p=(float*)(arg1+0xcc);
}

bool hook_gettimeofday(){
	void* gettimeofday=(void *)MSFindSymbol(NULL,"_gettimeofday");
	if(gettimeofday) {
		MSHookFunction(gettimeofday, (void *)mygettimeofday, (void **)&orig_gettimeofday);
		NSLog(@"hook gettimeofday success");
		return true;
	}
	else {
		NSLog(@"hook gettimeofday failed");
		return false;
	}
}
bool hook_clock_gettime(){
	void* clock_gettime=(void *)MSFindSymbol(NULL,"_clock_gettime");
	if(clock_gettime) {
		MSHookFunction(clock_gettime, (void *)myclock_gettime, (void **)&orig_clock_gettime);
		NSLog(@"hook clock_gettime success");
		return true;
	}
	else {
		NSLog(@"hook clock_gettime failed");
		return false;
	}
}

bool hook_time_scale(){
	bool flag1=0,flag2=0;
	kern_return_t kret;
	mach_port_t task=mach_task_self(); // type vm_map_t = mach_port_t in mach_types.defs
	mach_vm_offset_t address = 0;
	mach_vm_size_t size;
	mach_port_t object_name;
	vm_region_basic_info_data_64_t info;
	mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
	int occurranceCount = 0;
	long realAddress=0;
	char oldValue[20]; // change type: unsigned int, long, unsigned long, etc. Should be customizable!
	unsigned long length;

	if(true){
		oldValue[0]=0x60;
		oldValue[1]=0xa2;
		oldValue[2]=0x00;
		oldValue[3]=0x91;
		oldValue[4]=0x7f;
		oldValue[5]=0x96;
		oldValue[6]=0x00;
		oldValue[7]=0xb9;
		length=8;
		printf("test:%lu\n",length);
	}
	while (mach_vm_region(task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS)
	{
		//NSLog(@"mach_vm_region success");
		pointer_t buffer;
		mach_msg_type_number_t bufferSize = size;
		vm_prot_t protection = info.protection;
		if ((kret = mach_vm_read(task, (mach_vm_address_t)address, size, &buffer, &bufferSize)) == KERN_SUCCESS)
		{
			//NSLog(@"mach_vm_read success");
			void *substring = NULL;
			if ((substring = memmem((const void *)buffer, bufferSize, oldValue, length)) != NULL)
			{
				occurranceCount++;
				long i;
				for(i=4;i<0x78;i+=4){
					unsigned int c=(*(char *)(substring-i))&0xff;
					unsigned int c2=(*(char *)(substring-i+1))&0xff;
					unsigned int c3=(*(char *)(substring-i+2))&0xff;
					unsigned int c4=(*(char *)(substring-i+3))&0xff;
					NSLog(@"%x %x %x %x",c,c2,c3,c4);
					if(c==0xf4&&c2==0x4f){
						flag1=1;
						break;
					}
				}
				
				realAddress = (long)substring - (long)buffer + (long)address - i;
				//printf("Search result %2d: %s at 0x%0lx (%s)\n", occurranceCount, oldValue, realAddress, (protection & VM_PROT_WRITE) != 0 ? "writable" : "non-writable");
				NSLog(@"Search result %2d: %s at 0x%0lx (%s)\n", occurranceCount, oldValue, realAddress, (protection & VM_PROT_WRITE) != 0 ? "writable" : "non-writable");
				break;
				
			}
		}
		address+=size;
	}
	long loc1=realAddress;
	


	if(true){
		oldValue[0]=0x08;
		oldValue[1]=0x20;
		oldValue[2]=0x20;
		oldValue[3]=0x1e;
		oldValue[4]=0x6b;
		oldValue[5]=0x00;
		oldValue[6]=0x00;
		oldValue[7]=0x54;
		oldValue[8]=0x00;
		oldValue[9]=0xcc;
		oldValue[10]=0x00;
		length=11;
		printf("test2:%lu\n",length);
	}
	while (mach_vm_region(task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS)
	{
		//NSLog(@"mach_vm_region success");
		pointer_t buffer;
		mach_msg_type_number_t bufferSize = size;
		vm_prot_t protection = info.protection;
		if ((kret = mach_vm_read(task, (mach_vm_address_t)address, size, &buffer, &bufferSize)) == KERN_SUCCESS)
		{
			//NSLog(@"mach_vm_read success");
			void *substring = NULL;
			if ((substring = memmem((const void *)buffer, bufferSize, oldValue, length)) != NULL)
			{
				occurranceCount++;
				realAddress = (long)substring - (long)buffer + (long)address;
				//printf("Search result %2d: %s at 0x%0lx (%s)\n", occurranceCount, oldValue, realAddress, (protection & VM_PROT_WRITE) != 0 ? "writable" : "non-writable");
				NSLog(@"Search result %2d: %s at 0x%0lx (%s)\n", occurranceCount, oldValue, realAddress, (protection & VM_PROT_WRITE) != 0 ? "writable" : "non-writable");
				flag2=1;
				break;
			}
		}
		address+=size;
	}
	long loc2=realAddress-0x10;
	
	NSLog(@"ad1:0x%0lx, ad2:0x%0lx",loc1,loc2);
	
	if (flag1&&flag2){
		//loc1=_dyld_get_image_vmaddr_slide(0) +0x10177e980;
		//loc2=_dyld_get_image_vmaddr_slide(0) +0x10177edf8;
		MSHookFunction((void *)loc1, (void *)my_time_init, (void **)&orig_time_init);
		MSHookFunction((void *)loc2, (void *)my_time_scale, (void **)&orig_time_scale);
		NSLog(@"hook time_init/scale success");
		return true;
	}
	else{
		NSLog(@"hook time_init/scale failed: %d, %d",flag1,flag2);
		return false;
	}
}


%group unity
%hook UnityAppController
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions{
	BOOL ret=%orig(application,launchOptions);
	NSLog(@"UnityAppController hooked");
	button=[WQSuspendView showWithType:WQSuspendViewTypeNone tapBlock:^{
		rate_i=(rate_i+1)%rate_count;
		if(orig_time_scale) orig_time_scale(scale_arg1,orig_scale*rates[rate_i]);
		NSLog(@"Now rates:%f",rates[rate_i]);
		if(toast)[WHToast showSuccessWithMessage:[NSString stringWithFormat:@"%f",rates[rate_i]] duration:0.5 finishHandler:^{}];
	}];

	return ret;
}
%end //UnityAppController
%end //unity

%group cocos2d
%hook AppController
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions{
	BOOL ret=%orig(application,launchOptions);
	if(button) return ret;
	NSLog(@"AppController hooked");
	button=[WQSuspendView showWithType:WQSuspendViewTypeNone tapBlock:^{
		rate_i=(rate_i+1)%rate_count;
		NSLog(@"Now rates:%f",rates[rate_i]);
		if(toast)[WHToast showSuccessWithMessage:[NSString stringWithFormat:@"%f",rates[rate_i]] duration:0.5 finishHandler:^{}];
	}];

	return ret;
}
%end //AppController

%hook AppDelegate
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions{
	BOOL ret=%orig(application,launchOptions);
	if(button) return ret;
	NSLog(@"AppDelegate hooked");
	button=[WQSuspendView showWithType:WQSuspendViewTypeNone tapBlock:^{
		rate_i=(rate_i+1)%rate_count;
		NSLog(@"Now rates:%f",rates[rate_i]);
		if(toast)[WHToast showSuccessWithMessage:[NSString stringWithFormat:@"%f",rates[rate_i]] duration:0.5 finishHandler:^{}];
	}];

	return ret;
}
%end //AppDelegate
%end //cocos2d

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

%ctor {
	NSLog(@"construct--------------------------------------");

	//prefs
	NSString* bundleIdentifier=[[NSBundle mainBundle] bundleIdentifier];
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.brend0n.accdemo.plist"];
	if(prefs){	
		NSArray *apps=prefs[@"apps"];
		enabled=[prefs[@"enabled"] boolValue]==YES?1:0;
		toast=[prefs[@"toast"] boolValue]==YES?1:0;
		mode=[prefs[@"mode"] intValue];
		if(apps&&enabled)
			if([apps containsObject:bundleIdentifier]){
				NSLog(@"ASLR=0x%lx",_dyld_get_image_vmaddr_slide(0));
				NSLog(@"app:%@",bundleIdentifier);
				NSLog(@"mode(1-3):%d",mode+1);
				for(int i=0;i<3;i++){
					NSString *key=[[NSString alloc] initWithFormat:@"rate%d",i+1];
					NSString *item=prefs[key];
					if(item){
						float rate=[item floatValue];
						if(rate&&rate<100.0&&rate!=1.0){
							rates[rate_count++]=rate;
						}
					}
				}		
				if(rate_count){
					rates[rate_count++]=1.0;
					NSLog(@"rates:%f, %f, %f. num=%d",rates[0],rates[1],rates[2],rate_count);
					%init(_ungrouped);
					

					if (objc_getClass("UnityAppController")) {
						NSLog(@"Unity app");
						%init(unity);
						if(mode==AUTO) {if(!hook_time_scale()) hook_gettimeofday();}
						else if(mode==GETTIMEOFDAY) hook_gettimeofday();
						else if(mode==CLOCKGETTIME) hook_clock_gettime();
					}
					else if (objc_getClass("EAGLView")||objc_getClass("CCEAGLView")){
						NSLog(@"cocos2d app");
						%init(cocos2d);
						if(mode==AUTO) {if(!hook_gettimeofday()) hook_clock_gettime();}
						else if(mode==GETTIMEOFDAY) hook_gettimeofday();
						else if(mode==CLOCKGETTIME) hook_clock_gettime();
					}
					
				}

			}
			
		}
	}