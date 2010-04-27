//
//  RootViewController.m
//  RushHourNTU
//
//  Created by Jeremy Foo on 4/25/10.
//  Copyright ORNYX 2010. All rights reserved.
//

#import "RootViewController.h"
#import "JONTUBusEngine.h"
#import "BusStopViewController.h"
#import "NSString+htmlentitiesaddition.h"
#import "JONTUBusStop+location.h"
#import "LocationManager.h"
#import "CacheOperation.h"
#import "RegexKitLite.h"

@implementation RootViewController

@synthesize currentLocation, refreshCache, savedSearchTerm, filteredContent, searchWasActive, activity, actualContent, workQueue;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.title = @"Rush Hour NTU";
	lastUpdate = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
	lastUpdate.backgroundColor = [UIColor clearColor];
	lastUpdate.textColor = [UIColor whiteColor];
	lastUpdate.font = [UIFont fontWithName:@"Helvetica" size:13.0];
	lastUpdate.text = @"";
	self.toolbarItems = [NSArray arrayWithObjects:currentLocation,
						 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
						 [[[UIBarButtonItem alloc] initWithCustomView:lastUpdate] autorelease],
						 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
						 nil];
	
	self.navigationItem.rightBarButtonItem = refreshCache;
	
	if (self.savedSearchTerm) {
		[self.searchDisplayController setActive:self.searchWasActive];
		[self.searchDisplayController.searchBar setText:savedSearchTerm];
		
		self.savedSearchTerm = nil;
	}
	self.tableView.scrollEnabled = YES;
	
	LocationManager *manager = [LocationManager sharedLocationManager];
	
	[manager.manager dismissHeadingCalibrationDisplay];
	[manager.manager setDelegate:self];
	[manager.manager setDesiredAccuracy:kCLLocationAccuracyBest];
	
	proximitySort = NO;
	
	workQueue = [[NSOperationQueue alloc] init];
	
	if ([JONTUBusEngine sharedJONTUBusEngine].brandNew) {
		CacheOperation *fillCache = [[CacheOperation alloc] initWithDelegate:self];
		[self.workQueue addOperation:fillCache];
		[fillCache release];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
	} else {
		[self freshen];		
	}
}


-(IBAction)useLocation {
	[currentLocation setStyle:UIBarButtonItemStyleDone];
	[currentLocation setAction:@selector(stopLocation)];
	
	LocationManager *manager = [LocationManager sharedLocationManager];	
	[manager.manager startUpdatingLocation];
	proximitySort = YES;
}

-(IBAction)refreshTheCache {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Refresh Cache" 
													message:@"Are you sure you want to refresh the cache?" 
												   delegate:self 
										  cancelButtonTitle:@"No"
										  otherButtonTitles:@"Yes",nil];
	[alert setDelegate:self];
	[alert show];
	[alert release];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if ((alertView.title = @"Refresh Cache") && ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"])) {
		NSLog(@"Refreshing Cache");
		[[JONTUBusEngine sharedJONTUBusEngine] setHoldCache:20];
		CacheOperation *fillCache = [[CacheOperation alloc] initWithDelegate:self];
		[self.workQueue addOperation:fillCache];
		[fillCache release];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
	}
}

-(void)engineStarted {
	NSLog(@"Fill Cache complete");
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[[JONTUBusEngine sharedJONTUBusEngine] setHoldCache:-1];	
	[self freshen];
}

-(void)freshen {
	JONTUBusEngine *engine = [JONTUBusEngine sharedJONTUBusEngine];	
	self.filteredContent = [NSMutableArray arrayWithCapacity:[[engine stops] count]];	
	self.actualContent = [[engine stops] mutableCopy];
	
	NSDateFormatter *f = [[NSDateFormatter alloc] init];
	[f setDateStyle:NSDateFormatterShortStyle];
	[f setTimeStyle:NSDateFormatterShortStyle];
	
	lastUpdate.text = [NSString stringWithFormat:@"Last updated: %@", [f stringFromDate:engine.lastGetIndexPage]];
	[f release];
	
	[self.tableView reloadData];
}

