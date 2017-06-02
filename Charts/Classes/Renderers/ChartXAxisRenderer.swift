//
//  ChartXAxisRenderer.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 3/3/15.
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

open class ChartXAxisRenderer: ChartAxisRendererBase
{
    internal var _xAxis: ChartXAxis!
  
    public init(viewPortHandler: ChartViewPortHandler, xAxis: ChartXAxis, transformer: ChartTransformer!)
    {
        super.init(viewPortHandler: viewPortHandler, transformer: transformer)
        
        _xAxis = xAxis
    }
    
    open func computeAxis(_ xValAverageLength: Double, xValues: [String?])
    {
        var a = ""
        
        let max = Int(round(xValAverageLength + Double(_xAxis.spaceBetweenLabels)))
        
        for _ in 0 ..< max
        {
            a += "h"
        }
        
        let widthText = a as NSString
        
        _xAxis.labelWidth = widthText.size(attributes: [NSFontAttributeName: _xAxis.labelFont]).width
        _xAxis.labelHeight = _xAxis.labelFont.lineHeight
        _xAxis.values = xValues
    }
    
    open override func renderAxisLabels(_ context: CGContext?)
    {
        if (!_xAxis.isEnabled || !_xAxis.isDrawLabelsEnabled)
        {
            return
        }
        
        let yoffset = CGFloat(4.0)
        
        if (_xAxis.labelPosition == .top)
        {
            drawLabels(context, pos: viewPortHandler.offsetTop - _xAxis.labelHeight - yoffset)
        }
        else if (_xAxis.labelPosition == .bottom)
        {
            drawLabels(context, pos: viewPortHandler.contentBottom + yoffset * 1.5)
        }
        else if (_xAxis.labelPosition == .bottomInside)
        {
            drawLabels(context, pos: viewPortHandler.contentBottom - _xAxis.labelHeight - yoffset)
        }
        else if (_xAxis.labelPosition == .topInside)
        {
            drawLabels(context, pos: viewPortHandler.offsetTop + yoffset)
        }
        else
        { // BOTH SIDED
            drawLabels(context, pos: viewPortHandler.offsetTop - _xAxis.labelHeight - yoffset)
            drawLabels(context, pos: viewPortHandler.contentBottom + yoffset * 1.6)
        }
    }
    
    fileprivate var _axisLineSegmentsBuffer = [CGPoint](repeating: CGPoint(), count: 2)
    
    open override func renderAxisLine(_ context: CGContext?)
    {
        if (!_xAxis.isEnabled || !_xAxis.isDrawAxisLineEnabled)
        {
            return
        }
        
        context!.saveGState()
        
        context!.setStrokeColor(_xAxis.axisLineColor.cgColor)
        context!.setLineWidth(_xAxis.axisLineWidth)
        if (_xAxis.axisLineDashLengths != nil)
        {
            context!.setLineDash(phase: _xAxis.axisLineDashPhase, lengths: _xAxis.axisLineDashLengths)
        }
        else
        {
            context!.setLineDash(phase: 0.0, lengths: [])
        }

        if (_xAxis.labelPosition == .top
                || _xAxis.labelPosition == .topInside
                || _xAxis.labelPosition == .bothSided)
        {
            _axisLineSegmentsBuffer[0].x = viewPortHandler.contentLeft
            _axisLineSegmentsBuffer[0].y = viewPortHandler.contentTop
            _axisLineSegmentsBuffer[1].x = viewPortHandler.contentRight
            _axisLineSegmentsBuffer[1].y = viewPortHandler.contentTop
            context!.strokeLineSegments(between: _axisLineSegmentsBuffer)
        }

        if (_xAxis.labelPosition == .bottom
                || _xAxis.labelPosition == .bottomInside
                || _xAxis.labelPosition == .bothSided)
        {
            _axisLineSegmentsBuffer[0].x = viewPortHandler.contentLeft
            _axisLineSegmentsBuffer[0].y = viewPortHandler.contentBottom
            _axisLineSegmentsBuffer[1].x = viewPortHandler.contentRight
            _axisLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
            context!.strokeLineSegments(between: _axisLineSegmentsBuffer)
        }
        
        context!.restoreGState()
    }
    
    /// draws the x-labels on the specified y-position
    internal func drawLabels(_ context: CGContext?, pos: CGFloat)
    {
        let paraStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paraStyle.alignment = .center
        
        let labelAttrs = [NSFontAttributeName: _xAxis.labelFont,
            NSForegroundColorAttributeName: _xAxis.labelTextColor,
            NSParagraphStyleAttributeName: paraStyle] as [String : Any]
        
        let valueToPixelMatrix = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        var labelMaxSize = CGSize()
        
        if (_xAxis.isWordWrapEnabled)
        {
            labelMaxSize.width = _xAxis.wordWrapWidthPercent * valueToPixelMatrix.a
        }
        let maxX = min(_maxX + 1, _xAxis.values.count)
        for i in stride(from: _minX, to: maxX, by: _xAxis.axisLabelModulus)
        {
            let label = _xAxis.values[i]
            if (label == nil)
            {
                continue
            }
            
            position.x = CGFloat(i)
            position.y = 0.0
            position = position.applying(valueToPixelMatrix)
            
            if (viewPortHandler.isInBoundsX(position.x))
            {
                let labelns = label! as NSString
                
                if (_xAxis.isAvoidFirstLastClippingEnabled)
                {
                    // avoid clipping of the last
                    if (i == _xAxis.values.count - 1 && _xAxis.values.count > 1)
                    {
                        let width = labelns.boundingRect(with: labelMaxSize, options: .usesLineFragmentOrigin, attributes: labelAttrs, context: nil).size.width
                        
                        if (width > viewPortHandler.offsetRight * 2.0
                            && position.x + width > viewPortHandler.chartWidth)
                        {
                            position.x -= width / 2.0
                        }
                    }
                    else if (i == 0)
                    { // avoid clipping of the first
                        let width = labelns.boundingRect(with: labelMaxSize, options: .usesLineFragmentOrigin, attributes: labelAttrs, context: nil).size.width
                        position.x += width / 2.0
                    }
                }
                
                drawLabel(context, label: label!, xIndex: i, x: position.x, y: pos, align: .center, attributes: labelAttrs as! [String : NSObject], constrainedToSize: labelMaxSize)
            }
        }
    }
    
