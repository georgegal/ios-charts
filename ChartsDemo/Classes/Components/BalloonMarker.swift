//
//  BalloonMarker.swift
//  ChartsDemo
//
//  Created by Daniel Cohen Gindi on 19/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import UIKit;
import Charts;

open class BalloonMarker: ChartMarker
{
    open var color: UIColor!;
    open var arrowSize = CGSize(width: 15, height: 11);
    open var font: UIFont!;
    open var insets = UIEdgeInsets();
    open var minimumSize = CGSize();
    
    fileprivate var labelns: NSString!;
    fileprivate var _labelSize: CGSize = CGSize();
    fileprivate var _size: CGSize = CGSize();
    fileprivate var _paragraphStyle: NSMutableParagraphStyle!;
    
    public init(color: UIColor, font: UIFont, insets: UIEdgeInsets)
    {
        super.init();
        
        self.color = color;
        self.font = font;
        self.insets = insets;
        
        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle;
        _paragraphStyle.alignment = .center;
    }
    
    open override var size: CGSize { return _size; }
    
    open override func draw(_ context: CGContext?, point: CGPoint)
    {
        if (labelns === nil)
        {
            return;
        }
        
        var rect = CGRect(origin: point, size: _size);
        rect.origin.x -= _size.width / 2.0;
        rect.origin.y -= _size.height;
        
        context?.saveGState();
        
        context?.setFillColor(color.cgColor);
        context?.beginPath();
        context?.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y));
        context?.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y));
        context?.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height - arrowSize.height));
        context?.addLine(to: CGPoint(x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0, y: rect.origin.y + rect.size.height - arrowSize.height));
        context?.addLine(to: CGPoint(x: rect.origin.x + rect.size.width / 2.0, y: rect.origin.y + rect.size.height));
        context?.addLine(to: CGPoint(x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0, y: rect.origin.y + rect.size.height - arrowSize.height));
        context?.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height - arrowSize.height));
        context?.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y));
        context?.fillPath();
        
        rect.origin.y += self.insets.top;
        rect.size.height -= self.insets.top + self.insets.bottom;
        
        UIGraphicsPushContext(context);
        
        labelns.draw(in: rect, withAttributes: [NSFontAttributeName: self.font, NSParagraphStyleAttributeName: _paragraphStyle]);
        
        UIGraphicsPopContext();
        
        context?.restoreGState();
    }
    
    open override func refreshContent(entry: ChartDataEntry, highlight: ChartHighlight)
    {
        let label = entry.value.description;
        labelns = label as NSString;
        
        _labelSize = labelns.size(attributes: [NSFontAttributeName: self.font]);
        _size.width = _labelSize.width + self.insets.left + self.insets.right;
        _size.height = _labelSize.height + self.insets.top + self.insets.bottom;
        _size.width = max(minimumSize.width, _size.width);
        _size.height = max(minimumSize.height, _size.height);
    }
}
