//
//  StackedBarChartViewController.m
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

#import "StackedBarChartViewController.h"
#import "ChartsDemo-Swift.h"

@interface StackedBarChartViewController () <ChartViewDelegate>

@property (nonatomic, strong) IBOutlet BarChartView *chartView;
@property (nonatomic, strong) IBOutlet UISlider *sliderX;
@property (nonatomic, strong) IBOutlet UISlider *sliderY;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextX;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextY;

@end

@implementation StackedBarChartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Stacked Bar Chart";
    
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
    
    _chartView.pinchZoomEnabled = NO;
    _chartView.drawGridBackgroundEnabled = NO;
    _chartView.drawBarShadowEnabled = NO;
    _chartView.drawValueAboveBarEnabled = YES;
    
    _chartView.maxVisibleValueCount = 60;
    _chartView.pinchZoomEnabled = NO;
    _chartView.doubleTapToZoomEnabled = NO;
    
    _chartView.drawBordersEnabled = NO;
    _chartView.leftAxis.enabled = NO;
    _chartView.rightAxis.enabled = NO;
    _chartView.xAxis.enabled = YES;
    _chartView.legend.enabled = NO;
    [_chartView setScaleEnabled:NO];
    _chartView.dragEnabled = YES;
    [_chartView zoom:1.5 scaleY:1 x:200 y:0];
    
    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelPosition = XAxisLabelPositionBottom;
    xAxis.labelFont = [UIFont systemFontOfSize:10.f];
    xAxis.drawAxisLineEnabled = NO;
    xAxis.drawGridLinesEnabled = NO;
    xAxis.gridLineWidth = .3;
    
    ChartLimitLine *ll1 = [[ChartLimitLine alloc] initWithLimit:11000.0 label:@"Average"];
    ll1.lineWidth = 0.5;
    ll1.lineDashLengths = @[@4.f, @4.f];
    ll1.labelPosition = ChartLimitLabelPositionRightBottom;
    ll1.valueFont = [UIFont systemFontOfSize:10.0];
    ll1.lineColor = [UIColor grayColor];
    
    ChartYAxis *leftAxis = _chartView.leftAxis;
    [leftAxis removeAllLimitLines];
    [leftAxis addLimitLine:ll1];
    leftAxis.startAtZeroEnabled = NO;
    
    _sliderX.value = 12.0;
    _sliderY.value = 15000.0;
    [self slidersValueChanged:nil];
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
        [xVals addObject:months[i % 12]];
    }
    
    NSMutableArray *yVals = [[NSMutableArray alloc] init];
    NSMutableArray *randomYVals = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < count; i++)
    {
        double mult = (15000 + 1);
        double val1 = (double) (arc4random_uniform(mult) + mult / 3);
        
        [randomYVals addObject:@(val1)];
    }
    
    double max = 0;
    for (NSNumber *val in randomYVals) {
        if (val.doubleValue > max) {
            max = val.doubleValue;
        }
    }
    
    for (NSNumber *val in randomYVals) {
        NSInteger index = [randomYVals indexOfObject:val];
        double val2 = max - val.doubleValue;
        [yVals addObject:[[BarChartDataEntry alloc] initWithValues:@[val, @(val2)] xIndex:index]];
    }
    
    BarChartDataSet *set1 = [[BarChartDataSet alloc] initWithYVals:yVals label:@"Statistics Vienna 2014"];
    NSMutableArray *colors = [NSMutableArray new];
    for (int i = 0; i < set1.entryCount * 2; i ++) {
        if (i % 2 == 0) {
            [colors addObject:ChartColorTemplates.vordiplom[1]];
        } else {
            [colors addObject:ChartColorTemplates.vordiplom[0]];
        }
    }
    set1.colors = colors;
    set1.stackLabels = @[@"Births", @"Divorces"];
    set1.highlightColor = [UIColor colorWithRed:228/255. green:221/255. blue:213/255. alpha:0.85];
    set1.highLightAlpha = 1;
    set1.highlightEnabled = NO;
    set1.barSpace = 0.3;
    set1.displayFirstValueOnly = YES;
    
    BarChartStakedIndex *index = [[BarChartStakedIndex alloc] initWithXIndex:set1.entryCount - 1 stackIndex:0];
    
    UIColor *strokeColor = [UIColor redColor];
    BarChartStrokeStyle strokeStyle = BarChartStrokeStyleDotted;
    
    BarChartStrokeOption *strokeOption = [[BarChartStrokeOption alloc] initWithStrokeColor:strokeColor
                                                                               strokeStyle:strokeStyle];
    NSMutableDictionary *strokeOptions = set1.strokeOptions.mutableCopy;
    strokeOptions[index] = strokeOption;
    set1.strokeOptions = strokeOptions;
    
    NSMutableArray *dataSets = [[NSMutableArray alloc] init];
    [dataSets addObject:set1];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.maximumFractionDigits = 1;
    
    BarChartData *data = [[BarChartData alloc] initWithXVals:xVals dataSets:dataSets];
    [data setValueFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:7.f]];
    [data setValueFormatter:formatter];
    
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
    NSLog(@"chartValueSelected, stack-index %ld", (long)highlight.stackIndex);
}

- (void)chartValueNothingSelected:(ChartViewBase * __nonnull)chartView
{
    NSLog(@"chartValueNothingSelected");
}

@end
