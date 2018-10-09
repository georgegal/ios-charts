//
//  PieChartRenderer.swift
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

open class PieChartRenderer: ChartDataRendererBase
{
    internal weak var _chart: PieChartView!
    
    open var drawHoleEnabled = true
    open var holeTransparent = true
    open var holeColor: UIColor? = UIColor.white
    open var holeRadiusPercent = CGFloat(0.5)
    open var transparentCircleRadiusPercent = CGFloat(0.55)
    open var centerTextColor = UIColor.black
    open var centerTextFont = UIFont.systemFont(ofSize: 12.0)
    open var drawXLabelsEnabled = true
    open var usePercentValuesEnabled = false
    open var centerText: String!
    open var drawCenterTextEnabled = true
    open var centerTextLineBreakMode = NSLineBreakMode.byTruncatingTail
    open var centerTextRadiusPercent: CGFloat = 1.0
    
    public init(chart: PieChartView, animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        _chart = chart
    }
    
    open override func drawData(_ context: CGContext?)
    {
        if (_chart !== nil)
        {
            let pieData = _chart.data
            
            if (pieData != nil)
            {
                for set in pieData!.dataSets as! [PieChartDataSet]
                {
                    if set.isVisible && set.entryCount > 0
                    {
                        drawDataSet(context, dataSet: set)
                    }
                }
            }
        }
    }
    
    internal func drawDataSet(_ context: CGContext?, dataSet: PieChartDataSet)
    {
        var angle = _chart.rotationAngle
        
        var cnt = 0
        
        var entries = dataSet.yVals
        var drawAngles = _chart.drawAngles
        let circleBox = _chart.circleBox
        let radius = _chart.radius
        let innerRadius = drawHoleEnabled && holeTransparent ? radius * holeRadiusPercent : 0.0
        
        context!.saveGState()
        
        for j in 0 ..< entries.count
        {
            let newangle = drawAngles[cnt]
            let sliceSpace = dataSet.sliceSpace
            
            let e = entries[j]
            
            // draw only if the value is greater than zero
            if ((abs(e.value) > 0.000001))
            {
                if (!_chart.needsHighlight(e.xIndex,
                    dataSetIndex: _chart.data!.indexOfDataSet(dataSet)))
                {
                    let startAngle = angle + sliceSpace / 2.0
                    var sweepAngle = newangle * _animator.phaseY
                        - sliceSpace / 2.0
                    if (sweepAngle < 0.0)
                    {
                        sweepAngle = 0.0
                    }
                    let endAngle = startAngle + sweepAngle
                    
                    let path = CGMutablePath()
                    path.move(to: CGPoint(x: circleBox.midX, y: circleBox.midY))
                    path.addArc(center: CGPoint(x: circleBox.midX, y: circleBox.midY), radius: radius, startAngle: startAngle * ChartUtils.Math.FDEG2RAD, endAngle: endAngle * ChartUtils.Math.FDEG2RAD, clockwise: false)
                    path.closeSubpath()
                    
                    if (innerRadius > 0.0)
                    {
                        path.move(to: CGPoint(x: circleBox.midX, y: circleBox.midY))
                        path.addArc(center: CGPoint(x: circleBox.midX, y: circleBox.midY), radius: innerRadius, startAngle: startAngle * ChartUtils.Math.FDEG2RAD, endAngle: endAngle * ChartUtils.Math.FDEG2RAD, clockwise: false)
                        path.closeSubpath()
                    }
                    
                    context!.beginPath()
                    context!.addPath(path)
                    context!.setFillColor(dataSet.colorAt(j).cgColor)
                    context!.fillPath()
                }
            }
            
            angle += newangle * _animator.phaseX
            cnt += 1
        }
        
        context!.restoreGState()
    }
    
