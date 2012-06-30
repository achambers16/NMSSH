#import "NMSSHChannelTests.h"
#import "ConfigHelper.h"

#import <NMSSH/NMSSH.h>

@interface NMSSHChannelTests () {
    NSDictionary *settings;
    NSString *localFilePath;

    NMSSHChannel *channel;
    NMSSHSession *session;
}
@end

@implementation NMSSHChannelTests

// -----------------------------------------------------------------------------
// TEST SETUP
// -----------------------------------------------------------------------------

- (void)setUp {
    settings = [ConfigHelper valueForKey:@"valid_password_protected_server"];

    session = [NMSSHSession connectToHost:[settings objectForKey:@"host"]
                             withUsername:[settings objectForKey:@"user"]];
    [session authenticateByPassword:[settings objectForKey:@"password"]];
    assert([session isAuthorized]);

    // Setup test file for SCP
    localFilePath = [@"~/nmssh-test.txt" stringByExpandingTildeInPath];
    NSData *contents = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
    [[NSFileManager defaultManager] createFileAtPath:localFilePath
                                            contents:contents
                                          attributes:nil];
}

- (void)tearDown {
    if (channel) {
        channel = nil;
    }

    if (session) {
        [session disconnect];
        session = nil;
    }

    // Cleanup SCP test files
    [[NSFileManager defaultManager] removeItemAtPath:localFilePath error:nil];
}

// -----------------------------------------------------------------------------
// SHELL EXECUTION TESTS
// -----------------------------------------------------------------------------

- (void)testCreatingChannelWorks {
    STAssertNoThrow(channel = [[NMSSHChannel alloc] initWithSession:session],
                    @"Setting up channel does not throw exception");
}

- (void)testExecutingShellCommand {
    channel = [[NMSSHChannel alloc] initWithSession:session];

    NSError *error = nil;
    STAssertNoThrow([channel execute:[settings objectForKey:@"execute_command"]
                               error:&error],
                    @"Execution should not throw an exception");

    STAssertEqualObjects([channel lastResponse],
                         [settings objectForKey:@"execute_expected_response"],
                         @"Execution returns the expected response");
}

// -----------------------------------------------------------------------------
// SCP FILE TRANSFER TESTS
// -----------------------------------------------------------------------------

- (void)testUploadingFileToWritableDirWorks {
    channel = [[NMSSHChannel alloc] initWithSession:session];
    NSString *dir = [settings objectForKey:@"writable_dir"];

    BOOL result;
    STAssertNoThrow(result = [channel uploadFile:localFilePath to:dir],
                    @"Uploading file to writable dir doesn't throw exception");

    STAssertTrue(result, @"Uploading to writable dir should work.");
}

- (void)testUploadingFileToNonWritableDirFails {
    channel = [[NMSSHChannel alloc] initWithSession:session];
    NSString *dir = [settings objectForKey:@"non_writable_dir"];

    BOOL result;
    STAssertNoThrow(result = [channel uploadFile:localFilePath to:dir],
                    @"Uploading file to non-writable dir doesn't throw"
                    @"exception");

    STAssertFalse(result, @"Uploading to non-writable dir should not work.");
}

@end