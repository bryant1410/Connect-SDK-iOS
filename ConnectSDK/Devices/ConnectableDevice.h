//
//  ConnectableDevice.h
//  Connect SDK
//
//  Created by Jeremy White on 12/9/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceDescription.h"
#import "DeviceService.h"
#import "ConnectableDeviceDelegate.h"
#import "DeviceServiceDelegate.h"

#import "Launcher.h"
#import "VolumeControl.h"
#import "TVControl.h"
#import "MediaControl.h"
#import "ExternalInputControl.h"
#import "ToastControl.h"
#import "TextInputControl.h"
#import "MediaPlayer.h"
#import "WebAppLauncher.h"
#import "KeyControl.h"
#import "MouseControl.h"
#import "PowerControl.h"

/*!
 * Enumerated value for determining how a DeviceService should handle pairing when attempting to connect.
 */
typedef enum {
    /*! DeviceServices will never try to pair with a device */
    ConnectableDevicePairingLevelOff = 0,

    /*! DeviceServices will try to pair with a device, if needed */
    ConnectableDevicePairingLevelOn
} ConnectableDevicePairingLevel;

/*!
 * ###Overview
 * ConnectableDevice serves as a normalization layer between your app and each of the device's services. It consolidates a lot of key data about the physical device and provides access to underlying functionality.
 *
 * ###In Depth
 * ConnectableDevice consolidates some key information about the physical device, including model name, friendly name, ip address, connected DeviceService names, etc. In some cases, it is not possible to accurately select which DeviceService has the best friendly name, model name, etc. In these cases, the values of these properties are dependent upon the order of DeviceService discovery.
 *
 * To be informed of any ready/pairing/disconnect messages from each of the DeviceService, you must set a delegate.
 *
 * ConnectableDevice exposes capabilities that exist in the underlying DeviceServices such as TV Control, Media Player, Media Control, Volume Control, etc. These capabilities, when accessed through the ConnectableDevice, will be automatically chosen from the most suitable DeviceService by using that DeviceService's CapabilityPriorityLevel.
 */
@interface ConnectableDevice : NSObject <DeviceServiceDelegate>

// @cond INTERNAL
+ (instancetype) connectableDeviceWithDescription:(ServiceDescription *)description;
@property (nonatomic, strong, readonly) ServiceDescription *serviceDescription;
// @endcond

/*!
 * Delegate which should receive messages on certain events.
 */
@property (nonatomic, weak) id<ConnectableDeviceDelegate> delegate;

#pragma mark - General info

/*! Current IP address of the ConnectableDevice. */
@property (nonatomic, readonly) NSString *address;

/*! An estimate of the ConnectableDevice's current friendly name. */
@property (nonatomic, readonly) NSString *friendlyName;

/*! An estimate of the ConnectableDevice's current model name. */
@property (nonatomic, readonly) NSString *modelName;

/*! An estimate of the ConnectableDevice's current model number. */
@property (nonatomic, readonly) NSString *modelNumber;

/*! Last IP address this ConnectableDevice was discovered at. */
@property (nonatomic) NSString *lastKnownIPAddress;

/*! Name of the last wireless network this ConnectableDevice was discovered on. */
@property (nonatomic) NSString *lastSeenOnWifi;

/*! Last time (in seconds from 1970) that this ConnectableDevice was connected to. */
@property (nonatomic) double lastConnected;

/*! Last time (in seconds from 1970) that this ConnectableDevice was detected. */
@property (nonatomic) double lastDetection;

// @cond INTERNAL
- (NSString *) connectedServiceNames;
// @endcond

#pragma mark - Connection

/*!
 * Enumerates through all DeviceServices and attempts to connect to each of them. When all of a ConnectableDevice's DeviceServices are ready to receive commands, the ConnectableDevice will send a connectableDeviceReady: message to its delegate.
 *
 * It is always necessary to call connect on a ConnectableDevice, even if it contains no connectable DeviceServices.
 */
- (void) connect;

/*! Enumerates through all DeviceServices and attempts to disconnect from each of them. */
- (void) disconnect;

