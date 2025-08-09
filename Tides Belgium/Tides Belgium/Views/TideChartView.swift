//
//  TideChartView.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import SwiftUI
import Charts

struct TideChartView: View {
    let tideData: [TideData]
    let currentHeight: Double
    let selectedDate: Date
    @ObservedObject var tideService: TideService // Add TideService reference
    @Environment(\.localizationManager) private var localizationManager
    @State private var selectedDay: DaySelection = .today
    
    enum DaySelection: CaseIterable {
        case today, tomorrow
        
        var displayName: String {
            switch self {
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var chartData: [TideData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayAfter = calendar.date(byAdding: .day, value: 2, to: today)!
        
        return tideData.filter { tide in
            tide.time >= today && tide.time < dayAfter
        }.sorted { $0.time < $1.time }
    }
    
    private var chartTimeRange: (start: Date, end: Date) {
        guard let firstDataPoint = chartData.first?.time,
              let lastDataPoint = chartData.last?.time else {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            return (today, calendar.date(byAdding: .day, value: 2, to: today)!)
        }
        return (firstDataPoint, lastDataPoint)
    }
    
    private var todaysTideEvents: [TideData] {
        filterTideEvents(for: .today)
    }
    
    private var tomorrowsTideEvents: [TideData] {
        filterTideEvents(for: .tomorrow)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ChartHeaderView(currentHeight: currentHeight)
            
            TideContinuousChartView(
                chartData: chartData, 
                selectedDay: $selectedDay,
                todayEvents: todaysTideEvents,
                tomorrowEvents: tomorrowsTideEvents,
                chartTimeRange: chartTimeRange
            )
            
            DaySelectionToggle(selectedDay: $selectedDay, tideService: tideService)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tide chart for today and tomorrow")
    }
    
    // MARK: - Helper Methods
    
    private func filterTideEvents(for day: DaySelection) -> [TideData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = day == .today ? today : calendar.date(byAdding: .day, value: 1, to: today)!
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        return tideData.filter { tide in
            (tide.type == .high || tide.type == .low) &&
            tide.time >= startDate && 
            tide.time < endDate
        }.sorted { $0.time < $1.time }
    }
    
    private func L(_ key: String) -> String {
        localizationManager.localizedString(for: key)
    }
}

// MARK: - Subviews

private struct ChartHeaderView: View {
    let currentHeight: Double
    @Environment(\.localizationManager) private var localizationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("tide_chart_48h"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(currentHeight, specifier: "%.1f")m")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(L("current_level"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue.opacity(0.1))
                    .stroke(.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func L(_ key: String) -> String {
        localizationManager.localizedString(for: key)
    }
}

private struct TideContinuousChartView: View {
    let chartData: [TideData]
    @Binding var selectedDay: TideChartView.DaySelection
    let todayEvents: [TideData]
    let tomorrowEvents: [TideData]
    let chartTimeRange: (start: Date, end: Date)
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Constants
    private let chartHeight: CGFloat = 200
    private let lineWidth: CGFloat = 3
    private let symbolSize: CGFloat = 180
    
    // MARK: - Computed Properties
    
    private var yAxisRange: (min: Double, max: Double) {
        let minHeight = chartData.map { $0.height }.min() ?? 0.0
        let maxHeight = chartData.map { $0.height }.max() ?? 6.0
        return (
            min: min(minHeight - 0.2, 0.0),
            max: max(maxHeight + 0.2, 6.0)
        )
    }
    
    private var highlightedEvents: [TideData] {
        selectedDay == .today ? todayEvents : tomorrowEvents
    }
    
    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [
                .blue.opacity(colorScheme == .dark ? 0.4 : 0.3),
                .cyan.opacity(colorScheme == .dark ? 0.3 : 0.2),
                .blue.opacity(colorScheme == .dark ? 0.2 : 0.1),
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var lineGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .cyan, .blue],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            Chart {
                ForEach(chartData, id: \.time) { tide in
                    LineMark(
                        x: .value("Time", tide.time),
                        y: .value("Height", tide.height)
                    )
                    .foregroundStyle(lineGradient)
                    .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", tide.time),
                        yStart: .value("Min Height", yAxisRange.min),
                        yEnd: .value("Height", tide.height)
                    )
                    .foregroundStyle(areaGradient)
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(highlightedEvents, id: \.time) { tide in
                    PointMark(
                        x: .value("Time", tide.time),
                        y: .value("Height", tide.height)
                    )
                    .foregroundStyle(tide.type == .high ? Color.red : Color.blue)
                    .symbolSize(symbolSize)
                    .symbol(Circle())
                    .opacity(0.9)
                }
            }
            .chartBackground { proxy in
                CurrentTimeIndicator(proxy: proxy, chartTimeRange: chartTimeRange)
                DayDividerLine(proxy: proxy, chartTimeRange: chartTimeRange)
            }
            .frame(height: chartHeight)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.secondary.opacity(0.2))
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.secondary.opacity(0.6))
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 1.5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.secondary.opacity(0.2))
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.secondary.opacity(0.6))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .chartYScale(domain: yAxisRange.min...yAxisRange.max)
            .chartXScale(domain: chartTimeRange.start...chartTimeRange.end)
            .chartYAxisLabel("meters", position: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .stroke(.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

private struct CurrentTimeIndicator: View {
    let proxy: ChartProxy
    let chartTimeRange: (start: Date, end: Date)
    
    // MARK: - Constants
    private let indicatorWidth: CGFloat = 2
    private let labelOffset: CGFloat = 12
    
    private var currentTime: Date { Date() }
    
    private var isCurrentTimeVisible: Bool {
        currentTime >= chartTimeRange.start && currentTime <= chartTimeRange.end
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isCurrentTimeVisible,
               let plotFrame = proxy.plotFrame,
               let xPosition = proxy.position(forX: currentTime) {
                let frame = geometry[plotFrame]
                let clampedX = max(0, min(xPosition, frame.width))
                let indicatorX = frame.minX + clampedX
                
                // NOW indicator line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: indicatorWidth, height: frame.height)
                    .position(x: indicatorX, y: frame.midY)
                    .shadow(color: .orange, radius: 2)
                
                // "NOW" label
                Text("NOW")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.4), radius: 2)
                    )
                    .position(x: indicatorX, y: frame.minY - labelOffset)
            }
        }
    }
}

