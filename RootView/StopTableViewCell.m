//
//  StopTableViewCell.m
//  RushHourNTU
//
//  Created by Jeremy Foo on 4/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "StopTableViewCell.h"

const NSInteger SIDE_PADDING = 5;

@implementation StopTableViewCell

@synthesize fav, swipe;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		fav = [[UIImageView alloc] initWithFrame:CGRectZero];
		fav.contentMode = UIViewContentModeCenter;
		swipe = NO;
		[self.contentView addSubview:fav];
	}
	return self;
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[self layoutSubviews];
	if (editing) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;		
	} else {
		self.selectionStyle = UITableViewCellSelectionStyleBlue;
		self.swipe = NO;
	}
	[super setEditing:editing animated:animated];
}

-(void)setEditing:(BOOL)editing {
	[self layoutSubviews];
	if (editing) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;		
	} else {
		self.selectionStyle = UITableViewCellSelectionStyleBlue;		
		self.swipe = NO;
	}
	[super setEditing:editing];
}
//
// layoutSubviews
//
// When editing, displace everything rightwards to allow space for the
// selection indicator.
//
- (void)layoutSubviews
{	
		
	[super layoutSubviews];
	
	if (!swipe) {
		fav.frame = CGRectMake(-(fav.image.size.width + SIDE_PADDING), (self.frame.size.height - fav.image.size.height)/2, (SIDE_PADDING + fav.image.size.width + SIDE_PADDING), fav.image.size.height);
		
		if (((UITableView *)self.superview).isEditing)
		{
			CGRect contentFrame = self.contentView.frame;
			contentFrame.origin.x = (SIDE_PADDING + fav.image.size.width + SIDE_PADDING);
			self.contentView.frame = contentFrame;
		}
		else
		{
			CGRect contentFrame = self.contentView.frame;
			contentFrame.origin.x = 0;
			self.contentView.frame = contentFrame;
		}
	}
	
}

-(void)dealloc {
	[fav release];
	[super dealloc];
}

@end
