//
//  BugsplatStartupManager.m
//  BugsplatMac
//
//  Created by Geoff Raeder on 2/8/16.
//  Copyright © 2016 Bugsplat. All rights reserved.
//

#import <HockeySDK/HockeySDK.h>
#import "BugsplatStartupManager.h"

NSString *const kHockeyIdentifierPlaceholder = @"b0cf675cb9334a3e96eda0764f95e38e";  // Just to satisfy Hockey since this is required

@interface BugsplatStartupManager () <BITHockeyManagerDelegate>

@end

@implementation BugsplatStartupManager

+ (instancetype)sharedManager
{
    static BugsplatStartupManager *sharedInstance = nil;
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[BugsplatStartupManager alloc] init];
    });
    
    return sharedInstance;
}

- (void)start
{
    NSString *serverURL = [self.hostBundle objectForInfoDictionaryKey:@"BugsplatServerURL"];
    
    NSAssert(serverURL != nil, @"No server url provided.  Please add this key/value to the your bundle's Info.plist");
	
	// JFA: I want reports to be automatically sent without user interaction
	self.autoSubmitCrashReport = YES;
	
	// JFA: Configure Hockey to use this manager class as a delegate so we can provide additional info in crash reports
	[[BITHockeyManager sharedHockeyManager] setDelegate:self];
	
    [[BITHockeyManager sharedHockeyManager] setServerURL:serverURL];
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:kHockeyIdentifierPlaceholder];
    [[BITHockeyManager sharedHockeyManager].crashManager setAutoSubmitCrashReport:self.autoSubmitCrashReport];
    [[BITHockeyManager sharedHockeyManager] startManager];
}

- (NSBundle *)hostBundle
{
    if (!_hostBundle)
    {
        _hostBundle = [NSBundle mainBundle];
    }
    
    return _hostBundle;
}

// JFA: Delegate methods implemented to provide more info for crash reports
#pragma mark - BITHockeyManagerDelegate

/**
 * Generates an XML or GZipped XML report from system profiler
 */
- (NSString *)collectSystemReport:(BOOL)compressed
{
	dispatch_semaphore_t dsema = dispatch_semaphore_create(0);
	
	NSString * systemProfilerDataTypes = @"SPFrameworksDataType SPHardwareDataType";
	
	NSString * filename = compressed ? @"SystemReport.spx.gz" : @"SystemReport.spx";
	NSString * cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
	NSString * systemReportPath = [cachePath stringByAppendingPathComponent:filename];
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		
		NSMutableString * systemReportPathFixed = [systemReportPath mutableCopy];
		
		NSLog(@"Collecting system report for diagnostic purposes... Location: %@, Data types: %@", systemReportPath, systemProfilerDataTypes);
		
		[systemReportPathFixed replaceOccurrencesOfString:@"'" withString:@"'\\''" options:0 range:NSMakeRange(0, systemReportPath.length)];
		
		NSArray * arguments;
		if (compressed) {
			arguments = @[@"-c", [NSString stringWithFormat:@"/usr/sbin/system_profiler -xml %@ | /usr/bin/gzip > '%@'", systemProfilerDataTypes, systemReportPath]];
		}
		else {
			arguments = @[@"-c", [NSString stringWithFormat:@"/usr/sbin/system_profiler -xml %@ > '%@'", systemProfilerDataTypes, systemReportPath]];
		}
		
		NSTask * task = [[NSTask alloc] init];
		task.launchPath = @"/bin/bash";
		task.arguments = arguments;
		task.terminationHandler = ^(NSTask * task){
			dispatch_semaphore_signal(dsema);
		};
		[task launch];
	});
	
	dispatch_semaphore_signal(dsema);
	
	return systemReportPath;
}

- (NSString *)userIDForHockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITHockeyBaseManager *)componentManager
{
	(void)hockeyManager;
	(void)componentManager;
	NSLog(@"%s", __FUNCTION__);
	return @"UserID_Value";
}

- (NSString *)userNameForHockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITHockeyBaseManager *)componentManager
{
	(void)hockeyManager;
	(void)componentManager;
	NSLog(@"%s", __FUNCTION__);
	return @"User Name";
}

- (NSString *)userEmailForHockeyManager:(BITHockeyManager *)hockeyManager componentManager:(BITHockeyBaseManager *)componentManager
{
	(void)hockeyManager;
	(void)componentManager;
	NSLog(@"%s", __FUNCTION__);
	return @"user@example.com";
}

- (NSString *)applicationLogForCrashManager:(BITCrashManager *)crashManager
{
	(void)crashManager;
	NSLog(@"%s", __FUNCTION__);
	return @"Application log text";
}

- (BITHockeyAttachment *)attachmentForCrashManager:(BITCrashManager *)crashManager
{
	(void)crashManager;
	NSLog(@"%s", __FUNCTION__);
	NSString * filePath = [self collectSystemReport:NO];
	NSData * fileData = [NSData dataWithContentsOfFile:filePath];
	BITHockeyAttachment * attachment = [[BITHockeyAttachment alloc] initWithFilename:filePath hockeyAttachmentData:fileData contentType:@"text/xml"];
	return attachment;
}

- (void)crashManagerWillSendCrashReport:(BITCrashManager *)crashManager
{
	(void)crashManager;
	NSLog(@"%s", __FUNCTION__);
}

- (void)crashManager:(BITCrashManager *)crashManager didFailWithError:(NSError *)error
{
	(void)crashManager;
	NSLog(@"%s: %@", __FUNCTION__, error);
}

- (void)crashManagerDidFinishSendingCrashReport:(BITCrashManager *)crashManager
{
	(void)crashManager;
	NSLog(@"%s", __FUNCTION__);
}

- (void)crashManagerWillCancelSendingCrashReport:(BITCrashManager *)crashManager
{
	(void)crashManager;
	NSLog(@"%s", __FUNCTION__);
}

- (void)crashManagerWillShowSubmitCrashReportAlert:(BITCrashManager *)crashManager
{
	(void)crashManager;
	NSLog(@"%s", __FUNCTION__);
}

@end
