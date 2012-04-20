//
//  EventsManager.m
//  QuickHub
//
//  Created by Christophe Hamerling on 15/04/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "EventsManager.h"
#import "Preferences.h"
#import "GrowlManager.h"
#import "QHConstants.h"

@interface EventsManager (Private)
- (void) notifyNewEvent:(NSDictionary *) event;
- (BOOL) notificationActive:(NSString *) eventType;
- (BOOL) isNotificationsActive;
@end

@implementation EventsManager

- (id)init
{
    self = [super init];
    if (self) {
        events = [[NSMutableArray alloc] init];
        eventIds = [[NSMutableSet alloc] init];
    }
    
    return self;
}

- (void) addEventsFromDictionary:(NSDictionary *) dict {
    
    BOOL firstCall = ([events count] == 0);
    
    NSMutableDictionary *arrangedEvents = [[NSMutableDictionary alloc] init];

    NSMutableSet* justGet = [[[NSMutableSet alloc] init] autorelease];
    for (NSDictionary *event in dict) {
        [justGet addObject:[event valueForKey:@"id"]];
        [arrangedEvents setObject:event forKey:[event valueForKey:@"id"]];
    }
    
    // diff events with the already cached ones
    NSMutableSet* newEvents = [NSMutableSet setWithSet:justGet];
    [newEvents minusSet:eventIds];
        
    // cache new events
    for (id eventId in newEvents) {
        [eventIds addObject:eventId];
        [events addObject:[arrangedEvents objectForKey:eventId]];
    }
    
    if ([newEvents count] > 0 && [self isNotificationsActive]) {
        // send some notifications...
        
        int nbEvents = 10;
        if ([newEvents count] >= nbEvents) {
            // limit the number of events per configuration...
            
            if (!firstCall) {
                [[GrowlManager get] notifyWithName:@"GitHub Event" desc:[NSString stringWithFormat:@"%d new events...", [newEvents count]] url:nil icon:nil];
            }
        } else {
            // loop...
            // TODO : need to order events by date with the "created_at" element
            for (id eventId in newEvents) {
                NSDictionary *event = [arrangedEvents objectForKey:eventId];
                if (event) {
                    [self notifyNewEvent:event];
                }
            }
        }
    }
}

- (NSArray *) getEvents {
    return events;  
}

- (void) clearEvents {
    events = [[NSMutableArray alloc] init];
    eventIds = [[NSMutableSet alloc] init];
}

