//
//  BarChartRenderer.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 4/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import CoreGraphics
import UIKit

@objc
public protocol BarChartRendererDelegate
{
    func barChartRendererData(renderer: BarChartRenderer) -> BarChartData!
    func barChartRenderer(renderer: BarChartRenderer, transformerForAxis which: ChartYAxis.AxisDependency) -> ChartTransformer!
    func barChartRendererMaxVisibleValueCount(renderer: BarChartRenderer) -> Int
    func barChartDefaultRendererValueFormatter(renderer: BarChartRenderer) -> NSNumberFormatter!
    func barChartRendererChartYMax(renderer: BarChartRenderer) -> Double
    func barChartRendererChartYMin(renderer: BarChartRenderer) -> Double
    func barChartRendererChartXMax(renderer: BarChartRenderer) -> Double
    func barChartRendererChartXMin(renderer: BarChartRenderer) -> Double
    func barChartBarBorderLineWidth(renderer: BarChartRenderer) -> CGFloat
    func barChartIsDrawHighlightArrowEnabled(renderer: BarChartRenderer) -> Bool
    func barChartIsDrawValueAboveBarEnabled(renderer: BarChartRenderer) -> Bool
    func barChartIsDrawValueHightlightEnabled(renderer: BarChartRenderer) -> Bool
    func barChartIsDrawBarShadowEnabled(renderer: BarChartRenderer) -> Bool
    func barChartIsInverted(renderer: BarChartRenderer, axis: ChartYAxis.AxisDependency) -> Bool
}

public class BarChartRenderer: ChartDataRendererBase
{
    public weak var delegate: BarChartRendererDelegate?
    
    public init(delegate: BarChartRendererDelegate?, animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.delegate = delegate
    }
    
    public override func drawData(context: CGContext?)
    {
        let barData = delegate!.barChartRendererData(self)
        
        if (barData === nil)
        {
            return
        }
        
        for i in 0 ..< barData.dataSetCount
        {
            let set = barData.getDataSetByIndex(i)
            
            if set !== nil && set!.isVisible && set.entryCount > 0
            {
                drawDataSet(context, dataSet: set as! BarChartDataSet, index: i)
            }
        }
    }
    
