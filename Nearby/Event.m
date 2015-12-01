//
//  User.m
//  Nearby
//
//  Created by Piotr Czubak on 11/24/15.
//  Copyright © 2015 EventAppOrg. All rights reserved.
//

#import "Event.h"
#import "EventUser.h"

@implementation Event

@dynamic eventName;
@dynamic owner;
@dynamic address;
@dynamic eventDate;
@dynamic confirmedCount;
@dynamic distance;
@dynamic category;
@dynamic imageUrl;
@dynamic description;
@dynamic isPrivate;
@dynamic maybeCount;
@dynamic eventUsers;

+ (NSString *)parseClassName {
    return @"Event";
}

+ (void)getEventsForUser:(PFUser *)user completion:(void (^)(NSArray *events, NSError *error))completion {
    // get public events
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isPrivate = nil OR isPrivate = false"];
    PFQuery *query = [Event queryWithPredicate:predicate];
    [query includeKey:@"eventUsers"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Objects %@", objects);
            completion(objects, nil);
        } else {
            NSLog(@"Error: %@", error);
            completion(nil, error);
        }
    }];
    
    // get events where user is owner
    PFQuery *ownerQuery = [Event query];
    [ownerQuery includeKey:@"owner"];
    [ownerQuery includeKey:@"eventUsers"];
    [ownerQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
    [ownerQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Objects %@", objects);
            completion(objects, nil);
        } else {
            NSLog(@"Error: %@", error);
            completion(nil, error);
        }
    }];
    
    // get events where user is invited...
}


+ (void)createEventUser:(PFUser *)user forEvent:(Event *) event withStatus:(NSNumber *) status completion:(void (^)(Event *event, NSError *error))completion {
    EventUser *eventUser = [[EventUser alloc] init];
    eventUser.user = user;
    eventUser.status = status;
    [event addObject:eventUser forKey:@"eventUsers"];
    [event saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(!error) {
            completion(event, nil);
        } else {
            NSLog(@"Error: %@", error);
            completion(nil, error);
        }
    }];
}

@end
