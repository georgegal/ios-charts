//
//  ChartAxisRendererBase.swift
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
import UIKit

open class ChartAxisRendererBase: ChartRendererBase
{
    internal var transformer: ChartTransformer!
    
    public override init()
    {
        super.init()
    }
    
    public init(viewPortHandler: ChartViewPortHandler, transformer: ChartTransformer!)
    {
        super.init(viewPortHandler: viewPortHandler)
        
        self.transformer = transformer
    }
    
    /// Draws the axis labels on the specified context
    open func renderAxisLabels(_ context: CGContext?)
    {
        fatalError("renderAxisLabels() cannot be called on ChartAxisRendererBase")
    }
    
    /// Draws the grid lines belonging to the axis.
    open func renderGridLines(_ context: CGContext?)
    {
        fatalError("renderGridLines() cannot be called on ChartAxisRendererBase")
    }
    
    /// Draws the line that goes alongside the axis.
    open func renderAxisLine(_ context: CGContext?)
    {
        fatalError("renderAxisLine() cannot be called on ChartAxisRendererBase")
    }
    
    /// Draws the LimitLines associated with this axis to the screen.
    open func renderLimitLines(_ context: CGContext?)
    {
        fatalError("renderLimitLines() cannot be called on ChartAxisRendererBase")
    }
}