-(void)stopLocation {
	[currentLocation setStyle:UIBarButtonItemStyleBordered];
	[currentLocation setAction:@selector(useLocation)];
	
	LocationManager *manager = [LocationManager sharedLocationManager];	
	[manager.manager stopUpdatingLocation];
	proximitySort = NO;
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 5.0)
    {
        printf("latitude %+.6f, longitude %+.6f\n",
			   newLocation.coordinate.latitude,
			   newLocation.coordinate.longitude);
		self.actualContent = [[actualContent sortedArrayUsingSelector:@selector(compareLocation:)] mutableCopy];
		[self.tableView reloadData];

    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.toolbarHidden = NO;

}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	self.searchWasActive = [self.searchDisplayController isActive];
	self.savedSearchTerm = [self.searchDisplayController.searchBar text];
	
}


/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		return [self.filteredContent count];
	} else {		
		return [actualContent count];
		
	}
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 55;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.imageView.image = [UIImage imageNamed:@"map-marker.png"];
		//		cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"stop-bg.png"]] autorelease];
		cell.backgroundView.opaque = NO;
		cell.contentView.opaque = NO;
		cell.detailTextLabel.opaque = YES;
		cell.textLabel.opaque = YES;
		cell.contentView.backgroundColor = [UIColor clearColor];
		cell.detailTextLabel.backgroundColor = [UIColor clearColor];
		cell.textLabel.backgroundColor = [UIColor clearColor];
		
    }
	
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		cell.textLabel.text = [[[self.filteredContent objectAtIndex:indexPath.row] desc] removeHTMLEntities];
		cell.detailTextLabel.text = [[self.filteredContent objectAtIndex:indexPath.row] roadName];
		cell.tag = [[self.filteredContent objectAtIndex:indexPath.row] busstopid];
		
	} else {
		cell.textLabel.text = [[[actualContent objectAtIndex:indexPath.row] desc] removeHTMLEntities];
		
		if (proximitySort) {
			CLLocation *stopLocation = [[CLLocation alloc] initWithLatitude:[[[actualContent objectAtIndex:indexPath.row] lat] doubleValue] longitude:[[[actualContent objectAtIndex:indexPath.row] lon] doubleValue]];
			CLLocationDegrees dist = [[[[LocationManager sharedLocationManager] manager] location] getDistanceFrom:stopLocation];
			
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%.fm away", dist];
			[stopLocation release];
			
		} else {
			cell.detailTextLabel.text = [[actualContent objectAtIndex:indexPath.row] roadName];
			
		}
				
		cell.tag = [[actualContent objectAtIndex:indexPath.row] busstopid];
		
	}
    
	// Configure the cell.	
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	BusStopViewController *detailViewController = [[BusStopViewController alloc] initWithNibName:@"BusStopViewController" bundle:nil];
	// ...
	// Pass the selected object to the new view controller.
	detailViewController.busstopid = [[tableView cellForRowAtIndexPath:indexPath] tag];
	
	
	[self.navigationController pushViewController:detailViewController animated:YES];
	[detailViewController release];
}

#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
	[self.filteredContent removeAllObjects];
	
	for (JONTUBusStop *stop in actualContent) {
		
		NSRange descresult = [stop.desc rangeOfString:searchText options:NSCaseInsensitiveSearch];
		NSRange coderesult = [stop.code rangeOfString:searchText options:NSCaseInsensitiveSearch];
		NSRange roadnameresult = [stop.roadName rangeOfString:searchText options:NSCaseInsensitiveSearch];
		if ((coderesult.location != NSNotFound) || (descresult.location != NSNotFound) || (roadnameresult.location != NSNotFound)) {
			[self.filteredContent addObject:stop];
		}
		
	}
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
	 [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
	 [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}



#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	self.filteredContent = nil;
	
}


- (void)dealloc {
	[workQueue release];
	[lastUpdate release];
	[refreshCache release];
	[actualContent release];
	[activity release];
	[savedSearchTerm release];
	[filteredContent release];
	[currentLocation release];
    [super dealloc];
}


@end