    internal func drawDataSet(context: CGContext?, dataSet: BarChartDataSet, index: Int)
    {
        CGContextSaveGState(context!)
        
        let barData = delegate!.barChartRendererData(self)
        
        let trans = delegate!.barChartRenderer(self, transformerForAxis: dataSet.axisDependency)
        
        let drawBarShadowEnabled: Bool = delegate!.barChartIsDrawBarShadowEnabled(self)
        let dataSetOffset = (barData.dataSetCount - 1)
        let groupSpace = barData.groupSpace
        let groupSpaceHalf = groupSpace / 2.0
        let barSpace = dataSet.barSpace
        let barSpaceHalf = barSpace / 2.0
        let containsStacks = dataSet.isStacked
        let isInverted = delegate!.barChartIsInverted(self, axis: dataSet.axisDependency)
        var entries = dataSet.yVals as! [BarChartDataEntry]
        let barWidth: CGFloat = 0.5
        let phaseY = _animator.phaseY
        var barRect = CGRect()
        var barShadow = CGRect()
        var y: Double
        
        // do the drawing
        for (var j = 0, count = Int(ceil(CGFloat(dataSet.entryCount) * _animator.phaseX)); j < count; j += 1)
        {
            let e = entries[j]
            
            // calculate the x-position, depending on datasetcount
            let x = CGFloat(e.xIndex + e.xIndex * dataSetOffset) + CGFloat(index)
                + groupSpace * CGFloat(e.xIndex) + groupSpaceHalf
            var vals = e.values
            
            if (!containsStacks || vals == nil)
            {
                y = e.value
                
                let left = x - barWidth + barSpaceHalf
                let right = x + barWidth - barSpaceHalf
                var top = isInverted ? (y <= 0.0 ? CGFloat(y) : 0) : (y >= 0.0 ? CGFloat(y) : 0)
                var bottom = isInverted ? (y >= 0.0 ? CGFloat(y) : 0) : (y <= 0.0 ? CGFloat(y) : 0)
                
                // multiply the height of the rect with the phase
                if (top > 0)
                {
                    top *= phaseY
                }
                else
                {
                    bottom *= phaseY
                }
                
                barRect.origin.x = left
                barRect.size.width = right - left
                barRect.origin.y = top
                barRect.size.height = bottom - top
                
                trans.rectValueToPixel(&barRect)
                
                if (!viewPortHandler.isInBoundsLeft(barRect.origin.x + barRect.size.width))
                {
                    continue
                }
                
                if (!viewPortHandler.isInBoundsRight(barRect.origin.x))
                {
                    break
                }
                
                // if drawing the bar shadow is enabled
                if (drawBarShadowEnabled)
                {
                    barShadow.origin.x = barRect.origin.x
                    barShadow.origin.y = viewPortHandler.contentTop
                    barShadow.size.width = barRect.size.width
                    barShadow.size.height = viewPortHandler.contentHeight
                    
                    CGContextSetFillColorWithColor(context!, dataSet.barShadowColor.CGColor)
                    CGContextFillRect(context!, barShadow)
                }
                
                fillAndStrokeRect(context, dataSet: dataSet, xIndex: j, stackIndex: 0, rect: barRect)
            }
            else
            {
                var posY = 0.0
                var negY = -e.negativeSum
                var yStart = 0.0
                
                // if drawing the bar shadow is enabled
                if (drawBarShadowEnabled)
                {
                    y = e.value
                    
                    let left = x - barWidth + barSpaceHalf
                    let right = x + barWidth - barSpaceHalf
                    var top = isInverted ? (y <= 0.0 ? CGFloat(y) : 0) : (y >= 0.0 ? CGFloat(y) : 0)
                    var bottom = isInverted ? (y >= 0.0 ? CGFloat(y) : 0) : (y <= 0.0 ? CGFloat(y) : 0)
                    
                    // multiply the height of the rect with the phase
                    if (top > 0)
                    {
                        top *= phaseY
                    }
                    else
                    {
                        bottom *= phaseY
                    }
                    
                    barRect.origin.x = left
                    barRect.size.width = right - left
                    barRect.origin.y = top
                    barRect.size.height = bottom - top
                    
                    trans.rectValueToPixel(&barRect)
                    
                    barShadow.origin.x = barRect.origin.x
                    barShadow.origin.y = viewPortHandler.contentTop
                    barShadow.size.width = barRect.size.width
                    barShadow.size.height = viewPortHandler.contentHeight
                    
                    CGContextSetFillColorWithColor(context!, dataSet.barShadowColor.CGColor)
                    CGContextFillRect(context!, barShadow)
                }
                
                // fill the stack
                for k in 0 ..< vals!.count
                {
                    let value = vals![k]
                    
                    if value >= 0.0
                    {
                        y = posY
                        yStart = posY + value
                        posY = yStart
                    }
                    else
                    {
                        y = negY
                        yStart = negY + abs(value)
                        negY += abs(value)
                    }
                    
                    let left = x - barWidth + barSpaceHalf
                    let right = x + barWidth - barSpaceHalf
                    var top: CGFloat, bottom: CGFloat
                    if isInverted
                    {
                        bottom = y >= yStart ? CGFloat(y) : CGFloat(yStart)
                        top = y <= yStart ? CGFloat(y) : CGFloat(yStart)
                    }
                    else
                    {
                        top = y >= yStart ? CGFloat(y) : CGFloat(yStart)
                        bottom = y <= yStart ? CGFloat(y) : CGFloat(yStart)
                    }
                    
                    // multiply the height of the rect with the phase
                    top *= phaseY
                    bottom *= phaseY
                    
                    barRect.origin.x = left
                    barRect.size.width = right - left
                    barRect.origin.y = top
                    barRect.size.height = bottom - top
                    
                    trans.rectValueToPixel(&barRect)
                    
                    if (k == 0 && !viewPortHandler.isInBoundsLeft(barRect.origin.x + barRect.size.width))
                    {
                        // Skip to next bar
                        break
                    }
                    
                    // avoid drawing outofbounds values
                    if (!viewPortHandler.isInBoundsRight(barRect.origin.x))
                    {
                        break
                    }
                    
                    fillAndStrokeRect(context, dataSet: dataSet, xIndex: j, stackIndex: k, rect: barRect)
                }
            }
        }
        
        CGContextRestoreGState(context!)
    }
    
