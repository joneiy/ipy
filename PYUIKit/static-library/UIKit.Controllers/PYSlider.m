//
//  PYSlider.m
//  PYUIKit
//
//  Created by Push Chen on 7/30/13.
//  Copyright (c) 2013 Push Lab. All rights reserved.
//

/*
 LISENCE FOR IPY
 COPYRIGHT (c) 2013, Push Chen.
 ALL RIGHTS RESERVED.
 
 REDISTRIBUTION AND USE IN SOURCE AND BINARY
 FORMS, WITH OR WITHOUT MODIFICATION, ARE
 PERMITTED PROVIDED THAT THE FOLLOWING CONDITIONS
 ARE MET:
 
 YOU USE IT, AND YOU JUST USE IT!.
 WHY NOT USE THIS LIBRARY IN YOUR CODE TO MAKE
 THE DEVELOPMENT HAPPIER!
 ENJOY YOUR LIFE AND BE FAR AWAY FROM BUGS.
 */

#import "PYSlider.h"
#import "PYScrollView+SideAnimation.h"

@implementation PYSlider

- (void)viewJustBeenCreated
{
    [super viewJustBeenCreated];
    [self setLoopEnabled:YES];
    [self setPagable:YES];
    [self setScrollSide:PYScrollVerticalis];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setPageSize:frame.size];
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab
