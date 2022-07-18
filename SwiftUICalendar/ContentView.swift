//
//  ContentView.swift
//  SwiftUICalendar
//
//  Created by Solution888 on 7/18/22.
//

import SwiftUI

fileprivate extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}

struct WeekView<DateView>: View where DateView: View {
    @Environment(\.calendar) var calendar
    
    let week: Date
    let content: (Date) -> DateView
    
    init(week: Date, @ViewBuilder content: @escaping (Date) -> DateView) {
        self.week = week
        self.content = content
    }
    
    private var days: [Date] {
        guard
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: week)
        else { return [] }
        return calendar.generateDates(
            inside: weekInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                    HStack {
                        Spacer()
                        if self.calendar.isDate(self.week, equalTo: date, toGranularity: .month) {
                            self.content(date)
                        } else {
                            self.content(date).hidden()
                        }
                        Spacer()
                    }
                }
            }
            .padding([.leading, .trailing], 12)
            .padding([.top, .bottom], 16)
        }
        .background(Color.white)
    }
}

struct MonthView<DateView>: View where DateView: View {
    @Environment(\.calendar) var calendar
    
    @State private var month: Date
    let showHeader: Bool
    let content: (Date) -> DateView
    var onMonthChangeAction: ((Date) -> Void)?
    
    init(
        month: Date,
        showHeader: Bool = true,
        localizedWeekdays: [String] = [],
        @ViewBuilder content: @escaping (Date) -> DateView
    ) {
        self._month = State(initialValue: month)
        self.content = content
        self.showHeader = showHeader
    }
    
    private var weeks: [Date] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: month)
        else { return [] }
        return calendar.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0, weekday: calendar.firstWeekday)
        )
    }
    
    func changeDateBy(_ months: Int) {
        if let date = Calendar.current.date(byAdding: .month, value: months, to: month) {
            self.month = date
            onMonthChangeAction?(date)
        }
    }
    
    private var header: some View {
        HStack{
            HStack{
                Button(action: {
                    self.changeDateBy(-1)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image("Chevron_left")
                                    .renderingMode(.template)
                                    .imageScale(.large)
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                Text(String(format: "%d/%d", month.getYearFromDate(), month.getMonthFromDate()))
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    self.month = Date()
                    onMonthChangeAction?(self.month)
                }) {
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(Color.white)
                        .padding([.leading, .trailing], 6)
                        .padding([.top, .bottom], 8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    self.changeDateBy(1)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image("Chevron_right")
                                    .renderingMode(.template)
                                    .imageScale(.large)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .padding(16)
        }
    }
    
    @State private var offset = CGSize.zero
    
    var body: some View {
        VStack(spacing: 0) {
            if showHeader {
                header
            }
            HStack{
                ForEach(0..<7, id: \.self) {index in
                    Text("30")
                        .hidden()
                        .padding(8)
                        .clipShape(Circle())
                        .padding(.horizontal, 4)
                        .overlay(
                            Text(getWeekDaysSorted()[index])
                                .font(.footnote)
                                .foregroundColor(Color.gray)
                        )
                }
            }
            
            ForEach(weeks, id: \.self) { week in
                VStack(spacing: 0) {
                    WeekView(week: week, content: self.content)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                    print("offset: \(offset)")
                                }
                                .onEnded { _ in
                                    if offset.width > 100 {
                                        self.changeDateBy(-1)
                                    } else if offset.width < -100 {
                                        self.changeDateBy(1)
                                    } else {
                                        offset = .zero
                                    }
                                }
                        )
                    
                    if week != weeks.last {
                        Divider()
                    }
                }
            }
        }
    }
    
    func getWeekDaysSorted() -> [String]{
        let weekDays = ["Sun","Mon","Tue","Wed","Tur","Fri","Sat"]
        let sortedWeekDays = Array(weekDays[Calendar.current.firstWeekday - 1 ..< Calendar.current.shortWeekdaySymbols.count] + weekDays[0 ..< Calendar.current.firstWeekday - 1])
        return sortedWeekDays
    }
}

extension MonthView {
    func onMonthChange(action: @escaping ((Date) -> Void)) -> MonthView {
        var new = self
        new.onMonthChangeAction = action
        return new
    }
}

struct CalendarView<DateView>: View where DateView: View {
    @Environment(\.calendar) var calendar
    
    let interval: DateInterval
    let content: (Date) -> DateView
    var onMonthChangeAction: ((Date) -> Void)?
    
    init(interval: DateInterval, @ViewBuilder content: @escaping (Date) -> DateView) {
        self.interval = interval
        self.content = content
    }
    
    private var months: [Date] {
        calendar.generateDates(
            inside: interval,
            matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0)
        )
    }
    
    var body: some View {
        
        ForEach(months, id: \.self) { month in
            MonthView(month: month, content: self.content)
                .onMonthChange { date in
                    onMonthChangeAction?(date)
                }
        }
    }
}

extension CalendarView {
    func onMonthChange(action: @escaping ((Date) -> Void)) -> CalendarView {
        var new = self
        new.onMonthChangeAction = action
        return new
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.calendar) var calendar
        var year: DateInterval {
            calendar.dateInterval(of: .month, for: Date())!
        }
        
        return CalendarView(interval: year) { date in
            Text("00")
                .hidden()
                .padding(8)
                .background(Color.gray)
                .clipShape(Circle())
                .padding(4)
                .overlay(
                    Text(String(calendar.component(.day, from: date)))
                        .foregroundColor(Color.white)
                )
                .frame(width: 36, height: 36)
        }
    }
}

extension Date {
    func getYearFromDate() -> Int {
        return Calendar.current.component(.year, from: self)
    }
    
    func getMonthFromDate() -> Int {
        return Calendar.current.component(.month, from: self)
    }
}