    /// Prepares a bar for being highlighted.
    internal func prepareBarHighlight(x: CGFloat, y1: Double, y2: Double, barspacehalf: CGFloat, trans: ChartTransformer, inout rect: CGRect)
    {
        let barWidth: CGFloat = 0.5
        
        let left = x - barWidth + barspacehalf
        let right = x + barWidth - barspacehalf
        let top = CGFloat(y1)
        let bottom = CGFloat(y2)
        
        rect.origin.x = left
        rect.origin.y = top
        rect.size.width = right - left
        rect.size.height = bottom - top
        
        trans.rectValueToPixel(&rect, phaseY: _animator.phaseY)
    }
    
    public override func drawValues(context: CGContext?, indices: [ChartHighlight]?) {
        guard let drawableOptions = drawOptions(indices) else {
            return
        }
        let hasMultipleTextColors = drawableOptions.textColor.count > 1;
        for i in 0 ..< drawableOptions.values.count {
            
            drawValue(context,
                value: drawableOptions.values[i],
                xPos: drawableOptions.xPositions[i],
                yPos: drawableOptions.yPositions[i],
                font: drawableOptions.textFont,
                align: .Center,
                color: (hasMultipleTextColors) ? drawableOptions.textColor[i]: drawableOptions.textColor.first!)
        }

    }
    
    public override func drawValues(context: CGContext?)
    {
        drawValues(context, indices: []);
    }
    