/*! Whether the device has any DeviceServices that require an active connection (websocket, HTTP registration, etc) */
@property (nonatomic, readonly) BOOL isConnectable;

/*! Whether all the DeviceServices are connected. */
@property (nonatomic, readonly) BOOL connected;

#pragma mark - Service management

/*! Array of all currently discovered DeviceServices this ConnectableDevice has associated with it. */
@property (nonatomic, readonly) NSArray *services;

/*! Whether the ConnectableDevice has any running DeviceServices associated with it. */
@property (nonatomic, readonly) BOOL hasServices;

/*!
 * Adds a DeviceService to the ConnectableDevice instance. Only one instance of each DeviceService type (webOS, Netcast, etc) may be attached to a single ConnectableDevice instance. If a device contains your service type already, your service will not be added.
 *
 * @param service DeviceService to be added to the ConnectableDevice
 */
- (void) addService:(DeviceService *)service;

/*!
 * Removes a DeviceService from the ConnectableDevice instance. serviceId is used as the identifier because only one instance of each DeviceService type may be attached to a single ConnectableDevice instance.
 *
 * @param serviceId Id of the DeviceService to be removed from the ConnectableDevice
 */
- (void) removeServiceWithId:(NSString *)serviceId;

/*!
 * Obtains a service from the device with the provided serviceId
 *
 * @param serviceId Service ID of the targeted DeviceService (webOS, Netcast, DLNA, etc)
 * @return DeviceService with the specified serviceId or nil, if none exists
 */
- (DeviceService *)serviceWithName:(NSString *)serviceId;

#pragma mark - Capabilities

#pragma mark Info

/*! A combined list of all capabilities that are supported among the detected DeviceServices. */
@property (nonatomic, readonly) NSArray *capabilities;

/*!
 * Test to see if the capabilities array contains a given capability. See the individual Capability classes for acceptable capability values.
 *
 * It is possible to append a wildcard search term `.Any` to the end of the search term. This method will return true for capabilities that match the term up to the wildcard.
 *
 * Example: `Launcher.App.Any`
 *
 * @property capability Capability to test against
 */
- (BOOL) hasCapability:(NSString *)capability;

/*!
 * Test to see if the capabilities array contains a given set of capabilities. See the individual Capability classes for acceptable capability values.
 *
 * See hasCapability: for a description of the wildcard feature provided by this method.
 *
 * @property capabilities Array of capabilities to test against
 */
- (BOOL) hasCapabilities:(NSArray *)capabilities;

/*!
 * Test to see if the capabilities array contains at least one capability in a given set of capabilities. See the individual Capability classes for acceptable capability values.
 *
 * See hasCapability: for a description of the wildcard feature provided by this method.
 *
 * @property capabilities Array of capabilities to test against
 */
- (BOOL) hasAnyCapability:(NSArray *)capabilities;

#pragma mark Accessors

- (id<Launcher>) launcher; /*! Accessor for highest priority Launcher object */
- (id<ExternalInputControl>) externalInputControl; /*! Accessor for highest priority ExternalInputControl object */
- (id<MediaPlayer>) mediaPlayer; /*! Accessor for highest priority MediaPlayer object */
- (id<MediaControl>) mediaControl; /*! Accessor for highest priority MediaControl object */
- (id<VolumeControl>)volumeControl; /*! Accessor for highest priority VolumeControl object */
- (id<TVControl>)tvControl; /*! Accessor for highest priority TVControl object */
- (id<KeyControl>) keyControl; /*! Accessor for highest priority KeyControl object */
- (id<TextInputControl>) textInputControl; /*! Accessor for highest priority TextInputControl object */
- (id<MouseControl>)mouseControl; /*! Accessor for highest priority MouseControl object */
- (id<PowerControl>)powerControl; /*! Accessor for highest priority PowerControl object */
- (id<ToastControl>) toastControl; /*! Accessor for highest priority ToastControl object */
- (id<WebAppLauncher>) webAppLauncher; /*! Accessor for highest priority WebAppLauncher object */

@end