- (void) notifyNewEvent:(NSDictionary *) event {
    if (!event) {
        return;
    }
    
    NSString *type = [event valueForKey:@"type"];
    
    if (!type) {
        return;
    }
        
    if ([CommitCommentEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSString *message = [NSString stringWithFormat:@"%@ commented on %@", actorLogin, repository];
        NSString *url = [[[event valueForKey:@"payload"] valueForKey:@"comment"] valueForKey:@"html_url"];
        
        if ([self notificationActive:GHCommitCommentEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:url icon:nil];
        }
        
    } else if ([CreateEvent isEqualToString:type]) {
                
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSNumber *refType = [[event valueForKey:@"payload"] valueForKey:@"ref_type"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSString *message = [NSString stringWithFormat:@"%@ created %@ %@", actorLogin, refType, repository];
         
        if ([self notificationActive:GHCreateEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:nil iconName:@"octocat-128"];
        }
        // TODO check message format for repository, branch and tag. This one works for repository
        
    } else if ([DeleteEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSNumber *refType = [[event valueForKey:@"payload"] valueForKey:@"ref_type"];
        NSString *ref = [[event valueForKey:@"payload"] valueForKey:@"ref"];
        NSString *message = [NSString stringWithFormat:@"%@ deleted %@ from %@", actorLogin, refType, ref];
        
        if ([self notificationActive:GHDeleteEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:nil iconName:@"octocat-128"];
        }
        
    } else if ([DownloadEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *filename = [[[event valueForKey:@"payload"] valueForKey:@"download"] valueForKey:@"name"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSString *message = [NSString stringWithFormat:@"%@ uploaded %@ to %@", actorLogin, filename, repository];
        
        if ([self notificationActive:GHDownloadEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:nil iconName:@"octocat-128"];
        }

    } else if ([FollowEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *target = [[[event valueForKey:@"payload"] valueForKey:@"target"] valueForKey:@"login"];
        NSString *message = [NSString stringWithFormat:@"%@ started following %@", actorLogin, target];
        
        if ([self notificationActive:GHFollowEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:nil iconName:@"octocat-128"];
        }
        
    } else if ([ForkEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSString *message = [NSString stringWithFormat:@"%@ forked %@", actorLogin, repository];
        
        if ([self notificationActive:GHForkEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:nil iconName:@"octocat-128"];
        }
        
    } else if ([ForkApplyEvent isEqualToString:type]) {
        
        // tested but can not find when it happens
        // forked and merged, nothing...
        /*
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSString *message = [NSString stringWithFormat:@"%@ applied fork %@", actorLogin, repository];
        
        if ([self notificationActive:GHForkApplyEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:nil iconName:@"octocat-128"];
        }
         */
        
    } else if ([GistEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *action = [[event valueForKey:@"payload"] valueForKey:@"action"];
        NSNumber *gistId = [[[event valueForKey:@"payload"] valueForKey:@"gist"] valueForKey:@"id"];
        NSString *message = [NSString stringWithFormat:@"%@ %@d gist %@", actorLogin, action, gistId];
        NSString *url = [[[event valueForKey:@"payload"] valueForKey:@"gist"] valueForKey:@"html_url"];
        
        if ([self notificationActive:GHGistEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:url iconName:@"octocat-128"];
        }
        
    } else if ([GollumEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSArray *pages = [[event valueForKey:@"payload"] valueForKey:@"pages"];
        
        if ([pages count] > 1) {
            NSString *message = [NSString stringWithFormat:@"%@ modified %d pages in the %@ wiki", actorLogin, [pages count], repository];
            
            if ([self notificationActive:GHGollumEvent]) {
                [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:nil iconName:@"octocat-128"];
            }

        } else {
            
            for (NSDictionary *page in pages) {
                NSString *pageName = [page valueForKey:@"page_name"];
                NSString *action = [page valueForKey:@"action"];
                NSString *message = [NSString stringWithFormat:@"%@ %@ the %@ wiki page %@", actorLogin, action, repository, pageName];
                
                if ([self notificationActive:GHGollumEvent]) {
                    [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:nil iconName:@"octocat-128"];
                }
            }
        }
        
    } else if ([IssueCommentEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *action = [[event valueForKey:@"payload"] valueForKey:@"action"];
        NSNumber *issueId = [[[event valueForKey:@"payload"] valueForKey:@"issue"] valueForKey:@"number"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSString *message = [NSString stringWithFormat:@"%@ %@ comment on issue %@ on %@", actorLogin, action, issueId, repository];
        NSString *url = [[[event valueForKey:@"payload"] valueForKey:@"issue"] valueForKey:@"html_url"];
        
        if ([self notificationActive:GHIssueCommentEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:url iconName:@"octocat-128"];
        }
        
    } else if ([IssuesEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *action = [[event valueForKey:@"payload"] valueForKey:@"action"];
        NSNumber *issueId = [[[event valueForKey:@"payload"] valueForKey:@"issue"] valueForKey:@"number"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSString *message = [NSString stringWithFormat:@"%@ %@ issue %@ on %@", actorLogin, action, issueId, repository];
        NSString *url = [[[event valueForKey:@"payload"] valueForKey:@"issue"] valueForKey:@"html_url"];
        
        if ([self notificationActive:GHIssuesEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:url iconName:@"octocat-128"];
        }
        
    } else if ([MemberEvent isEqualToString:type]) {

    } else if ([PublicEvent isEqualToString:type]) {
        
    } else if ([PullRequestEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *action = [[event valueForKey:@"payload"] valueForKey:@"action"];
        NSNumber *pullrequestId = [[event valueForKey:@"payload"] valueForKey:@"number"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSString *message = [NSString stringWithFormat:@"%@ %@ on pull request %@ on %@", actorLogin, action, pullrequestId, repository];
        NSString *url = [[[event valueForKey:@"payload"] valueForKey:@"pull_request"] valueForKey:@"html_url"];
        
        if ([self notificationActive:GHPullRequestEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:url iconName:@"octocat-128"];
        }
            
    } else if ([PullRequestReviewCommentEvent isEqualToString:type]) {

    } else if ([PushEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSNumber *branch = [[event valueForKey:@"payload"] valueForKey:@"ref"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSString *message = [NSString stringWithFormat:@"%@ pushed to %@ at %@", actorLogin, branch, repository];
        
        if ([self notificationActive:GHPushEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:nil iconName:@"octocat-128"];
        }
        
    } else if ([TeamAddEvent isEqualToString:type]) {

    } else if ([WatchEvent isEqualToString:type]) {
        
        NSString *actorLogin = [[event valueForKey:@"actor"] valueForKey:@"login"];
        NSString *action = [[event valueForKey:@"payload"] valueForKey:@"action"];
        NSString *repository = [[event valueForKey:@"repo"] valueForKey:@"name"];
        NSString *message = [NSString stringWithFormat:@"%@ %@ watching %@", actorLogin, action, repository];
        
        if ([self notificationActive:GHWatchEvent]) {
            [[GrowlManager get] notifyWithName:@"GitHub" desc:message url:nil iconName:@"octocat-128"];
        }
        
    } else {
        // NOP
    }
}

- (BOOL) notificationActive:(NSString *) eventType {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL result = YES;
    
    if ([defaults valueForKey:eventType]) {
        result = [defaults boolForKey:eventType];
    } else {
        // if not found, let's say that the notification is active...
        result = YES;
    }
    return result;
}

- (BOOL) isNotificationsActive {
    BOOL result = YES;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults valueForKey:GHEventActive]) {
        result = [defaults boolForKey:GHEventActive];
    } else {
        // if not found, let's say that the notification is active...
        result = YES;
    }
    return result;    
}

- (void)dealloc {
    [super dealloc];
}

@end
