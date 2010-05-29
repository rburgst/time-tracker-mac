//
//  TTaskNameTransformer.h
//  Time Tracker
//
//  Created by Rainer Burgstaller on 30.05.10.
//  Copyright 2010 N/A. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TTaskNameTransformer : NSValueTransformer {
	BOOL _showProjectName;
}

@property BOOL showProjectName;

@end
