import Foundation
import CyberBlessingCheckSupport

var failures = 0
for check in CoreChecks.all {
    do { try check.run(); print("PASS \(check.name)") }
    catch { failures += 1; print("FAIL \(check.name): \(error)") }
}
print("\(CoreChecks.all.count - failures)/\(CoreChecks.all.count) checks passed")
exit(failures == 0 ? 0 : 1)
