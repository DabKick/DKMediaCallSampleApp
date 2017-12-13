//
//  EditorViewController.m
//  CameraApp
//
//  Created by Mladjan Antic on 5/16/13.
//  Copyright (c) 2013 Imperio. All rights reserved.
//

#import "EditorViewController.h"
#import "UIImage+Resize.h"
#import <QuartzCore/QuartzCore.h>
#import <DabKickLiveSessionSdk/DabKickLiveSessionSdk.h>

@interface EditorViewController () <DabKickLiveSessionSdkDelegate>

@property (strong, nonatomic) UIImage *cropedImage;

@end

@implementation EditorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.capturedImageView setImage:self.capturedImage];

    DabKickWatchTogetherButton *dabKickWatchTogetherButton = [[DabKickLiveSessionSdk defaultInstance] getWatchTogetherButton];
    [dabKickWatchTogetherButton sizeToFit];
    [self.view addSubview:dabKickWatchTogetherButton];
    dabKickWatchTogetherButton.center = self.view.center;
    
    [DabKickLiveSessionSdk defaultInstance].delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [self setCapturedImageView:nil];
    [self setUniversalBtn:nil];
    [self setAssetImageView1:nil];
    [self setAssetImageView2:nil];
    [self setAssetImageView3:nil];
    [self setAssetImageView4:nil];
    [self setAssetImageView5:nil];
    [super viewDidUnload];
}

- (IBAction)backBtnTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)universalBtnTapped:(id)sender {
    
    [self.universalBtn setEnabled:NO];
    
    // Take a screenshot
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    CGRect rect = [keyWindow bounds];
    UIGraphicsBeginImageContextWithOptions(rect.size,YES,0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [keyWindow.layer renderInContext:context];
    UIImage *capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Crop it
    CGRect frameForCrop = CGRectMake(30, 70, 580, 664);
    self.cropedImage = [capturedScreen croppedImage:frameForCrop];
    
    // Save it to camera roll
    UIImageWriteToSavedPhotosAlbum(self.cropedImage, nil, nil, nil);

    [self.universalBtn setTitle:@"Share" forState:UIControlStateNormal];
    [self.universalBtn setEnabled:YES];
    
    
    // Share it
    NSString* someText = @"My new look! CameraApp - makes you smile.";
    NSArray* dataToShare = @[someText, self.cropedImage];
    UIActivityViewController* activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:dataToShare
                                      applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:^{}];

}


#pragma mark - Handling gestures

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
        CGFloat slideMult = magnitude / 200;
        
        float slideFactor = 0.1 * slideMult;
        CGPoint finalPoint = CGPointMake(recognizer.view.center.x + (velocity.x * slideFactor),
                                         recognizer.view.center.y + (velocity.y * slideFactor));
        finalPoint.x = MIN(MAX(finalPoint.x, 0), self.view.bounds.size.width);
        finalPoint.y = MIN(MAX(finalPoint.y, 0), self.view.bounds.size.height);
        
        [UIView animateWithDuration:slideFactor*2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            recognizer.view.center = finalPoint;
        } completion:nil];
        
    }
    
}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    
    recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    recognizer.scale = 1;
    
}

- (IBAction)handleRotate:(UIRotationGestureRecognizer *)recognizer {
    
    recognizer.view.transform = CGAffineTransformRotate(recognizer.view.transform, recognizer.rotation);
    recognizer.rotation = 0;
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

// DKLIVESESSIONSDK
/**
 * Return images to start a live session with
 */
- (NSArray<id<DabKickContent>> *)startDabKickLiveSessionWithContent:(DabKickLiveSessionSdk *)liveSessionInstance {
    NSArray <UIImage *> *imagesToStart = @[
                                           /**
                                            * Replace images with images you would like to show when the live session starts
                                            */
                                           [UIImage imageNamed:@"closeBtn"],
                                           [UIImage imageNamed:@"albumBtn"],
                                           [UIImage imageNamed:@"captureBtn"]
                                           ];
    
    NSMutableArray<id <DabKickContent> > *contentArray = [[NSMutableArray alloc] initWithCapacity:imagesToStart.count];
    
    /*
     [self.imagesToStage enumerateObjectsUsingBlock:^(ALAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
     ALAssetRepresentation *defaultRep = [asset defaultRepresentation];
     UIImage *image = [UIImage imageWithCGImage:[defaultRep fullScreenImage] scale:[defaultRep scale] orientation:0];
     
     DabKickImageContent *imageContent = [[DabKickImageContent alloc] init];
     imageContent.image = image;
     
     [contentArray addObject:imageContent];
     }];
     */
    
    return contentArray;
}

/**
 * Get category names for images
 */
-(void)categoryNamesForDabKickLiveSession:(DabKickLiveSessionSdk *)liveSessionInstance offset:(NSUInteger)offset contentType:(DabKickContentType)contentType loader:(id<DabKickStringLoading>)loader {
    static NSArray *categories;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        categories = @[
                       @"Ahjumawi Lava Springs State Park",
                       @"Andrew Molera State Park",
                       @"Angel Island State Park",
                       @"Annadel State Park",
                       @"Ano Nuevo Island State Park",
                       @"Anza-Borrego Desert State Park",
                       @"Arthur B. Ripley Desert Woodland State Park",
                       @"Baker Beach State Park",
                       @"Beach State Park",
                       @"Bidwell-Sacramento River State Park",
                       @"Big Basin Redwoods State Park",
                       @"Bolsa Chica Beach State Park",
                       @"Border Field State Park"
                       ];
    });
    
    NSInteger nextLoadAmount = 5;
    NSInteger remainingCount = categories.count - offset;
    if (remainingCount < nextLoadAmount) {
        nextLoadAmount = remainingCount;
    }
    
    [loader send:[categories subarrayWithRange:NSMakeRange(offset, nextLoadAmount)]];
}



/**
 * Get content for a category
 */
- (void)dabKickLiveSession:(DabKickLiveSessionSdk *)liveSessionInstance contentForCategory:(NSString *)title offset:(NSUInteger)offset contentType:(DabKickContentType)contentType loader:
(id<DabKickContentLoading>)loader {
    /**
     * Replace this line to return images from your application or service
     NSArray <UIImage *> *imagesArray = [self getImagesForCategoryWithTitle:title offset:offset];
     
     NSMutableArray <id <DabKickContent>> *contentArray = [[NSMutableArray alloc] initWithCapacity:imagesArray.count];
     [imagesArray enumerateObjectsUsingBlock:^(id _Nonnull content, NSUInteger idx, BOOL * _Nonnull stop) {
     DabKickImageContent *imageContent = [[DabKickImageContent alloc] init];
     imageContent.image = content;
     [contentArray addObject:imageContent];
     }];
     
     [loader send:contentArray];
     */
    
}


@end
