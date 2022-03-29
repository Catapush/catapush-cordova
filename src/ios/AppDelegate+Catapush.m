#import "AppDelegate.h"
#import <objc/runtime.h>
#import "Catapush.h"

@implementation AppDelegate (Catapush)

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Catapush registerForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [Catapush applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    NSError *error;
    [Catapush applicationWillEnterForeground:application withError:&error];
    if (error != nil) {
        // API KEY, USERNAME or PASSWORD not set
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [Catapush applicationDidBecomeActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [Catapush applicationWillTerminate:application];
}

@end