    internal func drawOptions(indices: [ChartHighlight]?) -> (values: [String], xPositions: [CGFloat], yPositions: [CGFloat], textFont: UIFont, textColor: [UIColor])? {
        // if values are drawn
        if (passesCheck())
        {
            let defaultValueFormatter = delegate!.barChartDefaultRendererValueFormatter(self)
            let drawValueAboveBar = delegate!.barChartIsDrawValueAboveBarEnabled(self)
            
            let barData = delegate!.barChartRendererData(self)
            var dataSets = barData.dataSets
            
            var posOffset: CGFloat
            var negOffset: CGFloat
            
            for (var i = 0, count = barData.dataSetCount; i < count; i += 1)
            {
                let dataSet = dataSets[i] as! BarChartDataSet
                
                if !dataSet.isDrawValuesEnabled || dataSet.entryCount == 0
                {
                    continue
                }
                
                let isInverted = delegate!.barChartIsInverted(self, axis: dataSet.axisDependency)
                
                // calculate the correct offset depending on the draw position of the value
                let valueOffsetPlus: CGFloat = 4.5
                let textFont = dataSet.valueFont
                let valueTextHeight = textFont.lineHeight
                posOffset = (drawValueAboveBar ? -(valueTextHeight + valueOffsetPlus) : valueOffsetPlus)
                negOffset = (drawValueAboveBar ? valueOffsetPlus : -(valueTextHeight + valueOffsetPlus))
                
                if (isInverted)
                {
                    posOffset = -posOffset - valueTextHeight
                    negOffset = -negOffset - valueTextHeight
                }
                
                var formatter = dataSet.valueFormatter
                if (formatter === nil)
                {
                    formatter = defaultValueFormatter
                }
                
                let trans = delegate!.barChartRenderer(self, transformerForAxis: dataSet.axisDependency)
                
                var entries = dataSet.yVals as! [BarChartDataEntry]
                
                var valuePoints = getTransformedValues(trans, entries: entries, dataSetIndex: i)
                
                // if only single values are drawn (sum)
                if (!dataSet.isStacked)
                {
                    var values: [String] = []
                    var xPositions: [CGFloat] = []
                    var yPositions: [CGFloat] = []
                    var colors: [UIColor] = []
                    for (var j = 0, count = Int(ceil(CGFloat(valuePoints.count) * _animator.phaseX)); j < count; j += 1)
                    {
                        if (!viewPortHandler.isInBoundsRight(valuePoints[j].x))
                        {
                            break
                        }
                        
                        if (!viewPortHandler.isInBoundsY(valuePoints[j].y)
                            || !viewPortHandler.isInBoundsLeft(valuePoints[j].x))
                        {
                            continue
                        }
                        
                        let val = dataSet.useXLabelsInsteadOfValues ? barData.xVals[j] : formatter!.stringFromNumber(entries[j].value)
                        
                        let xPos = valuePoints[j].x
                        let yPos = valuePoints[j].y + (val != nil ? posOffset : negOffset)
                        
                        var color = dataSet.valueTextColor
                        let results = indices!.filter { $0.xIndex == j}
                        if(delegate!.barChartIsDrawValueHightlightEnabled(self) && !results.isEmpty) {
                            color = dataSet.valueHighlightTextColor
                        }
                        colors.append(color)
                        values.append(val!)
                        xPositions.append(xPos)
                        yPositions.append(yPos)
                    }
                    
                    return (values: values, xPositions: xPositions, yPositions: yPositions, textFont: textFont, textColor: colors)
                }
                else
                {
                    // if we have stacks
                    var stringValues: [String] = []
                    var xPositions: [CGFloat] = []
                    var yPositions: [CGFloat] = []
                    
                    for (var j = 0, count = Int(ceil(CGFloat(valuePoints.count) * _animator.phaseX)); j < count; j += 1)
                    {
                        let e = entries[j]
                        
                        let values = e.values
                        
                        // we still draw stacked bars, but there is one non-stacked in between
                        if (values == nil)
                        {
                            if (!viewPortHandler.isInBoundsRight(valuePoints[j].x))
                            {
                                break
                            }
                            
                            if (!viewPortHandler.isInBoundsY(valuePoints[j].y)
                                || !viewPortHandler.isInBoundsLeft(valuePoints[j].x))
                            {
                                continue
                            }
                            
                            let value = formatter!.stringFromNumber(e.value)!
                            let xPos = valuePoints[j].x
                            let yPos = valuePoints[j].y + (e.value >= 0.0 ? posOffset : negOffset)
                            stringValues.append(value)
                            xPositions.append(xPos)
                            yPositions.append(yPos)
                        }
                        else
                        {
                            // draw stack values
                            
                            let vals = values!
                            var transformed = [CGPoint]()
                            
                            var posY = 0.0
                            var negY = -e.negativeSum
                            
                            if dataSet.displayFirstValueOnly
                            {
                                var value = String()
                                
                                if (vals[0] == NSNumber(double: 0) && dataSet.displayZeroValues) ||
                                    vals[0] != NSNumber(double: 0) {
                                        value = formatter!.stringFromNumber(vals[0])!
                                }
                                
                                let xPos = valuePoints[j].x
                                let yPos = valuePoints[j].y + (vals[0] >= 0 ? posOffset : negOffset)
                                
                                stringValues.append(value)
                                xPositions.append(xPos)
                                yPositions.append(yPos)
                            }
                            else
                            {
                                for k in 0 ..< vals.count
                                {
                                    let value = vals[k]
                                    var y: Double
                                    
                                    if value >= 0.0
                                    {
                                        posY += value
                                        y = posY
                                    }
                                    else
                                    {
                                        y = negY
                                        negY -= value
                                    }
                                    
                                    transformed.append(CGPoint(x: 0.0, y: CGFloat(y) * _animator.phaseY))
                                }
                                
                                trans.pointValuesToPixel(&transformed)
                                
                                for k in 0 ..< transformed.count
                                {
                                    let xPos = valuePoints[j].x
                                    let yPos = transformed[k].y + (vals[k] >= 0 ? posOffset : negOffset)
                                    
                                    if (!viewPortHandler.isInBoundsRight(xPos))
                                    {
                                        break
                                    }
                                    
                                    if (!viewPortHandler.isInBoundsY(yPos) || !viewPortHandler.isInBoundsLeft(xPos))
                                    {
                                        continue
                                    }
                                    
                                    let value = formatter!.stringFromNumber(vals[k])!
                                    
                                    stringValues.append(value)
                                    xPositions.append(xPos)
                                    yPositions.append(yPos)
                                }
                            }
                        }
                    }
                    
                    return (values: stringValues, xPositions: xPositions, yPositions: yPositions, textFont: textFont, textColor: [dataSet.valueTextColor])
                }
            }
        }
        return nil
    }
    
