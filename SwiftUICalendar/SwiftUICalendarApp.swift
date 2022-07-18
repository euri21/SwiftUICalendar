//
//  SwiftUICalendarApp.swift
//  SwiftUICalendar
//
//  Created by Solution888 on 7/18/22.
//

import SwiftUI

@main
struct SwiftUICalendarApp: App {
    @Environment(\.calendar) var calendar
    var year: DateInterval {
        calendar.dateInterval(of: .month, for: Date())!
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                CalendarView(interval: year) { date in
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
                Spacer()
            }
        }
    }
}
