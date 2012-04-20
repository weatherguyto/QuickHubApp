//
//  Preferences.m
//  GHApp
//
//  Created by Christophe Hamerling on 12/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "Preferences.h"
#import "QHConstants.h"

static Preferences *sharedInstance = nil;

@implementation Preferences

- (id)init
{
    self = [super init];
    if (self) {
    }
    
    return self;
}

-(void)setDefault {
    [self storeLogin:@"" withPassword:@""];
}

- (void) setStandardUserDefault {
    
    // Set some default values for preferences. The framework will use them if they are not already set.
    // If they are, they will be ignored.
    
    NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableDictionary * states = [NSMutableDictionary dictionaryWithCapacity:18];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHCommitCommentEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHCreateEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHDeleteEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHDownloadEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHFollowEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHForkApplyEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHForkEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHGistEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHGollumEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHIssueCommentEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHIssuesEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHMemberEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHPublicEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHPullRequestEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHPullRequestReviewCommentEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHPushEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHTeamAddEvent];
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHWatchEvent];
    
    [states setObject:[NSNumber numberWithBool:YES] forKey:GHEventActive];
    

    [userdefaults registerDefaults:states];
}

- (NSString *)login {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *result = [prefs stringForKey:@"userID"];
    if (!result) {
        result = [NSString stringWithString:@""];
    }
    return result;
}

- (NSString *)password {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *result = [prefs stringForKey:@"pwd"];

    if (!result) {
        result = [NSString stringWithString:@""];
    }
    return result;
}

- (NSString *)oauthToken {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *result = [prefs stringForKey:@"oauth"];
    
    if (!result) {
        result = [NSString stringWithString:@""];
    }
    return result;
}

- (void) storeLogin:(NSString*)login withPassword:(NSString*)password{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:login forKey:@"userID"];
    [prefs setObject:password forKey:@"pwd"];
}

- (void) deleteOldPreferences {
    [self setDefault];
}

- (void) storeToken:(NSString*)token {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:token forKey:@"oauth"];
}

- (void) put:(NSString *) key value:(id) value {
    if (!key) {
        return;
    }
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:value forKey:[NSString stringWithFormat:@"%@.%@", APP_PREFIX, key]];
}

- (id) get:(NSString *) key {
    if (!key) {
        return nil;
    }
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs valueForKey:[NSString stringWithFormat:@"%@.%@", APP_PREFIX, key]];    
}

+ (Preferences *)sharedInstance {
    @synchronized(self) {
        if (sharedInstance == nil)
            sharedInstance = [[Preferences alloc] init];
    }
    return sharedInstance;
}

@end