private struct DayDividerLine: View {
    let proxy: ChartProxy
    let chartTimeRange: (start: Date, end: Date)
    
    // MARK: - Constants
    private let lineWidth: CGFloat = 1
    private let labelSpacing: CGFloat = 60
    private let labelOffsetX: CGFloat = 35
    private let labelOffsetY: CGFloat = 15
    
    private var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
    }
    
    private var isTomorrowVisible: Bool {
        tomorrow >= chartTimeRange.start && tomorrow <= chartTimeRange.end
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isTomorrowVisible,
               let plotFrame = proxy.plotFrame,
               let xPosition = proxy.position(forX: tomorrow) {
                let frame = geometry[plotFrame]
                let clampedX = max(0, min(xPosition, frame.width))
                let dividerX = frame.minX + clampedX
                
                // Day divider line
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(width: lineWidth, height: frame.height)
                    .position(x: dividerX, y: frame.midY)
                
                // "TOMORROW" label
                if dividerX < frame.width - labelSpacing {
                    Text("TOMORROW")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.ultraThinMaterial)
                                .stroke(.secondary.opacity(0.2), lineWidth: 0.5)
                        )
                        .position(x: dividerX + labelOffsetX, y: frame.minY + labelOffsetY)
                }
            }
        }
    }
}

private struct DaySelectionToggle: View {
    @Binding var selectedDay: TideChartView.DaySelection
    @ObservedObject var tideService: TideService // Add TideService reference
    @Environment(\.localizationManager) private var localizationManager
    
