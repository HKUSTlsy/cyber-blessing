import XCTest
import CyberBlessingCheckSupport

final class DivinationTests: XCTestCase {
    func testCoreRegressionChecks() {
        for check in CoreChecks.all {
            do { try check.run() }
            catch { XCTFail("\(check.name): \(error)") }
        }
    }
}
