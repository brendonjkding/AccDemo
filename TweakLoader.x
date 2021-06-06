#import <string.h>
#import <dlfcn.h>
#import <crt_externs.h>

%ctor{
    // credits to https://github.com/opa334/Choicy/blob/master/Tweak.x#L38
    char *arg0 = **_NSGetArgv();

    #if TARGET_OS_SIMULATOR
    arg0 = strstr(arg0, "/RuntimeRoot")?:arg0;
    #endif

    if(strstr(arg0,"/Application") == NULL){
        return;
    }

    #if TARGET_OS_SIMULATOR
    dlopen("/opt/simject/AccDemo.dylib",RTLD_NOW);
    #else
    dlopen("/Library/MobileSubstrate/DynamicLibraries/AccDemo.dylib",RTLD_NOW);
    #endif
}