    /// Draws a value at the specified x and y position.
    internal func drawValue(context: CGContext?, value: String, xPos: CGFloat, yPos: CGFloat, font: UIFont, align: NSTextAlignment, color: UIColor)
    {
        ChartUtils.drawText(context, text: value, point: CGPoint(x: xPos, y: yPos), align: align, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: color])
    }
    
    public override func drawExtras(context: CGContext?)
    {
        
    }
    
    private var _highlightArrowPtsBuffer = [CGPoint](count: 3, repeatedValue: CGPoint())
    
    public override func drawHighlighted(context: CGContext?, indices: [ChartHighlight])
    {
        let barData = delegate!.barChartRendererData(self)
        if (barData === nil)
        {
            return
        }
        
        CGContextSaveGState(context!)
        
        let setCount = barData.dataSetCount
        let drawHighlightArrowEnabled = delegate!.barChartIsDrawHighlightArrowEnabled(self)
        var barRect = CGRect()
        
        for i in 0 ..< indices.count
        {
            let h = indices[i]
            let index = h.xIndex
            
            let dataSetIndex = h.dataSetIndex
            let set = barData.getDataSetByIndex(dataSetIndex) as! BarChartDataSet!
            
            if (set === nil || !set.isHighlightEnabled)
            {
                continue
            }
            
            let barspaceHalf = set.barSpace / 2.0
            
            let trans = delegate!.barChartRenderer(self, transformerForAxis: set.axisDependency)
            
            CGContextSetFillColorWithColor(context!, set.highlightColor.CGColor)
            CGContextSetStrokeColorWithColor(context!, set.highlightColor.CGColor)
            CGContextSetAlpha(context!, set.highLightAlpha)
            
            // check outofbounds
            if (CGFloat(index) < (CGFloat(delegate!.barChartRendererChartXMax(self)) * _animator.phaseX) / CGFloat(setCount))
            {
                let e = set.entryForXIndex(index) as! BarChartDataEntry!
                
                if (e === nil || e.xIndex != index)
                {
                    continue
                }
                
                let groupspace = barData.groupSpace
                let isStack = h.stackIndex < 0 ? false : true

                // calculate the correct x-position
                let x = CGFloat(index * setCount + dataSetIndex) + groupspace / 2.0 + groupspace * CGFloat(index)
                
                let y1: Double
                let y2: Double
                
                if (isStack)
                {
                    y1 = h.range?.from ?? 0.0
                    y2 = h.range?.to ?? 0.0
                }
                else
                {
                    y1 = e.value
                    y2 = 0.0
                }

                prepareBarHighlight(x, y1: y1, y2: y2, barspacehalf: barspaceHalf, trans: trans, rect: &barRect)

                let index = BarChartStakedIndex(xIndex: h.xIndex, stackIndex: h.stackIndex < 0 ? 0 : h.stackIndex )
                if let strokeOptions = set.strokeOptions[index] {
                    let strokeStyle = strokeOptions.strokeStyle
                    strokeRect(context, rect: barRect, color: set.highlightColor, style: strokeStyle)
                } else {
                    CGContextFillRect(context!, barRect)
                }
                
                if (drawHighlightArrowEnabled)
                {
                    CGContextSetAlpha(context!, 1.0)
                    
                    // distance between highlight arrow and bar
                    let offsetY = _animator.phaseY * 0.07
                    
                    CGContextSaveGState(context!)
                    
                    let pixelToValueMatrix = trans.pixelToValueMatrix
                    let xToYRel = abs(sqrt(pixelToValueMatrix.b * pixelToValueMatrix.b + pixelToValueMatrix.d * pixelToValueMatrix.d) / sqrt(pixelToValueMatrix.a * pixelToValueMatrix.a + pixelToValueMatrix.c * pixelToValueMatrix.c))
                    
                    let arrowWidth = set.barSpace / 2.0
                    let arrowHeight = arrowWidth * xToYRel
                    
                    let yArrow = (y1 > -y2 ? y1 : y1) * Double(_animator.phaseY)
                    
                    _highlightArrowPtsBuffer[0].x = CGFloat(x) + 0.4
                    _highlightArrowPtsBuffer[0].y = CGFloat(yArrow) + offsetY
                    _highlightArrowPtsBuffer[1].x = CGFloat(x) + 0.4 + arrowWidth
                    _highlightArrowPtsBuffer[1].y = CGFloat(yArrow) + offsetY - arrowHeight
                    _highlightArrowPtsBuffer[2].x = CGFloat(x) + 0.4 + arrowWidth
                    _highlightArrowPtsBuffer[2].y = CGFloat(yArrow) + offsetY + arrowHeight
                    
                    trans.pointValuesToPixel(&_highlightArrowPtsBuffer)
                    
                    CGContextBeginPath(context!)
                    CGContextMoveToPoint(context!, _highlightArrowPtsBuffer[0].x, _highlightArrowPtsBuffer[0].y)
                    CGContextAddLineToPoint(context!, _highlightArrowPtsBuffer[1].x, _highlightArrowPtsBuffer[1].y)
                    CGContextAddLineToPoint(context!, _highlightArrowPtsBuffer[2].x, _highlightArrowPtsBuffer[2].y)
                    CGContextClosePath(context!)
                    
                    CGContextFillPath(context!)
                    
                    CGContextRestoreGState(context!)
                }
            }
        }
        
        CGContextRestoreGState(context!)
    }
    
    public func getTransformedValues(trans: ChartTransformer, entries: [BarChartDataEntry], dataSetIndex: Int) -> [CGPoint]
    {
        return trans.generateTransformedValuesBarChart(entries, dataSet: dataSetIndex, barData: delegate!.barChartRendererData(self)!, phaseY: _animator.phaseY)
    }
    
    internal func passesCheck() -> Bool
    {
        let barData = delegate!.barChartRendererData(self)
        
        if (barData === nil)
        {
            return false
        }
        
        return CGFloat(barData.yValCount) < CGFloat(delegate!.barChartRendererMaxVisibleValueCount(self)) * viewPortHandler.scaleX
    }
    
    // Set the color for the currently drawn value. If the index is out of bounds, reuse colors.
    // After, fill or stroke given rect.
    internal func fillAndStrokeRect(context: CGContext?, dataSet: BarChartDataSet, xIndex: Int, stackIndex: Int, rect: CGRect) {
        
        // fill rect with color
        var color: UIColor?
        let colorIndex = xIndex * dataSet.stackSize + stackIndex
        if dataSet.isStacked && colorIndex < dataSet.colors.count {
            color = dataSet.colors[colorIndex]
        } else {
            color = dataSet.colorAt(xIndex)
        }
        
        CGContextSetFillColorWithColor(context!, (color?.CGColor)!)
        CGContextFillRect(context!, rect)
        
        let index = BarChartStakedIndex(xIndex: xIndex, stackIndex: stackIndex)
        if let strokeOptions = dataSet.strokeOptions[index] {
            let strokeColor = strokeOptions.strokeColor
            let strokeStyle = strokeOptions.strokeStyle
            
            strokeRect(context, rect: rect, color: strokeColor, style: strokeStyle)
        }
    }
    
    // Stroke rect with options
    internal func strokeRect(context: CGContext?, rect: CGRect, color: UIColor, style: BarChartStrokeStyle) {
        CGContextSetStrokeColorWithColor(context!, color.CGColor)
        
        var lengths: [CGFloat]?
        
        switch style {
        case .Solid:
            lengths = nil
        case .Dashed:
            lengths = [4, 3]
        case .Dotted:
            lengths = [1, 1]
        }
        
        if let lengths = lengths {
            CGContextSetLineDash(context!, 0, lengths, lengths.count)
        } else {
            CGContextSetLineDash(context!, 0, nil, 0)
        }
        
        let lineWidth = delegate!.barChartBarBorderLineWidth(self)
        CGContextStrokeRect(context!, CGRectInset(rect, lineWidth, 0))
    }
}
