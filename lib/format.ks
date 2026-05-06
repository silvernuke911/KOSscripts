// ==========================
// FORMATTERS
// ==========================

function fmt_int {
    local parameter val.
    local parameter width.
    local parameter filler is " ".
    local parameter sign is false.

    local s is val:tostring.

    if sign {
        set width to width - 1.
        set s to abs(val):tostring.
        if val < 0 {
            set s to "-" + s.
        } else {
            set s to "+" + s.
        }
    }
    until s:length >= width {
        set s to filler + s.
    }
    return s.
}

function fmt_float {
    local parameter val.
    local parameter width.
    local parameter decimals is 1.
    local parameter filler is " ".
    local parameter sign is false.

    local rounded is round(val, decimals).
    local s is rounded:tostring.

    if sign {
        set width to width - 1.
        set s to abs(val):tostring.
        if val < 0 {
            set s to "-" + s.
        } else {
            set s to "+" + s.
        }
    }   

    // Ensure decimal point exists
    if not (s:find(".") >= 0) {
        set s to s + ".".
    }

    // Ensure correct decimal places
    local dotIndex is s:find(".").
    local currentDecimals is s:length - dotIndex - 1.

    until currentDecimals >= decimals {
        set s to s + "0".
        set currentDecimals to currentDecimals + 1.
    }

    // Pad left 
    until s:length >= width {
        set s to filler + s.
    }

    return s.
}


function fmt_fill {
    local parameter text.
    local parameter len.
    local parameter mode is ">".
    local parameter filler is " ".

    local function repeat {
        parameter char_, n.
        local out is "".
        from { local i is 0. } until i >= n step { set i to i + 1. } do {
            set out to out + char_.
        }
        return out.
    }

    local s is text.

    if s:length >= len {
        return s.
    }

    local diff is len - s:length.

    if mode = ">" {
        // pad LEFT
        return repeat(filler, diff) + s.
    }

    if mode = "<" {
        // pad RIGHT
        return s + repeat(filler, diff).
    }

    if mode = "^" {
        // CENTER
        local left is floor(diff / 2).
        local right is diff - left.
        return repeat(filler, left) + s + repeat(filler, right).
    }

    return s.
}

function fmt_time {
    local parameter t.
    local parameter mode is "hms".
    local parameter decimals is 0. 
    local parameter sep is ":".

    if decimals < 0 { set decimals to 0. }
    if decimals > 2 { set decimals to 2. }

    local s is t.

    local days is floor(s / 3600 * 6).
    set s to s - days * 3600 * 6.

    local hours is floor(s / 3600).
    set s to s - hours * 3600.

    local mins is floor(s / 60).
    set s to s - mins * 60.

    local secs is round(s, decimals).

    // ensure decimal formatting
    local secstr is secs:tostring.
    if decimals > 0 {
        if not (secstr:find(".") >= 0) {
            set secstr to secstr + ".".
        }
        local dot is secstr:find(".").
        local cur is secstr:length - dot - 1.
        until cur >= decimals {
            set secstr to secstr + "0".
            set cur to cur + 1.
        }
    }

    if sep = ":" {
        // CLOCK STYLE
        if mode = "dhms" {
            return days:tostring + ":" 
                + fmt_fill(hours:tostring,2,">","0") + ":" 
                + fmt_fill(mins:tostring,2,">","0") + ":" 
                + fmt_fill(secstr,2 + (decimals > 0)*(decimals+1),">","0").
        }

        if mode = "hms" {
            return hours:tostring + ":" 
                + fmt_fill(mins:tostring,2,">","0") + ":" 
                + fmt_fill(secstr,2 + (decimals > 0)*(decimals+1),">","0").
        }

        if mode = "ms" {
            return mins:tostring + ":" 
                + fmt_fill(secstr,2 + (decimals > 0)*(decimals+1),">","0").
        }

        return secstr.
    }

    // SYMBOL STYLE
    if mode = "dhms" {
        return days + "d" 
            + fmt_fill(hours:tostring,2,">","0") + "h"
            + fmt_fill(mins:tostring,2,">","0") + "m"
            + secstr + "s".
    }

    if mode = "hms" {
        return hours + "h"
            + fmt_fill(mins:tostring,2,">","0") + "m"
            + secstr + "s".
    }

    if mode = "ms" {
        return mins + "m"
            + secstr + "s".
    }

    return secstr + "s".
}


function fmt_sci {
    parameter val.
    parameter decimals.

    if val = 0 {
        return "0".
    }

    local sign is "".
    if val < 0 {
        set sign to "-".
        set val to abs(val).
    }

    local exp is 0.

    // normalize
    until val < 10 {
        set val to val / 10.
        set exp to exp + 1.
    }

    until val >= 1 {
        set val to val * 10.
        set exp to exp - 1.
    }

    local mant is round(val, decimals).
    local mstr is mant:tostring.

    // ensure decimals
    if decimals > 0 {
        if not (mstr:find(".") >= 0) {
            set mstr to mstr + ".".
        }
        local dot is mstr:find(".").
        local cur is mstr:length - dot - 1.
        until cur >= decimals {
            set mstr to mstr + "0".
            set cur to cur + 1.
        }
    }

    return sign + mstr + "x10^" + exp:tostring.
}