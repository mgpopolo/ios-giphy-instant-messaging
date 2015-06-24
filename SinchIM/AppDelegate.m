#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [[NSNotificationCenter defaultCenter]
      addObserverForName:@"UserDidLoginNotification"
                  object:nil
                   queue:nil
              usingBlock:^(NSNotification *note) { [self initSinchClientWithUserId:note.userInfo[@"userId"]]; }];
  return YES;
}

#pragma mark -

- (void)initSinchClientWithUserId:(NSString *)userId {
  if (!_client) {
    _client = [Sinch clientWithApplicationKey:@"d786d626-322a-4abd-93a1-37eb5d55a7de"
                            applicationSecret:@"5UFE93UqR0+idexRHSHTpQ=="
                              environmentHost:@"sandbox.sinch.com"
                                       userId:userId];

    _client.delegate = self;

    [_client setSupportMessaging:YES];

    [_client start];
    [_client startListeningOnActiveConnection];
  }
}

#pragma mark - SINClientDelegate

- (void)clientDidStart:(id<SINClient>)client {
  NSLog(@"Sinch client started successfully (version: %@)", [Sinch version]);
}

- (void)clientDidFail:(id<SINClient>)client error:(NSError *)error {
  NSLog(@"Sinch client error: %@", [error localizedDescription]);
}

- (void)client:(id<SINClient>)client
    logMessage:(NSString *)message
          area:(NSString *)area
      severity:(SINLogSeverity)severity
     timestamp:(NSDate *)timestamp {

  if (severity == SINLogSeverityCritical) {
    NSLog(@"%@", message);
  }
}

@end