    internal func drawLabel(_ context: CGContext?, label: String, xIndex: Int, x: CGFloat, y: CGFloat, align: NSTextAlignment, attributes: [String: NSObject], constrainedToSize: CGSize)
    {
        let formattedLabel = _xAxis.valueFormatter?.stringForXValue(xIndex, original: label, viewPortHandler: viewPortHandler) ?? label
        ChartUtils.drawMultilineText(context, text: formattedLabel, point: CGPoint(x: x, y: y), align: align, attributes: attributes, constrainedToSize: constrainedToSize)
    }
    
    fileprivate var _gridLineSegmentsBuffer = [CGPoint](repeating: CGPoint(), count: 2)
    
    open override func renderGridLines(_ context: CGContext?)
    {
        if (!_xAxis.isDrawGridLinesEnabled || !_xAxis.isEnabled)
        {
            return
        }
        
        context!.saveGState()
        
        context!.setStrokeColor(_xAxis.gridColor.cgColor)
        context!.setLineWidth(_xAxis.gridLineWidth)
        if (_xAxis.gridLineDashLengths != nil)
        {
            context!.setLineDash(phase: _xAxis.gridLineDashPhase, lengths: _xAxis.gridLineDashLengths)
        }
        else
        {
            context!.setLineDash(phase: 0.0, lengths: [])
        }
        
        let valueToPixelMatrix = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        for i in stride(from: _minX, to: _maxX, by: _xAxis.axisLabelModulus)
        {
            position.x = CGFloat(i)
            position.y = 0.0
            position = position.applying(valueToPixelMatrix)
            
            if (position.x >= viewPortHandler.offsetLeft
                && position.x <= viewPortHandler.chartWidth)
            {
                _gridLineSegmentsBuffer[0].x = position.x
                _gridLineSegmentsBuffer[0].y = viewPortHandler.contentTop
                _gridLineSegmentsBuffer[1].x = position.x
                _gridLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
                context!.strokeLineSegments(between: _gridLineSegmentsBuffer)
            }
        }
        
        context!.restoreGState()
    }
    
    fileprivate var _limitLineSegmentsBuffer = [CGPoint](repeating: CGPoint(), count: 2)
    
    open override func renderLimitLines(_ context: CGContext?)
    {
        var limitLines = _xAxis.limitLines
        
        if (limitLines.count == 0)
        {
            return
        }
        
        context!.saveGState()
        
        let trans = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        for i in 0 ..< limitLines.count
        {
            let l = limitLines[i]
            
            position.x = CGFloat(l.limit)
            position.y = 0.0
            position = position.applying(trans)
            
            _limitLineSegmentsBuffer[0].x = position.x
            _limitLineSegmentsBuffer[0].y = viewPortHandler.contentTop
            _limitLineSegmentsBuffer[1].x = position.x
            _limitLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
            
            context!.setStrokeColor(l.lineColor.cgColor)
            context!.setLineWidth(l.lineWidth)
            if (l.lineDashLengths != nil)
            {
                context!.setLineDash(phase: l.lineDashPhase, lengths: l.lineDashLengths!)
            }
            else
            {
                context?.setLineDash(phase: 0.0, lengths: [])
            }

            context!.strokeLineSegments(between: _limitLineSegmentsBuffer)
            
            let label = l.label
            
            // if drawing the limit-value label is enabled
            if (label.characters.count > 0)
            {
                let labelLineHeight = l.valueFont.lineHeight
                
                let add = _xAxis.aditionalLabelYOffset
                let xOffset: CGFloat = l.lineWidth
                let yOffset: CGFloat = add / 2.0
                
                if (l.labelPosition == .rightTop)
                {
                    ChartUtils.drawText(context,
                        text: label,
                        point: CGPoint(
                            x: position.x + xOffset,
                            y: viewPortHandler.contentTop + yOffset),
                        align: .left,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
                else if (l.labelPosition == .rightBottom)
                {
                    ChartUtils.drawText(context,
                        text: label,
                        point: CGPoint(
                            x: position.x + xOffset,
                            y: viewPortHandler.contentBottom - labelLineHeight - yOffset),
                        align: .left,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
                else if (l.labelPosition == .leftTop)
                {
                    ChartUtils.drawText(context,
                        text: label,
                        point: CGPoint(
                            x: position.x - xOffset,
                            y: viewPortHandler.contentTop + yOffset),
                        align: .right,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
                else
                {
                    ChartUtils.drawText(context,
                        text: label,
                        point: CGPoint(
                            x: position.x - xOffset,
                            y: viewPortHandler.contentBottom - labelLineHeight - yOffset),
                        align: .right,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
            }
        }
        
        context!.restoreGState()
    }
}
