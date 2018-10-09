//
//  BarChartDataSet.swift
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
public enum BarChartStrokeStyle: Int
{
    case solid
    case dashed
    case dotted
}

open class BarChartStakedIndex: NSObject, NSCopying
{
    @objc open var xIndex: Int = 0
    @objc open var stackIndex: Int = 0
    
    public override required init()
    {
        super.init()
    }
    
    public init(xIndex: Int, stackIndex: Int)
    {
        super.init()
        self.xIndex = xIndex
        self.stackIndex = stackIndex
    }
    
    // MARK: NSCopying
    
    open func copy(with zone: NSZone?) -> Any
    {
        let copy = type(of: self).init()
        
        copy.xIndex = xIndex
        copy.stackIndex = stackIndex
        
        return copy
    }
    
    // MARK: Hashable
    
    open override var hashValue: Int {
        return "\(self.xIndex), \(self.stackIndex)".hash
    }
    
    open override var hash: Int {
        return self.hashValue
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        return self.xIndex == (object as AnyObject).xIndex && self.stackIndex == (object as AnyObject).stackIndex
    }
}

public func ==(lhs: BarChartStakedIndex, rhs: BarChartStakedIndex) -> Bool {
    return lhs.xIndex == rhs.xIndex && lhs.stackIndex == rhs.stackIndex
}

open class BarChartStrokeOption: NSObject
{
    open var strokeColor: UIColor
    open var strokeStyle: BarChartStrokeStyle
    
    public init(strokeColor: UIColor, strokeStyle: BarChartStrokeStyle)
    {
        self.strokeColor = strokeColor
        self.strokeStyle = strokeStyle
    }
}

open class BarChartDataSet: BarLineScatterCandleBubbleChartDataSet
{
    /// space indicator between the bars in percentage of the whole width of one value (0.15 == 15% of bar width)
    open var barSpace: CGFloat = 0.15
    
    /// the maximum number of bars that are stacked upon each other, this value
    /// is calculated from the Entries that are added to the DataSet
    fileprivate var _stackSize = 1
    
    /// the color used for drawing the bar-shadows. The bar shadows is a surface behind the bar that indicates the maximum value
    open var barShadowColor = UIColor(red: 215.0/255.0, green: 215.0/255.0, blue: 215.0/255.0, alpha: 1.0)
    
    /// bars - stroke options
    open var strokeOptions = [BarChartStakedIndex : BarChartStrokeOption]()
    
    /// the alpha value (transparency) that is used for drawing the highlight indicator bar. min = 0.0 (fully transparent), max = 1.0 (fully opaque)
    open var highLightAlpha = CGFloat(120.0 / 255.0)
    
    /// the overall entry count, including counting each stack-value individually
    fileprivate var _entryCountStacks = 0
    
    /// array of labels used to describe the different values of the stacked bars
    open var stackLabels: [String] = ["Stack"]
    
    /// if true, on top of the bars will be displayed first value from the stack only (works with stacked data set)
    open var displayFirstValueOnly = false
    
    /// if true, zero values on x-axis will be displayed
    open var displayZeroValues = true
    
    public required init()
    {
        super.init()
    }
    
    public override init(yVals: [ChartDataEntry]?, label: String?)
    {
        super.init(yVals: yVals, label: label)
        
        self.highlightColor = UIColor.black
        
        self.calcStackSize(yVals as! [BarChartDataEntry]?)
        self.calcEntryCountIncludingStacks(yVals as! [BarChartDataEntry]?)
    }
    
    // MARK: NSCopying
    
    open override func copyWithZone(_ zone: NSZone?) -> AnyObject
    {
        let copy = super.copyWithZone(zone) as! BarChartDataSet
        copy.barSpace = barSpace
        copy._stackSize = _stackSize
        copy.barShadowColor = barShadowColor
        copy.highLightAlpha = highLightAlpha
        copy._entryCountStacks = _entryCountStacks
        copy.stackLabels = stackLabels
        return copy
    }
    
    /// Calculates the total number of entries this DataSet represents, including
    /// stacks. All values belonging to a stack are calculated separately.
    fileprivate func calcEntryCountIncludingStacks(_ yVals: [BarChartDataEntry]!)
    {
        _entryCountStacks = 0
        
        for i in 0 ..< yVals.count
        {
            let vals = yVals[i].values
            
            if (vals == nil)
            {
                _entryCountStacks += 1
            }
            else
            {
                _entryCountStacks += vals!.count
            }
        }
    }
    
    /// calculates the maximum stacksize that occurs in the Entries array of this DataSet
    fileprivate func calcStackSize(_ yVals: [BarChartDataEntry]!)
    {
        for i in 0 ..< yVals.count
        {
            if let vals = yVals[i].values
            {
                if vals.count > _stackSize
                {
                _stackSize = vals.count
            }
        }
    }
    }
    
    internal override func calcMinMax(_ start : Int, end: Int)
    {
        let yValCount = _yVals.count
        
        if yValCount == 0
        {
            return
        }
        
        var endValue : Int
        
        if end == 0 || end >= yValCount
        {
            endValue = yValCount - 1
        }
        else
        {
            endValue = end
        }
        
        _lastStart = start
        _lastEnd = endValue
        
        _yMin = Double.greatestFiniteMagnitude
        _yMax = -Double.greatestFiniteMagnitude
        
        for i in start ... endValue
        {
            if let e = _yVals[i] as? BarChartDataEntry
            {
                if !e.value.isNaN
                {
                    if e.values == nil
                    {
                        if e.value < _yMin
                        {
                            _yMin = e.value
                        }
                        
                        if e.value > _yMax
                        {
                            _yMax = e.value
                        }
                    }
                    else
                    {
                        if -e.negativeSum < _yMin
                        {
                            _yMin = -e.negativeSum
                        }
                        
                        if e.positiveSum > _yMax
                        {
                            _yMax = e.positiveSum
                        }
                    }
                }
            }
        }
        
        if (_yMin == Double.greatestFiniteMagnitude)
        {
            _yMin = 0.0
            _yMax = 0.0
        }
    }
    
    /// - returns: the maximum number of bars that can be stacked upon another in this DataSet.
    open var stackSize: Int
    {
        return _stackSize
    }
    
    /// - returns: true if this DataSet is stacked (stacksize > 1) or not.
    open var isStacked: Bool
    {
        return _stackSize > 1 ? true : false
    }
    
    /// - returns: the overall entry count, including counting each stack-value individually
    open var entryCountStacks: Int
    {
        return _entryCountStacks
    }
}
