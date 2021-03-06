//
//  QBlueVoLEAppDelegate.m
//  iPhoneStreamingPlayer
//
//  Created by Matt Gallagher on 28/10/08.
//  Copyright Matt Gallagher 2008. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import "QBlueVoLEAppDelegate.h"
#import "HomeViewController.h"

// #import "AudioPlayerView.h"

@implementation QBlueVoLEAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    // Override point for customization after app launch    
        
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
        
    [self.window makeKeyAndVisible];
    
    HomeViewController *hvc = [[HomeViewController alloc]initWithNibName:@"HomeViewController" bundle:[NSBundle mainBundle]];
    UINavigationController *nvc = [[UINavigationController alloc]initWithRootViewController:hvc];
    self.window.rootViewController = nvc;
    
    
    /*
    Homev *vc = [[QBlueVoLEViewController alloc]initWithNibName:@"QBlueVoLEViewController" bundle:[NSBundle mainBundle]];
    UINavigationController *nc = [[UINavigationController alloc]initWithRootViewController:vc];
    self.window.rootViewController = nc; */
}


- (void)dealloc {
  //  [viewController release];
  //  [window release];
  //  [super dealloc];
}


@end
