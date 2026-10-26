
let now = Date(timeIntervalSince1970: 1800000000)
let base = "loop://meal-preview?v=1&grams=20&absorption_minutes=180&meal_time=1800000000"
var count = 0
func check(_ value: String, _ valid: Bool) {
    count += 1
    guard let url = URL(string: value) else {
        precondition(!valid); return
    }
    let result = MealPreview(url: url, now: now, minAbsorption: 1800, maxAbsorption: 28800)
    precondition((result != nil) == valid, "Unexpected result: \(value)")
}
check(base, true)
check(base.replacingOccurrences(of: "grams=20", with: "grams=20.5"), true)
for minutes in ["30", "480"] {
    check(base.replacingOccurrences(of: "minutes=180", with: "minutes=\(minutes)"), true)
}
for grams in ["0", "-1", "NaN", "inf", "1e999", "20g", "20,5", "", "%2020", "20%0A"] {
    check(base.replacingOccurrences(of: "grams=20", with: "grams=\(grams)"), false)
}
for minutes in ["0", "29", "481", "NaN", "3:00", "", "-30"] {
    check(base.replacingOccurrences(of: "minutes=180", with: "minutes=\(minutes)"), false)
}
for suffix in ["&grams=30", "&extra=1", "#fragment"] { check(base + suffix, false) }
check(base.replacingOccurrences(of: "&grams=20", with: ""), false)
check(base.replacingOccurrences(of: "&grams=20", with: "&v=1"), false)
check(base.replacingOccurrences(of: "v=1", with: "v=2"), false)
check(base.replacingOccurrences(of: "loop://", with: "https://"), false)
check(base.replacingOccurrences(of: "meal-preview?", with: "meal-preview/path?"), false)
check(base.replacingOccurrences(of: "meal-preview?", with: "user@meal-preview?"), false)
check(base.replacingOccurrences(of: "meal-preview?", with: "meal-preview:123?"), false)
check(base.replacingOccurrences(of: "1800000000", with: "1799999699"), false)
check(base.replacingOccurrences(of: "1800000000", with: "1800000061"), false)
check(base.replacingOccurrences(of: "1800000000", with: "NaN"), false)
let result = MealPreview(url: URL(string: base)!, now: now, minAbsorption: 1800, maxAbsorption: 28800)!
precondition(result.grams == 20 && result.absorptionTime == 10800 && result.date == now)
print("Passed \(count) parser cases plus exact grams, seconds, and timestamp assertions")
