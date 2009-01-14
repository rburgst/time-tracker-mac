#import "TDateTransformer.h"

@implementation TDateTransformer

- (id) init  
{
    if (self = [super init]) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        return self;
    }
    return nil;
}

+ (Class)transformedValueClass 
{ 
	return [NSString class]; 
}

+ (BOOL)allowsReverseTransformation 
{ 
	return NO; 
}

- (id)transformedValue:(id)value {
	return [_dateFormatter stringFromDate:value];
    //    return (value == nil) ? nil : NSStringFromClass([value class]);
}

@end


@implementation TTimeTransformer

- (id) init  
{
    if (self = [super init]) {
        _timeFormatter = [[NSDateFormatter alloc] init];
        [_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_timeFormatter setDateStyle:NSDateFormatterNoStyle];
        return self;
    }
    return nil;
}

+ (Class)transformedValueClass 
{ 
	return [NSString class]; 
}

+ (BOOL)allowsReverseTransformation 
{ 
	return NO; 
}

- (id)transformedValue:(id)value {
	return [_timeFormatter stringFromDate:value];
    //    return (value == nil) ? nil : NSStringFromClass([value class]);
}

@end