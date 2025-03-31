
// BORDER FUNCTIONS //

function draw_edge_border {
    parameter width is terminal:width.
    parameter height is terminal:height.
    parameter verchar is "|".
    parameter horchar is "-".

    vertical_line(0,height, 0, verchar).
    vertical_line(0,height,width, verchar).
    horizontal_line(0, width, 1, horchar).
    horizontal_line(0, width, height+2, horchar).
}

function horizontal_line{
    local parameter start.
    local parameter end.
    local parameter height.
    local parameter character is "-".
    for x in range(start, end){
        print character at (x, height).
    }
}

function vertical_line{
    local parameter start.
    local parameter end.
    local parameter xpos.
    local parameter character is "|".
    for y in range(start, end){
        print character at (xpos,y).
    }
}

// TEXT FORMATING FUNCTIONS
function center_text{
    parameter text.
    parameter height.

    local w is terminal:width.
    local strlen is text:length. 
    print text at ((w-strlen)/2,height).
}

// NUM TO STR 
// FORMAT NUM TO THIS MANY DIGITS
// FORMAT TXT <,>,^, 