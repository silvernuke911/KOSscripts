// Function to draw a border with '-' (horizontal) and '|' (vertical)
function draw_edge_border {
    parameter width.
    parameter height.
    vertical_line(1,height, 1, "|").
    vertical_line(1,height,width, "|").
    horizontal_line(1, width, 1, "=").
    horizontal_line(1, width, height, "=").
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

function center_text{
    parameter text.
    parameter height.

    local w is terminal:width.
    local strlen is text:length. 
    print text at ((w-strlen)/2,height).
}

// Function to clear screen and redraw the border dynamically
function refresh_display {
    clearScreen.
    local w to terminal:width.
    local h to terminal:height.
    draw_edge_border(w, h).  // Call the border function
    horizontal_line(1,w,2).
    vertical_line(3,h-15,w/2).
    horizontal_line(1,w,h-16).
    center_text("TESTING BORDER CONTROL",1).
    return.
}

function get_resource{
    local parameter resource_name.
    local parameter craft_type is "ship".
    
    local craft_resources is ship:resources.
    if craft_type = "ship" {
        set craft_resources to ship:resources.
    }
    if craft_type = "stage" {
        set craft_resources to stage:resources.
    }
    for resource in craft_resources {
        if resource:name = resource_name {
            return resource.
        }
    }
}

set power_amount to get_resource("electriccharge"):amount.
set power_capacity to get_resource("electriccharge"):capacity.
set power_percent to 100*power_amount/power_capacity.

refresh_display().

print("POWER REMAINING : " + round(power_amount,1)) at (3,25).
print("POWER CAPACITY  : " + round(power_capacity,1)) at (3,26).
print("POWER PERCENT   : " + round(power_percent,1)) at (3,27).

wait 5.
clearScreen.
 

