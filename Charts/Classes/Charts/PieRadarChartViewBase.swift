//
//  PieRadarChartViewBase.swift
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

/// Base class of PieChartView and RadarChartView.
open class PieRadarChartViewBase: ChartViewBase
{
    /// holds the normalized version of the current rotation angle of the chart
    fileprivate var _rotationAngle = CGFloat(270.0)
    
    /// holds the raw version of the current rotation angle of the chart
    fileprivate var _rawRotationAngle = CGFloat(270.0)
    
    /// flag that indicates if rotation is enabled or not
    open var rotationEnabled = true
    
    /// Sets the minimum offset (padding) around the chart, defaults to 10
    open var minOffset = CGFloat(10.0)

    fileprivate var _rotationWithTwoFingers = false
    
    fileprivate var _tapGestureRecognizer: UITapGestureRecognizer!
    #if !os(tvOS)
    fileprivate var _rotationGestureRecognizer: UIRotationGestureRecognizer!
    #endif
    
    public override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    deinit
    {
        stopDeceleration()
    }
    
    internal override func initialize()
    {
        super.initialize()
        
        _tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PieRadarChartViewBase.tapGestureRecognized(_:)))
        
        self.addGestureRecognizer(_tapGestureRecognizer)

        #if !os(tvOS)
            _rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(PieRadarChartViewBase.rotationGestureRecognized(_:)))
            self.addGestureRecognizer(_rotationGestureRecognizer)
            _rotationGestureRecognizer.isEnabled = rotationWithTwoFingers
        #endif
    }
    
    internal override func calcMinMax()
    {
        _deltaX = CGFloat(_data.xVals.count - 1)
    }
    
    open override func notifyDataSetChanged()
    {
        if (_dataNotSet)
        {
            return
        }
        
        calcMinMax()
        
        if (_legend !== nil)
        {
            _legendRenderer.computeLegend(_data)
        }
        
        calculateOffsets()
        
        setNeedsDisplay()
    }
  
    internal override func calculateOffsets()
    {
        var legendLeft = CGFloat(0.0)
        var legendRight = CGFloat(0.0)
        var legendBottom = CGFloat(0.0)
        var legendTop = CGFloat(0.0)

        if (_legend != nil && _legend.enabled)
        {
            var fullLegendWidth = min(_legend.neededWidth, _viewPortHandler.chartWidth * _legend.maxSizePercent)
            fullLegendWidth += _legend.formSize + _legend.formToTextSpace
            
            if (_legend.position == .rightOfChartCenter)
            {
                // this is the space between the legend and the chart
                let spacing = CGFloat(13.0)

                legendRight = fullLegendWidth + spacing
            }
            else if (_legend.position == .rightOfChart)
            {
                // this is the space between the legend and the chart
                let spacing = CGFloat(8.0)
                
                let legendWidth = fullLegendWidth + spacing
                let legendHeight = _legend.neededHeight + _legend.textHeightMax

                let c = self.midPoint

                let bottomRight = CGPoint(x: self.bounds.width - legendWidth + 15.0, y: legendHeight + 15)
                let distLegend = distanceToCenter(bottomRight.x, y: bottomRight.y)

                let reference = getPosition(c, dist: self.radius,
                    angle: angleForPoint(bottomRight.x, y: bottomRight.y))

                let distReference = distanceToCenter(reference.x, y: reference.y)
                let minOffset = CGFloat(5.0)

                if (distLegend < distReference)
                {
                    let diff = distReference - distLegend
                    legendRight = minOffset + diff
                }

                if (bottomRight.y >= c.y && self.bounds.height - legendWidth > self.bounds.width)
                {
                    legendRight = legendWidth
                }
            }
            else if (_legend.position == .leftOfChartCenter)
            {
                // this is the space between the legend and the chart
                let spacing = CGFloat(13.0)

                legendLeft = fullLegendWidth + spacing
            }
            else if (_legend.position == .leftOfChart)
            {

                // this is the space between the legend and the chart
                let spacing = CGFloat(8.0)
                
                let legendWidth = fullLegendWidth + spacing
                let legendHeight = _legend.neededHeight + _legend.textHeightMax

                let c = self.midPoint

                let bottomLeft = CGPoint(x: legendWidth - 15.0, y: legendHeight + 15)
                let distLegend = distanceToCenter(bottomLeft.x, y: bottomLeft.y)

                let reference = getPosition(c, dist: self.radius,
                    angle: angleForPoint(bottomLeft.x, y: bottomLeft.y))

                let distReference = distanceToCenter(reference.x, y: reference.y)
                let min = CGFloat(5.0)

                if (distLegend < distReference)
                {
                    let diff = distReference - distLegend
                    legendLeft = min + diff
                }

                if (bottomLeft.y >= c.y && self.bounds.height - legendWidth > self.bounds.width)
                {
                    legendLeft = legendWidth
                }
            }
            else if (_legend.position == .belowChartLeft
                    || _legend.position == .belowChartRight
                    || _legend.position == .belowChartCenter)
            {
                // It's possible that we do not need this offset anymore as it
                //   is available through the extraOffsets, but changing it can mean
                //   changing default visibility for existing apps.
                let yOffset = self.requiredLegendOffset
                
                legendBottom = min(_legend.neededHeight + yOffset, _viewPortHandler.chartHeight * _legend.maxSizePercent)
            }
            else if (_legend.position == .aboveChartLeft
                || _legend.position == .aboveChartRight
                || _legend.position == .aboveChartCenter)
            {
                // It's possible that we do not need this offset anymore as it
                //   is available through the extraOffsets, but changing it can mean
                //   changing default visibility for existing apps.
                let yOffset = self.requiredLegendOffset
                
                legendTop = min(_legend.neededHeight + yOffset, _viewPortHandler.chartHeight * _legend.maxSizePercent)
            }

            legendLeft += self.requiredBaseOffset
            legendRight += self.requiredBaseOffset
            legendTop += self.requiredBaseOffset
        }
        
        legendTop += self.extraTopOffset
        legendRight += self.extraRightOffset
        legendBottom += self.extraBottomOffset
        legendLeft += self.extraLeftOffset
        
        var minOffset = self.minOffset
        
        if (self.isKind(of: RadarChartView.self))
        {
            let x = (self as! RadarChartView).xAxis
            
            if x.isEnabled && x.drawLabelsEnabled
            {
                minOffset = max(minOffset, x.labelWidth)
            }
        }

        let offsetLeft = max(minOffset, legendLeft)
        let offsetTop = max(minOffset, legendTop)
        let offsetRight = max(minOffset, legendRight)
        let offsetBottom = max(minOffset, max(self.requiredBaseOffset, legendBottom))

        _viewPortHandler.restrainViewPort(offsetLeft: offsetLeft, offsetTop: offsetTop, offsetRight: offsetRight, offsetBottom: offsetBottom)
    }

    /// - returns: the angle relative to the chart center for the given point on the chart in degrees.
    /// The angle is always between 0 and 360°, 0° is NORTH, 90° is EAST, ...
    open func angleForPoint(_ x: CGFloat, y: CGFloat) -> CGFloat
    {
        let c = centerOffsets
        
        let tx = Double(x - c.x)
        let ty = Double(y - c.y)
        let length = sqrt(tx * tx + ty * ty)
        let r = acos(ty / length)

        var angle = r * ChartUtils.Math.RAD2DEG

        if (x > c.x)
        {
            angle = 360.0 - angle
        }

        // add 90° because chart starts EAST
        angle = angle + 90.0

        // neutralize overflow
        if (angle > 360.0)
        {
            angle = angle - 360.0
        }

        return CGFloat(angle)
    }
    
    /// Calculates the position around a center point, depending on the distance
    /// from the center, and the angle of the position around the center.
    internal func getPosition(_ center: CGPoint, dist: CGFloat, angle: CGFloat) -> CGPoint
    {
        return CGPoint(x: center.x + dist * cos(angle * ChartUtils.Math.FDEG2RAD),
                y: center.y + dist * sin(angle * ChartUtils.Math.FDEG2RAD))
    }

    /// - returns: the distance of a certain point on the chart to the center of the chart.
    open func distanceToCenter(_ x: CGFloat, y: CGFloat) -> CGFloat
    {
        let c = self.centerOffsets

        var dist = CGFloat(0.0)

        var xDist = CGFloat(0.0)
        var yDist = CGFloat(0.0)

        if (x > c.x)
        {
            xDist = x - c.x
        }
        else
        {
            xDist = c.x - x
        }

        if (y > c.y)
        {
            yDist = y - c.y
        }
        else
        {
            yDist = c.y - y
        }

        // pythagoras
        dist = sqrt(pow(xDist, 2.0) + pow(yDist, 2.0))

        return dist
    }

    /// - returns: the xIndex for the given angle around the center of the chart.
    /// -1 if not found / outofbounds.
    open func indexForAngle(_ angle: CGFloat) -> Int
    {
        fatalError("indexForAngle() cannot be called on PieRadarChartViewBase")
    }

    /// current rotation angle of the pie chart
    ///
    /// **default**: 270 --> top (NORTH)
    /// - returns: will always return a normalized value, which will be between 0.0 < 360.0
    open var rotationAngle: CGFloat
    {
        get
        {
            return _rotationAngle
        }
        set
        {
            _rawRotationAngle = newValue
            _rotationAngle = ChartUtils.normalizedAngleFromAngle(newValue)
            setNeedsDisplay()
        }
    }
    
    /// gets the raw version of the current rotation angle of the pie chart the returned value could be any value, negative or positive, outside of the 360 degrees. 
    /// this is used when working with rotation direction, mainly by gestures and animations.
    open var rawRotationAngle: CGFloat
    {
        return _rawRotationAngle
    }

    /// - returns: the diameter of the pie- or radar-chart
    open var diameter: CGFloat
    {
        let content = _viewPortHandler.contentRect
        return min(content.width, content.height)
    }

    /// - returns: the radius of the chart in pixels.
    open var radius: CGFloat
    {
        fatalError("radius cannot be called on PieRadarChartViewBase")
    }

    /// - returns: the required offset for the chart legend.
    internal var requiredLegendOffset: CGFloat
    {
        fatalError("requiredLegendOffset cannot be called on PieRadarChartViewBase")
    }

    /// - returns: the base offset needed for the chart without calculating the
    /// legend size.
    internal var requiredBaseOffset: CGFloat
    {
        fatalError("requiredBaseOffset cannot be called on PieRadarChartViewBase")
    }
    
    open override var chartXMax: Double
    {
        return 0.0
    }
    
    open override var chartXMin: Double
    {
        getSelectionDetailsAtIndex(1);
        return 0.0
    }
    
    /// The SelectionDetail objects give information about the value at the selected index and the DataSet it belongs to.
    /// - returns: an array of SelectionDetail objects for the given x-index.
    open func getSelectionDetailsAtIndex(_ xIndex: Int) -> [ChartSelectionDetail]
    {
        var vals = [ChartSelectionDetail]()
        
        for i in 0 ..< _data.dataSetCount
        {
            let dataSet = _data.getDataSetByIndex(i)
            if (dataSet === nil || !(dataSet?.isHighlightEnabled)!)
            {
                continue
            }
            
            // extract all y-values from all DataSets at the given x-index
            let yVal = dataSet!.yValForXIndex(xIndex)
            if (yVal.isNaN)
            {
                continue
            }
            
            vals.append(ChartSelectionDetail(value: yVal, dataSetIndex: i, dataSet: dataSet!))
        }
        
        return vals
    }
    
    open var isRotationEnabled: Bool { return rotationEnabled; }
    
    /// flag that indicates if rotation is done with two fingers or one.
    /// when the chart is inside a scrollview, you need a two-finger rotation because a one-finger rotation eats up all touch events.
    /// 
    /// **default**: false
    open var rotationWithTwoFingers: Bool
    {
        get
        {
            return _rotationWithTwoFingers
        }
        set
        {
            _rotationWithTwoFingers = newValue
            #if !os(tvOS)
                _rotationGestureRecognizer.isEnabled = _rotationWithTwoFingers
            #endif
        }
    }
    
    /// flag that indicates if rotation is done with two fingers or one.
    /// when the chart is inside a scrollview, you need a two-finger rotation because a one-finger rotation eats up all touch events.
    ///
    /// **default**: false
    open var isRotationWithTwoFingers: Bool
    {
        return _rotationWithTwoFingers
    }
    
    // MARK: - Animation
    
    fileprivate var _spinAnimator: ChartAnimator!
    
    /// Applys a spin animation to the Chart.
    open func spin(_ duration: TimeInterval, fromAngle: CGFloat, toAngle: CGFloat, easing: ChartEasingFunctionBlock?)
    {
        if (_spinAnimator != nil)
        {
            _spinAnimator.stop()
        }
        
        _spinAnimator = ChartAnimator()
        _spinAnimator.updateBlock = {
            self.rotationAngle = (toAngle - fromAngle) * self._spinAnimator.phaseX + fromAngle
        }
        _spinAnimator.stopBlock = { self._spinAnimator = nil; }
        
        _spinAnimator.animate(xAxisDuration: duration, easing: easing)
    }
    
    open func spin(_ duration: TimeInterval, fromAngle: CGFloat, toAngle: CGFloat, easingOption: ChartEasingOption)
    {
        spin(duration, fromAngle: fromAngle, toAngle: toAngle, easing: easingFunctionFromOption(easingOption))
    }
    
    open func spin(_ duration: TimeInterval, fromAngle: CGFloat, toAngle: CGFloat)
    {
        spin(duration, fromAngle: fromAngle, toAngle: toAngle, easing: nil)
    }
    
    open func stopSpinAnimation()
    {
        if (_spinAnimator != nil)
        {
            _spinAnimator.stop()
        }
    }
    
    // MARK: - Gestures
    
    fileprivate var _touchStartPoint: CGPoint!
    fileprivate var _isRotating = false
    fileprivate var _defaultTouchEventsWereEnabled = false
    fileprivate var _startAngle = CGFloat(0.0)
    
    fileprivate struct AngularVelocitySample
    {
        var time: TimeInterval
        var angle: CGFloat
    }
    
    fileprivate var _velocitySamples = [AngularVelocitySample]()
    
    fileprivate var _decelerationLastTime: TimeInterval = 0.0
    fileprivate var _decelerationDisplayLink: CADisplayLink!
    fileprivate var _decelerationAngularVelocity: CGFloat = 0.0
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        // if rotation by touch is enabled
        if (rotationEnabled)
        {
            stopDeceleration()
            
            if (!rotationWithTwoFingers)
            {
                let touch = touches.first as UITouch!
                
                let touchLocation = touch?.location(in: self)
                
                self.resetVelocity()
                
                if (rotationEnabled)
                {
                    self.sampleVelocity(touchLocation!)
                }
                
                self.setGestureStartAngle((touchLocation?.x)!, y: (touchLocation?.y)!)
                
                _touchStartPoint = touchLocation
            }
        }
        
        if (!_isRotating)
        {
            super.touchesBegan(touches, with: event)
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if (rotationEnabled && !rotationWithTwoFingers)
        {
            let touch = touches.first as UITouch!
            
            let touchLocation = touch?.location(in: self)
            
            if (isDragDecelerationEnabled)
            {
                sampleVelocity(touchLocation!)
            }
            
            if (!_isRotating && distance((touchLocation?.x)!, startX: _touchStartPoint.x, eventY: (touchLocation?.y)!, startY: _touchStartPoint.y) > CGFloat(8.0))
            {
                _isRotating = true
            }
            else
            {
                self.updateGestureRotation((touchLocation?.x)!, y: (touchLocation?.y)!)
                setNeedsDisplay()
            }
        }
        
        if (!_isRotating)
        {
            super.touchesMoved(touches, with: event)
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if (!_isRotating)
        {
            super.touchesEnded(touches, with: event)
        }
        
        if (rotationEnabled && !rotationWithTwoFingers)
        {
            let touch = touches.first as UITouch!
            
            let touchLocation = touch?.location(in: self)
            
            if (isDragDecelerationEnabled)
            {
                stopDeceleration()
                
                sampleVelocity(touchLocation!)
                
                _decelerationAngularVelocity = calculateVelocity()
                
                if (_decelerationAngularVelocity != 0.0)
                {
                    _decelerationLastTime = CACurrentMediaTime()
                    _decelerationDisplayLink = CADisplayLink(target: self, selector: #selector(PieRadarChartViewBase.decelerationLoop))
                    _decelerationDisplayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
                }
            }
        }
        
        if (_isRotating)
        {
            _isRotating = false
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?)
    {
        super.touchesCancelled(touches!, with: event)
        
        if (_isRotating)
        {
            _isRotating = false
        }
    }
    
    fileprivate func resetVelocity()
    {
        _velocitySamples.removeAll(keepingCapacity: false)
    }
    
    fileprivate func sampleVelocity(_ touchLocation: CGPoint)
    {
        let currentTime = CACurrentMediaTime()
        
        _velocitySamples.append(AngularVelocitySample(time: currentTime, angle: angleForPoint(touchLocation.x, y: touchLocation.y)))
        
        // Remove samples older than our sample time - 1 seconds
        var count = _velocitySamples.count
        for var i in 0 ..< count - 2
        {
            if (currentTime - _velocitySamples[i].time > 1.0)
            {
                _velocitySamples.remove(at: 0)
                i -= 1
                count -= 1
            }
            else
            {
                break
            }
        }
    }
    
    fileprivate func calculateVelocity() -> CGFloat
    {
        if (_velocitySamples.isEmpty)
        {
            return 0.0
        }
        
        var firstSample = _velocitySamples[0]
        var lastSample = _velocitySamples[_velocitySamples.count - 1]
        
        // Look for a sample that's closest to the latest sample, but not the same, so we can deduce the direction
        var beforeLastSample = firstSample
        for i in stride(from: _velocitySamples.count, to:0, by: -1)
        {
            beforeLastSample = _velocitySamples[i]
            if (beforeLastSample.angle != lastSample.angle)
            {
                break
            }
        }
        
        // Calculate the sampling time
        var timeDelta = lastSample.time - firstSample.time
        if (timeDelta == 0.0)
        {
            timeDelta = 0.1
        }
        
        // Calculate clockwise/ccw by choosing two values that should be closest to each other,
        // so if the angles are two far from each other we know they are inverted "for sure"
        var clockwise = lastSample.angle >= beforeLastSample.angle
        if (abs(lastSample.angle - beforeLastSample.angle) > 270.0)
        {
            clockwise = !clockwise
        }
        
        // Now if the "gesture" is over a too big of an angle - then we know the angles are inverted, and we need to move them closer to each other from both sides of the 360.0 wrapping point
        if (lastSample.angle - firstSample.angle > 180.0)
        {
            firstSample.angle += 360.0
        }
        else if (firstSample.angle - lastSample.angle > 180.0)
        {
            lastSample.angle += 360.0
        }
        
        // The velocity
        var velocity = abs((lastSample.angle - firstSample.angle) / CGFloat(timeDelta))
        
        // Direction?
        if (!clockwise)
        {
            velocity = -velocity
        }
        
        return velocity
    }
    
    /// sets the starting angle of the rotation, this is only used by the touch listener, x and y is the touch position
    fileprivate func setGestureStartAngle(_ x: CGFloat, y: CGFloat)
    {
        _startAngle = angleForPoint(x, y: y)
        
        // take the current angle into consideration when starting a new drag
        _startAngle -= _rotationAngle
    }
    
    /// updates the view rotation depending on the given touch position, also takes the starting angle into consideration
    fileprivate func updateGestureRotation(_ x: CGFloat, y: CGFloat)
    {
        self.rotationAngle = angleForPoint(x, y: y) - _startAngle
    }
    
    open func stopDeceleration()
    {
        if (_decelerationDisplayLink !== nil)
        {
            _decelerationDisplayLink.remove(from: RunLoop.main, forMode: RunLoop.Mode.common)
            _decelerationDisplayLink = nil
        }
    }
    
    @objc fileprivate func decelerationLoop()
    {
        let currentTime = CACurrentMediaTime()
        
        _decelerationAngularVelocity *= self.dragDecelerationFrictionCoef
        
        let timeInterval = CGFloat(currentTime - _decelerationLastTime)
        
        self.rotationAngle += _decelerationAngularVelocity * timeInterval
        
        _decelerationLastTime = currentTime
        
        if(abs(_decelerationAngularVelocity) < 0.001)
        {
            stopDeceleration()
        }
    }
    
    /// - returns: the distance between two points
    fileprivate func distance(_ eventX: CGFloat, startX: CGFloat, eventY: CGFloat, startY: CGFloat) -> CGFloat
    {
        let dx = eventX - startX
        let dy = eventY - startY
        return sqrt(dx * dx + dy * dy)
    }
    
    /// - returns: the distance between two points
    fileprivate func distance(_ from: CGPoint, to: CGPoint) -> CGFloat
    {
        let dx = from.x - to.x
        let dy = from.y - to.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// reference to the last highlighted object
    fileprivate var _lastHighlight: ChartHighlight!
    
    @objc fileprivate func tapGestureRecognized(_ recognizer: UITapGestureRecognizer)
    {
        if (recognizer.state == UIGestureRecognizer.State.ended)
        {
            let location = recognizer.location(in: self)
            let distance = distanceToCenter(location.x, y: location.y)
            
            // check if a slice was touched
            if (distance > self.radius)
            {
                // if no slice was touched, highlight nothing
                let callDelegate = _lastHighlight != nil
                self.highlightValue(nil, callDelegate: callDelegate)
                _lastHighlight = nil
                _lastHighlight = nil
            }
            else
            {
                var angle = angleForPoint(location.x, y: location.y)
                
                if (self.isKind(of: PieChartView.self))
                {
                    angle /= _animator.phaseY
                }
                
                let index = indexForAngle(angle)
                
                // check if the index could be found
                if (index < 0)
                {
                    self.highlightValues(nil)
                    _lastHighlight = nil
                }
                else
                {
                    let valsAtIndex = getSelectionDetailsAtIndex(index)
                    
                    var dataSetIndex = 0
                    
                    // get the dataset that is closest to the selection (PieChart only has one DataSet)
                    if (self.isKind(of: RadarChartView.self))
                    {
                        dataSetIndex = ChartUtils.closestDataSetIndex(valsAtIndex, value: Double(distance / (self as! RadarChartView).factor), axis: nil)
                    }
                    
                    if (dataSetIndex < 0)
                    {
                        self.highlightValues(nil)
                        _lastHighlight = nil
                    }
                    else
                    {
                        let h = ChartHighlight(xIndex: index, dataSetIndex: dataSetIndex)
                        
                        if (_lastHighlight !== nil && h == _lastHighlight)
                        {
                            self.highlightValue(nil, callDelegate: true)
                            _lastHighlight = nil
                        }
                        else
                        {
                            self.highlightValue(h, callDelegate: true)
                            _lastHighlight = h
                        }
                    }
                }
            }
        }
    }
    
    #if !os(tvOS)
    @objc fileprivate func rotationGestureRecognized(_ recognizer: UIRotationGestureRecognizer)
    {
        if (recognizer.state == UIGestureRecognizer.State.began)
        {
            stopDeceleration()
            
            _startAngle = self.rawRotationAngle
        }
        
        if (recognizer.state == UIGestureRecognizer.State.began || recognizer.state == UIGestureRecognizer.State.changed)
        {
            let angle = ChartUtils.Math.FRAD2DEG * recognizer.rotation
            
            self.rotationAngle = _startAngle + angle
            setNeedsDisplay()
        }
        else if (recognizer.state == UIGestureRecognizer.State.ended)
        {
            let angle = ChartUtils.Math.FRAD2DEG * recognizer.rotation
            
            self.rotationAngle = _startAngle + angle
            setNeedsDisplay()
            
            if (isDragDecelerationEnabled)
            {
                stopDeceleration()
                
                _decelerationAngularVelocity = ChartUtils.Math.FRAD2DEG * recognizer.velocity
                
                if (_decelerationAngularVelocity != 0.0)
                {
                    _decelerationLastTime = CACurrentMediaTime()
                    _decelerationDisplayLink = CADisplayLink(target: self, selector: #selector(PieRadarChartViewBase.decelerationLoop))
                    _decelerationDisplayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
                }
            }
        }
    }
    #endif
}
