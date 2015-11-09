//
//  BarChartViewController.m
//  ChartsDemo
//
//  Created by Daniel Cohen Gindi on 17/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

#import "BarChartViewController.h"
#import "ChartsDemo-Swift.h"

@interface BarChartViewController () <ChartViewDelegate>

@property (nonatomic, strong) IBOutlet BarChartView *chartView;
@property (nonatomic, strong) IBOutlet UISlider *sliderX;
@property (nonatomic, strong) IBOutlet UISlider *sliderY;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextX;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextY;

@end

@implementation BarChartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Bar Chart";
    
    self.options = @[
                     @{@"key": @"toggleValues", @"label": @"Toggle Values"},
                     @{@"key": @"toggleHighlight", @"label": @"Toggle Highlight"},
                     @{@"key": @"toggleHighlightArrow", @"label": @"Toggle Highlight Arrow"},
                     @{@"key": @"animateX", @"label": @"Animate X"},
                     @{@"key": @"animateY", @"label": @"Animate Y"},
                     @{@"key": @"animateXY", @"label": @"Animate XY"},
                     @{@"key": @"toggleStartZero", @"label": @"Toggle StartZero"},
                     @{@"key": @"saveToGallery", @"label": @"Save to Camera Roll"},
                     @{@"key": @"togglePinchZoom", @"label": @"Toggle PinchZoom"},
                     @{@"key": @"toggleAutoScaleMinMax", @"label": @"Toggle auto scale min/max"},
                     ];
    
    _chartView.delegate = self;
    
    _chartView.descriptionText = @"";
    _chartView.noDataTextDescription = @"You need to provide data for the chart.";
    
    _chartView.drawBarShadowEnabled = NO;
    _chartView.drawValueAboveBarEnabled = YES;
    
    _chartView.maxVisibleValueCount = 60;
    _chartView.pinchZoomEnabled = NO;
    _chartView.doubleTapToZoomEnabled = NO;

    _chartView.drawBordersEnabled = NO;
    _chartView.leftAxis.enabled = NO;
    _chartView.rightAxis.enabled = NO;
    _chartView.xAxis.enabled = NO;
    _chartView.legend.enabled = NO;
    [_chartView setScaleEnabled:NO];
    _chartView.disableHighlightToggle = YES;
    
    _sliderX.value = 6.0;
    _sliderY.value = 50.0;
    [self slidersValueChanged:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // select first chart index
    [_chartView highlightValueWithXIndex:0 dataSetIndex:0 callDelegate:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDataCount:(int)count range:(double)range
{
    NSMutableArray *xVals = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < count; i++)
    {
        NSString *month = months[i % 12];
        [xVals addObject:month.uppercaseString];
    }
    
    NSMutableArray *yVals = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < count; i++)
    {
        double mult = (range + 1);
        double val = (double) (arc4random_uniform(mult));
        [yVals addObject:[[BarChartDataEntry alloc] initWithValue:val xIndex:i]];
    }
    
    BarChartDataSet *set1 = [[BarChartDataSet alloc] initWithYVals:yVals label:@"DataSet"];
    set1.barSpace = 0.35;
    NSMutableArray *colors = [NSMutableArray new];
    for (int i = 0; i < set1.entryCount; i ++) {
        if (i == set1.entryCount - 1) {
            [colors addObject:[UIColor clearColor]];
        } else {
            [colors addObject:[UIColor colorWithRed:138/255. green:144/255. blue:149/255. alpha:0.85]];
        }
    }
    set1.colors = colors;
    set1.highlightColor = [UIColor colorWithRed:228/255. green:221/255. blue:213/255. alpha:0.85];
    set1.highLightAlpha = 1;
    
    BarChartStakedIndex *index = [[BarChartStakedIndex alloc] initWithXIndex:set1.entryCount - 1 stackIndex:0];
    
    UIColor *strokeColor = [UIColor colorWithRed:138/255. green:144/255. blue:149/255. alpha:0.85];
    BarChartStrokeStyle strokeStyle = BarChartStrokeStyleSolid;
    
    BarChartStrokeOption *strokeOption = [[BarChartStrokeOption alloc] initWithStrokeColor:strokeColor
                                                                               strokeStyle:strokeStyle];
    NSMutableDictionary *strokeOptions = set1.strokeOptions.mutableCopy;
    strokeOptions[index] = strokeOption;
    set1.strokeOptions = strokeOptions;
    
    set1.barSpace = 0.5;
    set1.useXLabelsInsteadOfValues = YES;
    
    NSMutableArray *dataSets = [[NSMutableArray alloc] init];
    [dataSets addObject:set1];
    
    BarChartData *data = [[BarChartData alloc] initWithXVals:xVals dataSets:dataSets];
    [data setValueFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:10.f]];
    [data setValueTextColor:[UIColor colorWithRed:138/255. green:144/255. blue:149/255. alpha:0.85]];
    [data setHighlightEnabled:YES];
    
    _chartView.data = data;
}

- (void)optionTapped:(NSString *)key
{
    if ([key isEqualToString:@"toggleValues"])
    {
        for (ChartDataSet *set in _chartView.data.dataSets)
        {
            set.drawValuesEnabled = !set.isDrawValuesEnabled;
        }
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleHighlight"])
    {
        _chartView.highlightEnabled = !_chartView.isHighlightEnabled;
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleHighlightArrow"])
    {
        _chartView.drawHighlightArrowEnabled = !_chartView.isDrawHighlightArrowEnabled;
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleStartZero"])
    {
        _chartView.leftAxis.startAtZeroEnabled = !_chartView.leftAxis.isStartAtZeroEnabled;
        _chartView.rightAxis.startAtZeroEnabled = !_chartView.rightAxis.isStartAtZeroEnabled;
        
        [_chartView notifyDataSetChanged];
    }
    
    if ([key isEqualToString:@"animateX"])
    {
        [_chartView animateWithXAxisDuration:3.0];
    }
    
    if ([key isEqualToString:@"animateY"])
    {
        [_chartView animateWithYAxisDuration:3.0];
    }
    
    if ([key isEqualToString:@"animateXY"])
    {
        [_chartView animateWithXAxisDuration:3.0 yAxisDuration:3.0];
    }
    
    if ([key isEqualToString:@"saveToGallery"])
    {
        [_chartView saveToCameraRoll];
    }
    
    if ([key isEqualToString:@"togglePinchZoom"])
    {
        _chartView.pinchZoomEnabled = !_chartView.isPinchZoomEnabled;
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleAutoScaleMinMax"])
    {
        _chartView.autoScaleMinMaxEnabled = !_chartView.isAutoScaleMinMaxEnabled;
        [_chartView notifyDataSetChanged];
    }
}

#pragma mark - Actions

- (IBAction)slidersValueChanged:(id)sender
{
    _sliderTextX.text = [@((int)_sliderX.value + 1) stringValue];
    _sliderTextY.text = [@((int)_sliderY.value) stringValue];
    
    [self setDataCount:(_sliderX.value + 1) range:_sliderY.value];
}

#pragma mark - ChartViewDelegate

- (void)chartValueSelected:(ChartViewBase * __nonnull)chartView entry:(ChartDataEntry * __nonnull)entry dataSetIndex:(NSInteger)dataSetIndex highlight:(ChartHighlight * __nonnull)highlight
{
    NSLog(@"chartValueSelected");
}

- (void)chartValueNothingSelected:(ChartViewBase * __nonnull)chartView
{
    NSLog(@"chartValueNothingSelected");
}

@end
