//
//  ViewController.m
//  BarcodeScanner
//
//  Created by Kevin Nguy on 1/13/16.
//  Copyright © 2016 kevinnguy. All rights reserved.
//

#import "MTBBarcodeScanner.h"

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *scannerView;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@property (nonatomic, strong) MTBBarcodeScanner *scanner;
@property (nonatomic, strong) NSMutableDictionary *overlayViews;
@property (nonatomic, strong) NSMutableArray *barcodes;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view layoutIfNeeded];
    
    self.scanner = [[MTBBarcodeScanner alloc] initWithPreviewView:self.cameraView];
    self.scanner.scanRect = self.scannerView.frame;
    
    [self.submitButton setTitle:@"Copy scanned barcodes" forState:UIControlStateNormal];
    [self.submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.submitButton.titleLabel.font = [UIFont systemFontOfSize:18];
    self.submitButton.backgroundColor = [UIColor blueColor];
    [self.submitButton addTarget:self action:@selector(submitButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.overlayViews = [NSMutableDictionary new];
    self.barcodes = [NSMutableArray new];
    
    self.scannerView.alpha = 0.2f;
    self.scannerView.backgroundColor = [UIColor blackColor];
    self.scannerView.layer.borderColor = [UIColor greenColor].CGColor;
    self.scannerView.layer.borderWidth = 4;
    
    [self.scanner startScanningWithResultBlock:^(NSArray *codes) {
        [self drawOverlaysOnCodes:codes];
    }];
}

- (void)drawOverlaysOnCodes:(NSArray *)codes {
    // Get all of the captured code strings
    NSMutableArray *codeStrings = [[NSMutableArray alloc] init];
    for (AVMetadataMachineReadableCodeObject *code in codes) {
        if (code.stringValue) {
            [codeStrings addObject:code.stringValue];
        }
    }
    
    // Remove any code overlays no longer on the screen
    for (NSString *code in self.overlayViews.allKeys) {
        if ([codeStrings indexOfObject:code] == NSNotFound) {
            // A code that was on the screen is no longer
            // in the list of captured codes, remove its overlay
            [self.overlayViews[code] removeFromSuperview];
            [self.overlayViews removeObjectForKey:code];
        }
    }
    
    for (AVMetadataMachineReadableCodeObject *code in codes) {
        UIView *view = nil;
        NSString *codeString = code.stringValue;
        
        if (!codeString.length) {
            continue;
        }
        
        if (self.overlayViews[codeString]) {
            // The overlay is already on the screen
            view = self.overlayViews[codeString];
            
            // Move it to the new location
            view.frame = code.bounds;
        } else {
            // Create an overlay
            UIView *overlayView = [self overlayForCodeString:codeString
                                                      bounds:code.bounds];
            self.overlayViews[codeString] = overlayView;
            
            // Add the overlay to the preview view
            [self.cameraView addSubview:overlayView];
            
            // Add codestring to barcodes array
            [self.barcodes addObject:codeString];
        }
    }
}

- (UIView *)overlayForCodeString:(NSString *)codeString bounds:(CGRect)bounds {
    UIColor *viewColor = [UIColor redColor];
    UIView *view = [[UIView alloc] initWithFrame:bounds];
    UILabel *label = [[UILabel alloc] initWithFrame:view.bounds];
    
    // Configure the view
    view.layer.borderWidth = 5.0;
    view.backgroundColor = [viewColor colorWithAlphaComponent:0.75];
    view.layer.borderColor = viewColor.CGColor;
    
    // Configure the label
    label.font = [UIFont boldSystemFontOfSize:12];
    label.text = codeString;
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    
    // Add the label to the view
    [view addSubview:label];
    
    return view;
}

#pragma mark - Button pressed
- (void)submitButtonPressed:(id)sender {
    NSString *pasteString = @"";
    for (NSString *barcode in self.barcodes) {
        pasteString = [pasteString stringByAppendingString:[NSString stringWithFormat:@"%@,\n", barcode]];
    }
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = pasteString;

    [self.barcodes removeAllObjects];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Copied to clipboard" message:@"Paste barcodes to Slack or email or something." delegate:nil cancelButtonTitle:@"I'm Awesome" otherButtonTitles:nil];
    [alertView show];
}

@end
