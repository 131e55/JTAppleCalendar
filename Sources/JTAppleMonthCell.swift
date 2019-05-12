//
//  JTAppleDayCell.swift
//
//  Copyright (c) 2016-2017 JTAppleCalendar (https://github.com/patchthecode/JTAppleCalendar)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

open class JTAppleMonthCell: UIView {
    var daysInSection: [Int: Int] = [:] // temporary caching
    var sectionInset = UIEdgeInsets.zero
    var month: Month?
    var monthDate: Date?
    var configurationParameters: ConfigurationParameters?
    
    var yCellOffset:CGFloat = 0
    var xCellOffset:CGFloat = 0
    var xStride:CGFloat = 0
    

    var scrollDirection: UICollectionView.ScrollDirection = .horizontal
    
    func setupWith(configurationParameters: ConfigurationParameters, index: Int) {
        self.configurationParameters = configurationParameters
        
        let dateConfigurator = JTAppleDateConfigGenerator.shared
        
        let c = Calendar(identifier: .gregorian)
        guard let startEndDate = c.date(byAdding: .month, value: index, to: configurationParameters.startDate) else { assert(false, "Could not create date"); return }
        
        let internalConfigurationParameters = ConfigurationParameters(startDate: startEndDate,
                                                                      endDate: startEndDate,
                                                                      numberOfRows: configurationParameters.numberOfRows,
                                                                      calendar: configurationParameters.calendar,
                                                                      generateInDates: configurationParameters.generateInDates,
                                                                      generateOutDates: configurationParameters.generateOutDates,
                                                                      firstDayOfWeek: configurationParameters.firstDayOfWeek,
                                                                      hasStrictBoundaries: configurationParameters.hasStrictBoundaries)
        
        
        let dateInfo = dateConfigurator.setupMonthInfoDataForStartAndEndDate(internalConfigurationParameters)
        self.month = dateInfo.months.first
        self.monthDate = startEndDate
        
    }

    func sizeForitem(month: Month) -> (width: CGFloat, height: CGFloat) {
        let numberOfRowsForSection = month.maxNumberOfRowsForFull(developerSetRows: 6)
        let width = (frame.width - ((sectionInset.left / 7) + (sectionInset.right / 7))) / 7
        let height = (frame.height - sectionInset.top - sectionInset.bottom) / CGFloat(numberOfRowsForSection)
        return (width, height)
    }
    
    func numberOfDaysInSection(_ index: Int, monthInfo: [Month]) -> Int {
        if let days = daysInSection[index] {
            return days
        }
        let days = monthInfo[index].numberOfDaysInMonthGrid
        daysInSection[index] = days
        return days
    }
    
    func determineToApplyAttribs(month: Month)
        -> (xOffset: CGFloat, yOffset: CGFloat, width: CGFloat, height: CGFloat)? {
            let size = sizeForitem(month: month)
            let y = scrollDirection == .horizontal ? yCellOffset + sectionInset.top : yCellOffset
            return (xCellOffset + xStride, y, size.width, size.height)
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)

        UIGraphicsGetCurrentContext()
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        
        guard
            let month = month,
            let monthDate = monthDate else { return }
        
        let ff = DateFormatter()
        ff.dateFormat = "dd"
        
        for numberOfDaysInCurrentSection in month.sections {
            
            for dayCounter in 1...numberOfDaysInCurrentSection {
                guard let attribute = determineToApplyAttribs(month: month) else { continue }
            
                let rect = CGRect(x: attribute.xOffset, y: attribute.yOffset, width: attribute.width, height: attribute.height)
                
                let date = dateOwnerInfoFromPath(dayCounter - 1, month: month, startOfMonthCache: monthDate)
                
                drawTextFor(day: ff.string(from: date!), with: attribute.width, in: rect)
                
                xCellOffset += attribute.width
                
                if dayCounter == numberOfDaysInCurrentSection || dayCounter % maxNumberOfDaysInWeek == 0 {
                    // We are at the last item in the section
                    // && if we have headers
                    xCellOffset = sectionInset.left
                    yCellOffset += attribute.height
                }
            }
        }
        context.restoreGState()
    }
    
    func drawTextFor(day: String, with radius: CGFloat, in rect: CGRect) {
        
        let font = UIFont(name: "HelveticaNeue", size: fontSizeFor(radius: radius))!
        
        let dayText = day

        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        
        dayText.draw(in: rect, withAttributes: [
            NSAttributedString.Key.font : font,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ])

    }
    
    func fontSizeFor(radius: CGFloat) -> CGFloat {
        if radius >= 17.0 {
            return 11.0
        } else if radius >= 16.0 {
            return 10.0
        } else {
            return 8.0
        }
    }
    
    private func dateOwnerInfoFromPath(_ index: Int, month: Month, startOfMonthCache: Date) -> Date? { // Returns nil if date is out of scope
        let calendar = Calendar(identifier: .gregorian)
        // Calculate the offset
        let offSet = month.inDates
        let numberOfDaysToAddToOffset: Int = 0
        
        var dayIndex = 0
        
        let date: Date?
        if index >= offSet && index + numberOfDaysToAddToOffset < month.numberOfDaysInMonth + offSet {
            // This is a month date
            dayIndex = month.startDayIndex + index - offSet + numberOfDaysToAddToOffset
            date = calendar.date(byAdding: .day, value: dayIndex, to: startOfMonthCache)
        } else if index < offSet {
            // This is a preDate
            dayIndex = index - offSet + month.startDayIndex
            date = calendar.date(byAdding: .day, value: dayIndex, to: startOfMonthCache)
        } else {
            // This is a postDate
            dayIndex =  month.startDayIndex - offSet + index + numberOfDaysToAddToOffset
            date = calendar.date(byAdding: .day, value: dayIndex, to: startOfMonthCache)
        }
        guard let validDate = date else { return nil }
        return validDate
    }
}
