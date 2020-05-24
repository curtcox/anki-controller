//
//  StdInReader.m
//  AnkiVehicleController
//
//  Created by Jeff on 4/25/15.
//  Copyright (c) 2015 Jeff. All rights reserved.
//

#import "StdInReader.h"
#import "Vehicle.h"

@implementation StdInReader

-(id) initWithVehicleController:(VehiclesController*)controller {
    self = [super init];
    _controller = controller;
    return self;
}


-(void) begin {
    [NSThread detachNewThreadSelector:@selector(listenForCommands) toTarget:self withObject:nil];
}

-(void) listenForCommands {
    
    /* { command: 'set-speed', carId: 'id', value: 30 }
       
     list-cars, 
     spin carId
     scan
     stop-scan
     
     */
    while (true) {
        char input[256];
        NSError *error = nil;
        fgets(input, 256, stdin);
        NSLog(@"Recieved command: %s\n", input);
        id object = [NSJSONSerialization
                     JSONObjectWithData: [NSData dataWithBytes:input length:strlen(input)]
                     options:0
                     error:&error];
        if (error) {
            [self invalidJson:error];
            continue;
        }
        NSDictionary *dict = object;
        NSString *command = dict[@"command"];
        [self perform:command:dict:error];
    }
}

-(void) perform:(NSString*)command :(NSDictionary*)dict :(NSError*)error {
    if ([command isEqualToString:@"set-speed"])  { [self setSpeed:dict];  }
    else if ([command isEqualToString:@"set-offset"]) { [self setOffset:dict]; }
    else if ([command isEqualToString:@"list-cars"])  { [self listCars:error]; }
    else if ([command isEqualToString:@"spin"])       { [self spin:dict];      }
    else if ([command isEqualToString:@"scan"])       { [self beginScan];      }
    else if ([command isEqualToString:@"stop-scan"])  { [self stopScan];       }
    else {
        [self unrecognized:command];
    }
}

-(void) invalidJson:(NSError*)error {
    NSLog(@"Invalid json: %@", [error localizedDescription]);
}

-(void) setSpeed:(NSDictionary*) dict {
    Vehicle *v = [self getVehicle:dict[@"carId"]];
    int val = (int)[dict[@"value"] integerValue];
    [v setSpeed:val];
}

-(void) setOffset:(NSDictionary*) dict {
    Vehicle *v = [self getVehicle:dict[@"carId"]];
    float val = (int)[dict[@"value"] floatValue];
    NSLog(@"OFFSET: **%f**\n", val);
    [v setLaneOffset:val];
}

-(void) listCars:(NSError*)error {
    NSMutableArray *cars = [NSMutableArray new];
    for (Vehicle *v in _controller.vehicles) {
        NSMutableDictionary *car = [NSMutableDictionary new];
        [car setObject:[NSNumber numberWithUnsignedInt:v.identifier] forKey:@"id"];
        [cars addObject:car];
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:cars options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"**%@**\n", jsonString);
}

-(void) spin:(NSDictionary*) dict {
    Vehicle *v = [self getVehicle:dict[@"carId"]];
    [v spin180];
}

-(void) beginScan {
    [_controller beginScan];
}

-(void) stopScan {
    [_controller stopScan];
}

-(void) unrecognized:(NSString*) command {
    NSLog(@"Unrecognized command %@", command);
}

-(Vehicle*) getVehicle:(NSNumber*) carId {
    uint32_t identifier = (uint32_t)[carId integerValue];
    Vehicle *v = [_controller findVehicleById:identifier];
    if (v == nil) {
        NSLog(@"Failed to find vehicle id=%d", identifier);
    }
    return v;
}

@end