    // MARK: - Constants
    private let buttonMinHeight: CGFloat = 44
    private let cornerRadius: CGFloat = 10
    private let containerCornerRadius: CGFloat = 13
    private let containerPadding: CGFloat = 3
    private let indicatorSize: CGFloat = 8
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TideChartView.DaySelection.allCases, id: \.self) { day in
                dayButton(for: day)
            }
        }
        .padding(containerPadding)
        .background(
            RoundedRectangle(cornerRadius: containerCornerRadius)
                .fill(.ultraThinMaterial)
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func dayButton(for day: TideChartView.DaySelection) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDay = day
                
                // Call the appropriate TideService method to update the filtered data
                if day == .today {
                    tideService.showToday()
                } else {
                    tideService.showTomorrow()
                }
            }
        }) {
            VStack(spacing: 4) {
                Text(dayLabel(for: day))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(selectedDay == day ? .white : .primary)
                
                HStack(spacing: 8) {
                    Text(dateLabel(for: day))
                        .font(.caption2)
                        .foregroundColor(selectedDay == day ? .white.opacity(0.8) : .secondary)
                    
                    tideIndicators
                }
            }
            .frame(maxWidth: .infinity, minHeight: buttonMinHeight)
            .background(buttonBackground(for: day))
        }
        .buttonStyle(.plain)
    }
    
    private var tideIndicators: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.red)
                .frame(width: indicatorSize, height: indicatorSize)
            Circle()
                .fill(.blue)
                .frame(width: indicatorSize, height: indicatorSize)
        }
    }
    
    private func buttonBackground(for day: TideChartView.DaySelection) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                selectedDay == day ?
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .stroke(
                selectedDay == day ? .clear : .secondary.opacity(0.3),
                lineWidth: 1
            )
            .shadow(
                color: selectedDay == day ? .blue.opacity(0.3) : .clear,
                radius: selectedDay == day ? 4 : 0
            )
    }
    
    // MARK: - Helper Methods
    
    private func dayLabel(for day: TideChartView.DaySelection) -> String {
        switch day {
        case .today:
            return L("today")
        case .tomorrow:
            return L("tomorrow")
        }
    }
    
    private func dateLabel(for day: TideChartView.DaySelection) -> String {
        let calendar = Calendar.current
        let date = day == .today ? Date() : calendar.date(byAdding: .day, value: 1, to: Date())!
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func L(_ key: String) -> String {
        localizationManager.localizedString(for: key)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    // Create sample tide data for today and tomorrow
    let sampleTides = [
        // Today's tides
        TideData(time: today.addingTimeInterval(2*3600), height: 2.5, type: .high),
        TideData(time: today.addingTimeInterval(6*3600), height: 1.2, type: .regular),
        TideData(time: today.addingTimeInterval(8*3600), height: 0.8, type: .low),
        TideData(time: today.addingTimeInterval(12*3600), height: 1.5, type: .regular),
        TideData(time: today.addingTimeInterval(14*3600), height: 2.8, type: .high),
        TideData(time: today.addingTimeInterval(18*3600), height: 1.8, type: .regular),
        TideData(time: today.addingTimeInterval(20*3600), height: 0.5, type: .low),
        TideData(time: today.addingTimeInterval(24*3600), height: 1.2, type: .regular),
        
        // Tomorrow's tides
        TideData(time: today.addingTimeInterval(26*3600), height: 2.6, type: .high),
        TideData(time: today.addingTimeInterval(30*3600), height: 1.5, type: .regular),
        TideData(time: today.addingTimeInterval(32*3600), height: 0.9, type: .low),
        TideData(time: today.addingTimeInterval(36*3600), height: 1.8, type: .regular),
        TideData(time: today.addingTimeInterval(38*3600), height: 2.7, type: .high),
        TideData(time: today.addingTimeInterval(42*3600), height: 1.6, type: .regular),
        TideData(time: today.addingTimeInterval(44*3600), height: 0.6, type: .low),
        TideData(time: today.addingTimeInterval(48*3600), height: 1.3, type: .regular)
    ]
    
    TideChartView(tideData: sampleTides, currentHeight: 1.8, selectedDate: Date())
        .environmentObject(LocalizationManager())
        .padding()
}
