function getMonthDays(month, year) {
    return new Date(year, month + 1, 0).getDate();
}

function getCalendarLayout(dateObject, highlightToday) {
    var year = dateObject.getFullYear();
    var month = dateObject.getMonth();
    var today = new Date();
    var todayDate = today.getDate();
    var todayMonth = today.getMonth();
    var todayYear = today.getFullYear();

    var firstDay = new Date(year, month, 1).getDay();
    // Shift to Monday-start: 0=Mon, 1=Tue, ..., 6=Sun
    firstDay = (firstDay + 6) % 7;

    var daysInMonth = getMonthDays(month, year);
    var daysInPrevMonth = getMonthDays((month + 11) % 12, month === 0 ? year - 1 : year);

    var weeks = [];
    var dayCounter = 1;
    var nextMonthDay = 1;

    for (var w = 0; w < 6; w++) {
        var week = [];
        for (var d = 0; d < 7; d++) {
            var cellIndex = w * 7 + d;
            if (cellIndex < firstDay) {
                // Previous month
                week.push({
                    day: daysInPrevMonth - firstDay + cellIndex + 1,
                    today: -1
                });
            } else if (dayCounter <= daysInMonth) {
                var isToday = highlightToday && dayCounter === todayDate
                    && month === todayMonth && year === todayYear;
                week.push({
                    day: dayCounter,
                    today: isToday ? 1 : 0
                });
                dayCounter++;
            } else {
                // Next month
                week.push({
                    day: nextMonthDay,
                    today: -1
                });
                nextMonthDay++;
            }
        }
        weeks.push(week);
    }
    return weeks;
}

function getDateInXMonthsTime(monthShift) {
    var now = new Date();
    return new Date(now.getFullYear(), now.getMonth() + monthShift, 1);
}

var weekDays = [
    { day: "Mo" }, { day: "Tu" }, { day: "We" },
    { day: "Th" }, { day: "Fr" }, { day: "Sa" }, { day: "Su" }
];
