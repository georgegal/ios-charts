//
//  RadarChartRenderer.swift
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

open class RadarChartRenderer: LineScatterCandleRadarChartRenderer
{
    internal weak var _chart: RadarChartView!

    public init(chart: RadarChartView, animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        _chart = chart
    }
    
    open override func drawData(_ context: CGContext?)
    {
        if (_chart !== nil)
        {
            let radarData = _chart.data
            
            if (radarData != nil)
            {
                for set in radarData!.dataSets as! [RadarChartDataSet]
                {
                    if set.isVisible && set.entryCount > 0
                    {
                        drawDataSet(context, dataSet: set)
                    }
                }
            }
        }
    }
    
    internal func drawDataSet(_ context: CGContext?, dataSet: RadarChartDataSet)
    {
        context!.saveGState()
        
        let sliceangle = _chart.sliceAngle
        
        // calculate the factor that is needed for transforming the value to pixels
        let factor = _chart.factor
        
        let center = _chart.centerOffsets
        var entries = dataSet.yVals
        let path = CGMutablePath()
        var hasMovedToPoint = false
        
        for j in 0 ..< entries.count
        {
            let e = entries[j]
            
            let p = ChartUtils.getPosition(center, dist: CGFloat(e.value - _chart.chartYMin) * factor, angle: sliceangle * CGFloat(j) + _chart.rotationAngle)
            
            if (p.x.isNaN)
            {
                continue
            }
            
            if (!hasMovedToPoint)
            {
                path.move(to: p)
                hasMovedToPoint = true
            }
            else
            {
                path.addLine(to: p)
            }
        }
        
        path.closeSubpath()
        
        // draw filled
        if (dataSet.isDrawFilledEnabled)
        {
            context!.setFillColor(dataSet.colorAt(0).cgColor)
            context!.setAlpha(dataSet.fillAlpha)
            
            context!.beginPath()
            context!.addPath(path)
            context!.fillPath()
        }
        
        // draw the line (only if filled is disabled or alpha is below 255)
        if (!dataSet.isDrawFilledEnabled || dataSet.fillAlpha < 1.0)
        {
            context!.setStrokeColor(dataSet.colorAt(0).cgColor)
            context!.setLineWidth(dataSet.lineWidth)
            context!.setAlpha(1.0)
            
            context!.beginPath()
            context!.addPath(path)
            context!.strokePath()
        }
        
        context!.restoreGState()
    }
    
