import Testing
@testable import Sub2APIMonitorApp

@Test
func countdownFormatterFormatsHoursAndMinutes() {
    #expect(CountdownFormatter.string(from: 4 * 3_600 + 30 * 60) == "4h 30m")
}

@Test
func countdownFormatterFormatsDaysAndHours() {
    #expect(CountdownFormatter.string(from: 4 * 86_400 + 18 * 3_600) == "4d 18h")
}

@Test
func countdownFormatterClampsExpiredIntervals() {
    #expect(CountdownFormatter.string(from: -1) == "即将重置")
}
