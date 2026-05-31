// Fuzzy subsequence matcher (fzf-style). score(query, text) returns a number
// (higher = better) when every query character appears in text in order, or
// null when it does not. The score may be negative for sparse matches, so
// callers test against null, not a sign. Matching is case-insensitive. Greedy
// earliest-match, so a
// subsequence is always found when one exists; bonuses bias the score toward
// matches that land on word boundaries and run consecutively, which for pass
// entries means path segments like "github" in "web/github.com/me" rank high.
.pragma library

var BONUS_BOUNDARY = 16;    // match right after a separator (/ - _ . space)
var BONUS_CAMEL = 12;       // lowercase -> Uppercase transition
var BONUS_CONSECUTIVE = 8;  // directly follows the previous matched char
var BONUS_FIRST = 8;        // match at index 0
var PENALTY_GAP = 1;        // per char skipped between two matches

function isBoundary(ch) {
    return ch === "/" || ch === "-" || ch === "_" || ch === "." || ch === " ";
}

function isUpper(ch) {
    return ch !== ch.toLowerCase() && ch === ch.toUpperCase();
}

function score(query, text) {
    if (query.length === 0) return 0;
    var q = query.toLowerCase();
    var lower = text.toLowerCase();
    var qi = 0;
    var total = 0;
    var prevMatch = -2;
    for (var ti = 0; ti < text.length && qi < q.length; ++ti) {
        if (lower[ti] !== q[qi]) continue;
        var s = 1;
        if (ti === 0) {
            s += BONUS_FIRST;
        } else {
            var prev = text[ti - 1];
            if (isBoundary(prev)) s += BONUS_BOUNDARY;
            else if (!isUpper(prev) && isUpper(text[ti])) s += BONUS_CAMEL;
        }
        if (ti === prevMatch + 1) s += BONUS_CONSECUTIVE;
        else if (prevMatch >= 0) s -= (ti - prevMatch - 1) * PENALTY_GAP;
        total += s;
        prevMatch = ti;
        ++qi;
    }
    if (qi < q.length) return null;
    // Tiebreaker: prefer shorter strings so exact-ish entries float up.
    return total - text.length * 0.01;
}
