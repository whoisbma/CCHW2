//
//  MyScene.m
//  SpriteKitPhysicsTest
//
//  Created by Bryan Ma on 3/3/14.
//  Copyright (c) 2014 Bryan Ma. All rights reserved.
//

#import "MyScene.h"
#define ARC4RANDOM_MAX  0x100000000
static inline CGFloat ScalarRandomRange(CGFloat min, CGFloat max)
{
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}

@implementation MyScene
{
    SKSpriteNode *_square;
    SKSpriteNode *_circle;
    SKSpriteNode *_triangle;
    SKSpriteNode *_octagon;
    
    NSTimeInterval _dt;
    NSTimeInterval _lastUpdateTime;
    CGVector _windForce;
    BOOL _blowing;
    int _forceVal;
    NSTimeInterval _timeUntilSwitchWindDirection;
}

-(instancetype)initWithSize:(CGSize)size
{
    _forceVal = 10;
    if(self = [super initWithSize:size])
    {
        _square = [SKSpriteNode spriteNodeWithImageNamed:@"square"];
        _square.position = CGPointMake(self.size.width * 0.25, self.size.height * 0.50);
        [self addChild:_square];
        
        _circle = [SKSpriteNode spriteNodeWithImageNamed:@"circle"];
        _circle.position = CGPointMake(self.size.width * 0.50, self.size.height * 0.50);
        [self addChild:_circle];
        
        _triangle = [SKSpriteNode spriteNodeWithImageNamed:@"triangle"];
        _triangle.position = CGPointMake(self.size.width * 0.75, self.size.height * 0.5);
        [self addChild:_triangle];
        
        _octagon = [SKSpriteNode spriteNodeWithImageNamed:@"octagon"];
        _octagon.position = CGPointMake(self.size.width * 0.50, self.size.height * 0.75);
        [self addChild:_octagon];
        
        _square.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_square.size];
        _circle.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_circle.size.width/2];
        _circle.physicsBody.dynamic = NO;
        
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        
        //TRIANGLE BODY
        //1 create new CGMutablePathRef which will be used to draw the triangle
        CGMutablePathRef trianglePath = CGPathCreateMutable();
        
        //2 moves virtual pen to starting point to draw by using CGPathMoveToPoint() - coordinates are relative to sprite's anchor point (default at center)
        CGPathMoveToPoint(trianglePath, nil, -_triangle.size.width/2, -_triangle.size.height/2);
        
        //3 draw 3 lines to the three corners of the triangle by calling CGPathAddLineToPoint
        CGPathAddLineToPoint(trianglePath, nil, _triangle.size.width/2, -_triangle.size.height/2);
        CGPathAddLineToPoint(trianglePath, nil, 0, _triangle.size.height/2);
        CGPathAddLineToPoint(trianglePath, nil, -_triangle.size.width/2, -_triangle.size.height/2);
        
        //4 create the body by passing the trianglePath to bodyWithPolygonFromPath:
        _triangle.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:trianglePath];
        
        //5 need to call this because CGPathCreateMutable() gave a retained copy of the path through the ARC bridge (????)
        CGPathRelease(trianglePath);
        
        CGMutablePathRef octagonPath = CGPathCreateMutable();
        CGPathMoveToPoint(octagonPath, nil, -_octagon.size.width/4, _octagon.size.height/2);
        CGPathAddLineToPoint(octagonPath, nil, -_octagon.size.width/2, _octagon.size.height/4);
        CGPathAddLineToPoint(octagonPath, nil, -_octagon.size.width/2, -_octagon.size.height/4);
        CGPathAddLineToPoint(octagonPath, nil, -_octagon.size.width/4, -_octagon.size.height/2);
        CGPathAddLineToPoint(octagonPath, nil, _octagon.size.width/4, -_octagon.size.height/2);
        CGPathAddLineToPoint(octagonPath, nil, _octagon.size.width/2, -_octagon.size.height/4);
        CGPathAddLineToPoint(octagonPath, nil, _octagon.size.width/2, _octagon.size.height/4);
        CGPathAddLineToPoint(octagonPath, nil, _octagon.size.width/4, _octagon.size.height/2);
        CGPathAddLineToPoint(octagonPath, nil, -_octagon.size.width/4, _octagon.size.height/2);
        _octagon.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:octagonPath];
        CGPathRelease(octagonPath);
        
        
        [self runAction:
         [SKAction repeatAction:
          [SKAction sequence:
           @[[SKAction performSelector:@selector(spawnSand)onTarget:self],
             [SKAction waitForDuration:0.02]
             ]]
                          count:100]
         ];
    }
    return self;
}

-(void)spawnSand
{
    //create a small ball body
    SKSpriteNode *sand = [SKSpriteNode spriteNodeWithImageNamed:@"sand"];
    sand.position = CGPointMake((float)(arc4random()%(int)self.size.width),self.size.height-sand.size.height);
    sand.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:sand.size.width/2];
    sand.name = @"sand";
    sand.physicsBody.restitution = 0.8;
    sand.physicsBody.density = 5.0;
    [self addChild:sand];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (SKSpriteNode *node in self.children) {
        if ([node.name isEqualToString:@"sand"])
            [node.physicsBody applyImpulse:CGVectorMake(0, arc4random()%20)];
    }
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        [_circle setPosition:location];
    }
    
}

-(void)update:(NSTimeInterval)currentTime
{
    //1 -- determines how much time has elapsed since the last frame
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
    
    //2 -- keeps track of how much time until the wind direction should switch (a random time between 1-5 seconds) then resets the time and sets the wind force
    _timeUntilSwitchWindDirection -= _dt;
    if (_timeUntilSwitchWindDirection <= 0) {
        _timeUntilSwitchWindDirection = ScalarRandomRange(1, 5);
        _windForce = CGVectorMake(_forceVal, 0);
        NSLog(@"Wind force: %0.2f, %0.2f", _windForce.dx, _windForce.dy);
        _forceVal = -_forceVal;
    }
    
    //4 - apply windforce
    for (SKSpriteNode *node in self.children) {
        [node.physicsBody applyForce:_windForce];
    }
}

@end