    open override func drawValues(_ context: CGContext?)
    {
        let center = _chart.centerCircleBox
        
        // get whole the radius
        var r = _chart.radius
        let rotationAngle = _chart.rotationAngle
        var drawAngles = _chart.drawAngles
        var absoluteAngles = _chart.absoluteAngles
        
        var off = r / 10.0 * 3.0
        
        if (drawHoleEnabled)
        {
            off = (r - (r * _chart.holeRadiusPercent)) / 2.0
        }
        
        r -= off; // offset to keep things inside the chart
        
        let data: ChartData! = _chart.data
        if (data === nil)
        {
            return
        }
        
        let defaultValueFormatter = _chart.valueFormatter
        
        var dataSets = data.dataSets
        let drawXVals = drawXLabelsEnabled
        
        var cnt = 0
        
        for i in 0 ..< dataSets.count
        {
            let dataSet = dataSets[i] as! PieChartDataSet
            
            let drawYVals = dataSet.isDrawValuesEnabled
            
            if (!drawYVals && !drawXVals)
            {
                continue
            }
            
            let valueFont = dataSet.valueFont
            let valueTextColor = dataSet.valueTextColor
            
            var formatter = dataSet.valueFormatter
            if (formatter === nil)
            {
                formatter = defaultValueFormatter
            }
            
            var entries = dataSet.yVals
            let maxEntry = Int(min(ceil(CGFloat(entries.count) * _animator.phaseX), CGFloat(entries.count)))
            for j in 0 ..< maxEntry
            {
                if (drawXVals && !drawYVals && (j >= data.xValCount || data.xVals[j] == nil))
                {
                    continue
                }
                
                // offset needed to center the drawn text in the slice
                let offset = drawAngles[cnt] / 2.0
                
                // calculate the text position
                let x = (r * cos(((rotationAngle + absoluteAngles[cnt] - offset) * _animator.phaseY) * ChartUtils.Math.FDEG2RAD) + center.x)
                var y = (r * sin(((rotationAngle + absoluteAngles[cnt] - offset) * _animator.phaseY) * ChartUtils.Math.FDEG2RAD) + center.y)
                
                let value = usePercentValuesEnabled ? entries[j].value / data.yValueSum * 100.0 : entries[j].value
                
                let val = formatter!.string(from: NSNumber(value:value))!
                
                let lineHeight = valueFont.lineHeight
                y -= lineHeight
                
                // draw everything, depending on settings
                if (drawXVals && drawYVals)
                {
                    ChartUtils.drawText(context, text: val, point: CGPoint(x: x, y: y), align: .center, attributes: [convertFromNSAttributedStringKey(NSAttributedString.Key.font): valueFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): valueTextColor])
                    
                    if (j < data.xValCount && data.xVals[j] != nil)
                    {
                        ChartUtils.drawText(context, text: data.xVals[j]!, point: CGPoint(x: x, y: y + lineHeight), align: .center, attributes: [convertFromNSAttributedStringKey(NSAttributedString.Key.font): valueFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): valueTextColor])
                    }
                }
                else if (drawXVals && !drawYVals)
                {
                    ChartUtils.drawText(context, text: data.xVals[j]!, point: CGPoint(x: x, y: y + lineHeight / 2.0), align: .center, attributes: [convertFromNSAttributedStringKey(NSAttributedString.Key.font): valueFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): valueTextColor])
                }
                else if (!drawXVals && drawYVals)
                {
                    ChartUtils.drawText(context, text: val, point: CGPoint(x: x, y: y + lineHeight / 2.0), align: .center, attributes: [convertFromNSAttributedStringKey(NSAttributedString.Key.font): valueFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): valueTextColor])
                }
                
                cnt += 1
            }
        }
    }
    
    open override func drawExtras(_ context: CGContext?)
    {
        drawHole(context)
        drawCenterText(context)
    }
    
    /// draws the hole in the center of the chart and the transparent circle / hole
    fileprivate func drawHole(_ context: CGContext?)
    {
        if (_chart.drawHoleEnabled)
        {
            context!.saveGState()
            
            let radius = _chart.radius
            let holeRadius = radius * holeRadiusPercent
            let center = _chart.centerCircleBox
            
            if (holeColor !== nil && holeColor != UIColor.clear)
            {
                // draw the hole-circle
                context!.setFillColor(holeColor!.cgColor)
                context!.fillEllipse(in: CGRect(x: center.x - holeRadius, y: center.y - holeRadius, width: holeRadius * 2.0, height: holeRadius * 2.0))
            }
            
            if (transparentCircleRadiusPercent > holeRadiusPercent)
            {
                let secondHoleRadius = radius * transparentCircleRadiusPercent
                
                // make transparent
                context!.setFillColor(holeColor!.withAlphaComponent(CGFloat(0x60) / CGFloat(0xFF)).cgColor)
                
                // draw the transparent-circle
                context!.fillEllipse(in: CGRect(x: center.x - secondHoleRadius, y: center.y - secondHoleRadius, width: secondHoleRadius * 2.0, height: secondHoleRadius * 2.0))
            }
            
            context!.restoreGState()
        }
    }
    
    /// draws the description text in the center of the pie chart makes most sense when center-hole is enabled
    fileprivate func drawCenterText(_ context: CGContext?)
    {
        if (drawCenterTextEnabled && centerText != nil && centerText.characters.count > 0)
        {
            let center = _chart.centerCircleBox
            let innerRadius = drawHoleEnabled && holeTransparent ? _chart.radius * holeRadiusPercent : _chart.radius
            let holeRect = CGRect(x: center.x - innerRadius, y: center.y - innerRadius, width: innerRadius * 2.0, height: innerRadius * 2.0)
            var boundingRect = holeRect
            
            if (centerTextRadiusPercent > 0.0)
            {
                boundingRect = boundingRect.insetBy(dx: (boundingRect.width - boundingRect.width * centerTextRadiusPercent) / 2.0, dy: (boundingRect.height - boundingRect.height * centerTextRadiusPercent) / 2.0)
            }
            
            let centerTextNs = self.centerText as NSString
            
            let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.lineBreakMode = centerTextLineBreakMode
            paragraphStyle.alignment = .center
            
            let drawingAttrs = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): centerTextFont, convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyle, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): centerTextColor] as [String : Any]
            
            let textBounds = centerTextNs.boundingRect(with: boundingRect.size, options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine], attributes: convertToOptionalNSAttributedStringKeyDictionary(drawingAttrs), context: nil)
            
            var drawingRect = boundingRect
            drawingRect.origin.x += (boundingRect.size.width - textBounds.size.width) / 2.0
            drawingRect.origin.y += (boundingRect.size.height - textBounds.size.height) / 2.0
            drawingRect.size = textBounds.size
            
            context!.saveGState()

            let clippingPath = CGPath(ellipseIn: holeRect, transform: nil)
            context!.beginPath()
            context!.addPath(clippingPath)
            context!.clip()
            
            centerTextNs.draw(with: drawingRect, options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine], attributes: convertToOptionalNSAttributedStringKeyDictionary(drawingAttrs), context: nil)
            
            context!.restoreGState()
        }
    }
    
    open override func drawHighlighted(_ context: CGContext?, indices: [ChartHighlight])
    {
        if (_chart.data === nil)
        {
            return
        }
        
        context!.saveGState()
        
        let rotationAngle = _chart.rotationAngle
        var angle = CGFloat(0.0)
        
        var drawAngles = _chart.drawAngles
        var absoluteAngles = _chart.absoluteAngles
        
        let innerRadius = drawHoleEnabled && holeTransparent ? _chart.radius * holeRadiusPercent : 0.0
        
        for i in 0 ..< indices.count
        {
            // get the index to highlight
            let xIndex = indices[i].xIndex
            if (xIndex >= drawAngles.count)
            {
                continue
            }
            
            let set = _chart.data?.getDataSetByIndex(indices[i].dataSetIndex) as! PieChartDataSet!
            
            if (set === nil || !(set?.isHighlightEnabled)!)
            {
                continue
            }
            
            if (xIndex == 0)
            {
                angle = rotationAngle
            }
            else
            {
                angle = rotationAngle + absoluteAngles[xIndex - 1]
            }
            
            angle *= _animator.phaseY
            
            let sliceDegrees = drawAngles[xIndex]
            
            let shift = set!.selectionShift
            let circleBox = _chart.circleBox
            
            let highlighted = CGRect(
                x: circleBox.origin.x - shift,
                y: circleBox.origin.y - shift,
                width: circleBox.size.width + shift * 2.0,
                height: circleBox.size.height + shift * 2.0)
            
            context!.setFillColor((set?.colorAt(xIndex).cgColor)!)
            
            // redefine the rect that contains the arc so that the highlighted pie is not cut off
            
            let startAngle = angle + (set?.sliceSpace)! / 2.0
            var sweepAngle = sliceDegrees * _animator.phaseY - (set?.sliceSpace)! / 2.0
            if (sweepAngle < 0.0)
            {
                sweepAngle = 0.0
            }
            let endAngle = startAngle + sweepAngle
            
            let path = CGMutablePath()
            path.move(to: CGPoint(x: highlighted.midX, y: highlighted.midY))
            path.addArc(center: CGPoint(x: highlighted.midX, y: highlighted.midY),
                        radius: highlighted.size.width / 2.0,
                        startAngle: startAngle * ChartUtils.Math.FDEG2RAD,
                        endAngle: endAngle * ChartUtils.Math.FDEG2RAD, clockwise: false)

            path.closeSubpath()
            
            if (innerRadius > 0.0)
            {
                path.move(to: CGPoint(x: highlighted.midX, y: highlighted.midY))
                path.addArc(center: CGPoint(x: highlighted.midX, y: highlighted.midY),
                            radius: innerRadius,
                            startAngle: startAngle * ChartUtils.Math.FDEG2RAD,
                            endAngle: endAngle * ChartUtils.Math.FDEG2RAD, clockwise: false)
                path.closeSubpath()
            }
            
            context!.beginPath()
            context!.addPath(path)
            context!.fillPath()
        }
        
        context!.restoreGState()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
