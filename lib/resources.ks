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
    // allowable suffixes
    // :amount 
    // :density
    // :capacity
    // :parts
}