    open override func drawValues(_ context: CGContext?)
    {
        if (_chart.data === nil)
        {
            return
        }
        
        let data = _chart.data!
        
        let defaultValueFormatter = _chart.valueFormatter
        
        let sliceangle = _chart.sliceAngle
        
        // calculate the factor that is needed for transforming the value to pixels
        let factor = _chart.factor
        
        let center = _chart.centerOffsets
        
        let yoffset = CGFloat(5.0)
        
        let count = data.dataSetCount
        for i in 0 ..< count
        {
            let dataSet = data.getDataSetByIndex(i) as! RadarChartDataSet
            
            if !dataSet.isDrawValuesEnabled || dataSet.entryCount == 0
            {
                continue
            }
            
            var entries = dataSet.yVals
            
            for j in 0 ..< entries.count
            {
                let e = entries[j]
                
                let p = ChartUtils.getPosition(center, dist: CGFloat(e.value) * factor, angle: sliceangle * CGFloat(j) + _chart.rotationAngle)
                
                let valueFont = dataSet.valueFont
                let valueTextColor = dataSet.valueTextColor
                
                var formatter = dataSet.valueFormatter
                if (formatter === nil)
                {
                    formatter = defaultValueFormatter
                }
                
                ChartUtils.drawText(context, text: formatter!.string(from: NSNumber(value: e.value))!, point: CGPoint(x: p.x, y: p.y - yoffset - valueFont.lineHeight), align: .center, attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: valueTextColor])
            }
        }
    }
    
    open override func drawExtras(_ context: CGContext?)
    {
        drawWeb(context)
    }
    
    fileprivate var _webLineSegmentsBuffer = [CGPoint](repeating: CGPoint(), count: 2)
    
    internal func drawWeb(_ context: CGContext?)
    {
        let sliceangle = _chart.sliceAngle
        
        context!.saveGState()
        
        // calculate the factor that is needed for transforming the value to
        // pixels
        let factor = _chart.factor
        let rotationangle = _chart.rotationAngle
        
        let center = _chart.centerOffsets
        
        // draw the web lines that come from the center
        context!.setLineWidth(_chart.webLineWidth)
        context!.setStrokeColor(_chart.webColor.cgColor)
        context!.setAlpha(_chart.webAlpha)
        
        let xIncrements = 1 + _chart.skipWebLineCount
        let xValCount = _chart.data!.xValCount
        
        for i in stride(from: 0, to: xValCount, by: xIncrements)
        {
            let p = ChartUtils.getPosition(center, dist: CGFloat(_chart.yRange) * factor, angle: sliceangle * CGFloat(i) + rotationangle)
            
            _webLineSegmentsBuffer[0].x = center.x
            _webLineSegmentsBuffer[0].y = center.y
            _webLineSegmentsBuffer[1].x = p.x
            _webLineSegmentsBuffer[1].y = p.y
            context!.strokeLineSegments(between: _webLineSegmentsBuffer)
        }
        
        // draw the inner-web
        context!.setLineWidth(_chart.innerWebLineWidth)
        context!.setStrokeColor(_chart.innerWebColor.cgColor)
        context!.setAlpha(_chart.webAlpha)
        
        let labelCount = _chart.yAxis.entryCount
        
        for j in 0 ..< labelCount
        {
            let xValCount = _chart.data!.xValCount
            for i in 0 ..< xValCount
            {
                let r = CGFloat(_chart.yAxis.entries[j] - _chart.chartYMin) * factor

                let p1 = ChartUtils.getPosition(center, dist: r, angle: sliceangle * CGFloat(i) + rotationangle)
                let p2 = ChartUtils.getPosition(center, dist: r, angle: sliceangle * CGFloat(i + 1) + rotationangle)
                
                _webLineSegmentsBuffer[0].x = p1.x
                _webLineSegmentsBuffer[0].y = p1.y
                _webLineSegmentsBuffer[1].x = p2.x
                _webLineSegmentsBuffer[1].y = p2.y
                context!.strokeLineSegments(between: _webLineSegmentsBuffer)
            }
        }
        
        context!.restoreGState()
    }
    
    fileprivate var _highlightPointBuffer = CGPoint()

    open override func drawHighlighted(_ context: CGContext?, indices: [ChartHighlight])
    {
        if (_chart.data === nil)
        {
            return
        }
        
        let data = _chart.data as! RadarChartData
        
        context!.saveGState()
        context!.setLineWidth(data.highlightLineWidth)
        if (data.highlightLineDashLengths != nil)
        {
            context!.setLineDash(phase: data.highlightLineDashPhase, lengths: data.highlightLineDashLengths!)
        }
        else
        {
            context!.setLineDash(phase: 0.0, lengths: [])
        }
        
        let sliceangle = _chart.sliceAngle
        let factor = _chart.factor
        
        let center = _chart.centerOffsets
        
        for i in 0 ..< indices.count
        {
            let set = _chart.data?.getDataSetByIndex(indices[i].dataSetIndex) as! RadarChartDataSet!
            
            if (set === nil || !(set?.isHighlightEnabled)!)
            {
                continue
            }
            
            context!.setStrokeColor((set?.highlightColor.cgColor)!)
            
            // get the index to highlight
            let xIndex = indices[i].xIndex
            
            let e = set?.entryForXIndex(xIndex)
            if (e === nil || e!.xIndex != xIndex)
            {
                continue
            }
            
            let j = set?.entryIndex(entry: e!, isEqual: true)
            let y = (e!.value - _chart.chartYMin)
            
            if (y.isNaN)
            {
                continue
            }
            
            _highlightPointBuffer = ChartUtils.getPosition(center, dist: CGFloat(y) * factor,
                angle: sliceangle * CGFloat(j!) + _chart.rotationAngle)
            
            // draw the lines
            drawHighlightLines(context, point: _highlightPointBuffer, set: set!)
        }
        
        context!.restoreGState()
    }
}
