//
//  BusStopViewController.h
//  RushHourNTU
//
//  Created by Jeremy Foo on 4/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JONTUBusEngine.h"
#import "JONTUBus.h"
#import "BusETACell.h"
#import <CoreLocation/CoreLocation.h>

@interface BusStopViewController : UITableViewController {
	NSUInteger busstopid;
	JONTUBusStop *stop;
	NSArray *arrivals;
	CLLocation *stopLocation;
	
	IBOutlet UIBarButtonItem *refreshETA;
	
	BusETACell *etaCell;
}

@property (nonatomic, assign) IBOutlet BusETACell *etaCell;
@property (readonly) CLLocation *stopLocation;
@property (readwrite) NSUInteger busstopid;
-(IBAction)refreshETA;
@end
