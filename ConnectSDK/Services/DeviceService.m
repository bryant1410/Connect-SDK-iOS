//
//  DeviceService.m
//  Connect SDK
//
//  Created by Jeremy White on 12/5/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "DeviceService.h"
#import "Launcher.h"
#import "MediaPlayer.h"
#import "ExternalInputControl.h"
#import "WebAppLauncher.h"
#import "ConnectError.h"

@implementation DeviceService
{
    NSMutableArray *_capabilities;
}

- (NSString *)serviceName
{
    return self.serviceDescription.serviceId;
}

+ (NSDictionary *) discoveryParameters { return nil; }

+ (instancetype) deviceServiceWithClass:(Class)class serviceConfig:(ServiceConfig *)serviceConfig
{
    return [[class alloc] initWithServiceConfig:serviceConfig];
}

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        _connected = NO;
        _capabilities = [NSMutableArray new];
    }

    return self;
}

- (instancetype) initWithServiceConfig:(ServiceConfig *)serviceConfig
{
    self = [self init];

    if (self)
    {
        _serviceConfig = serviceConfig;
    }

    return self;
}

#pragma mark - Capabilities

- (NSArray *) capabilities { return [NSArray arrayWithArray:_capabilities]; }

- (BOOL) hasCapability:(NSString *)capability
{
    NSRange anyRange = [capability rangeOfString:@".Any"];
    
    if (anyRange.location != NSNotFound)
    {
        NSString *matchedCapability = [capability substringToIndex:anyRange.location];

        __block BOOL hasCap = NO;

        [self.capabilities enumerateObjectsUsingBlock:^(NSString *item, NSUInteger idx, BOOL *stop)
        {
            if ([item rangeOfString:matchedCapability].location != NSNotFound)
            {
                hasCap = YES;
                *stop = YES;
            }
        }];

        return hasCap;
    }

    return [self.capabilities containsObject:capability];
}

- (BOOL) hasCapabilities:(NSArray *)capabilities
{
    __block BOOL hasCaps = YES;

    [capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if (![self hasCapability:capability])
        {
            hasCaps = NO;
            *stop = YES;
        }
    }];

    return hasCaps;
}

- (BOOL) hasAnyCapability:(NSArray *)capabilities
{
    __block BOOL hasAnyCap = NO;

    [capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if ([self hasCapability:capability])
        {
            hasAnyCap = YES;
            *stop = YES;
        }
    }];

    return hasAnyCap;
}

- (void) addCapability:(NSString *)capability
{
    if (!capability || capability.length == 0)
        return;

    if ([self hasCapability:capability])
        return;

    [_capabilities addObject:capability];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:capabilitiesAdded:removed:)])
        [self.delegate deviceService:self capabilitiesAdded:@[capability] removed:[NSArray array]];
}

- (void) addCapabilities:(NSArray *)capabilities
{
    [capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if (!capability || capability.length == 0)
            return;

        if ([self hasCapability:capability])
            return;

        [_capabilities addObject:capability];
    }];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:capabilitiesAdded:removed:)])
        [self.delegate deviceService:self capabilitiesAdded:capabilities removed:[NSArray array]];
}

- (void) removeCapability:(NSString *)capability
{
    if (!capability || capability.length == 0)
        return;

    if (![self hasCapability:capability])
        return;

    do
    {
        [_capabilities removeObject:capability];
    } while ([_capabilities containsObject:capability]);

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:capabilitiesAdded:removed:)])
        [self.delegate deviceService:self capabilitiesAdded:[NSArray array] removed:@[capability]];
}

- (void) removeCapabilities:(NSArray *)capabilities
{
    [capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if (!capability || capability.length == 0)
            return;

        if (![self hasCapability:capability])
            return;

        do
        {
            [_capabilities removeObject:capability];
        } while ([_capabilities containsObject:capability]);
    }];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:capabilitiesAdded:removed:)])
        [self.delegate deviceService:self capabilitiesAdded:[NSArray array] removed:capabilities];
}

#pragma mark - Connection

- (BOOL) isConnectable
{
    return NO;
}

- (void) connect { }
- (void) disconnect { }

# pragma mark - Pairing

- (BOOL) requiresPairing
{
    return self.pairingType != DeviceServicePairingTypeNone;
}

- (DeviceServicePairingType) pairingType
{
    return DeviceServicePairingTypeNone;
}

- (id) pairingData
{
    return nil;
}

- (void)pairWithData:(id)pairingData { }

#pragma mark - Utility

void dispatch_on_main(dispatch_block_t block) {
    if (block)
        dispatch_async(dispatch_get_main_queue(), block);
}

id ensureString(id value)
{
    return value != nil ? value : @"";
}

- (void) closeLaunchSession:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!launchSession)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provice a valid LaunchSession object"]);

        return;
    }

    if (!launchSession.service)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"This LaunchSession does not have an associated DeviceService"]);

        return;
    }

    switch (launchSession.sessionType)
    {
        case LaunchSessionTypeApp:
            if ([launchSession.service conformsToProtocol:@protocol(Launcher)])
                [((id <Launcher>) launchSession.service) closeApp:launchSession success:success failure:failure];
            break;

        case LaunchSessionTypeMedia:
            if ([launchSession.service conformsToProtocol:@protocol(MediaPlayer)])
                [((id <MediaPlayer>) launchSession.service) closeMedia:launchSession success:success failure:failure];
            break;

        case LaunchSessionTypeExternalInputPicker:
            if ([launchSession.service conformsToProtocol:@protocol(ExternalInputControl)])
                [((id <ExternalInputControl>) launchSession.service) closeInputPicker:launchSession success:success failure:failure];
            break;

        case LaunchSessionTypeWebApp:
            if ([launchSession.service conformsToProtocol:@protocol(WebAppLauncher)])
                [((id <WebAppLauncher>) launchSession.service) closeWebApp:launchSession success:success failure:failure];
            break;

        case LaunchSessionTypeUnknown:
        default:
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"This DeviceService does not know how to close this LaunchSession"]);
    }
}

#pragma mark - JSONObjectCoding methods

- (instancetype) initWithJSONObject:(NSDictionary *)dict
{
    self = [self init];

    if (self)
    {
        NSDictionary *configDictionary = dict[@"config"];

        if (configDictionary)
            self.serviceConfig = [ServiceConfig serviceConfigWithJSONObject:configDictionary];

        NSDictionary *descriptionDictionary = dict[@"description"];

        if (descriptionDictionary)
            self.serviceDescription = [[ServiceDescription alloc] initWithJSONObject:descriptionDictionary];
    }

    return self;
}

- (NSDictionary *) toJSONObject
{
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    dictionary[@"class"] = NSStringFromClass([self class]);

    if (self.serviceConfig)
        dictionary[@"config"] = [self.serviceConfig toJSONObject];

    if (self.serviceDescription)
        dictionary[@"description"] = [self.serviceDescription toJSONObject];

    return dictionary;
}

@end
