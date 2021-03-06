//
// Scalable high-power switch.
//
// Todo:
//    - spindle bearings have a hard time sticking...
//    - Detent ring for solid contact engagement.
//    
// Bugs:
//    - throws = 1 doesn't work
//
// Vision - A central hub with stackable throws. Each throw consists of two parts, the rotating hub contactor that can be fixed to the shaft and an outer shell consisting of the connections for the poles.
// While this is essentially a stackable drum switch, it can be used for other types by only
// using one half of thhe end caps.
// The number of poles that can be acheived is dependent on the size of the blades. Either
// increase the switch length to lengthen the blade or decrease the blade width (and amperage!)
// to put the connectors more closely together.
//
// I want to be able to indicate the number of connections (poles and throws) as well as the conductor dimensions. Everything else should auto-scale for these.
//  - the spacing of blades at the periphery of the carrier must be > blade width to avoid shorts.
//
// Design details:
// heads are machined to a 'T' that is as wide as the blade and blade_width - 2 * blade_thickness in thickness...they can't rotate and are minimal sized.../


// Animation
animate_exploded = 0;
animate_rotation = 0;
animate_throws = 0;
animate_blade = 0;
_t = $t;
$t = (animate_exploded + animate_rotation + animate_throws + animate_blade) > 0 ? abs(.5 - $t) * 2 : 0;

// Constants
inches_to_mm = 25.4; //works best when multiple of layer height
units = inches_to_mm; // only apply to base variables, not derived!!!
recurse = true;
$fa = .1;
$fs = .3;

throws = 3 + round(2 * $t * animate_throws);
poles = 2;
handle_spindle_clearance = 3/16 * units; // how much clearance to give the handle (for panel mounting)


// Blades - amperage

blade_thickness = .050 * units;
blade_width = .15 * units;

//blade_thickness = (1/32 + animate_blade * ((1/32 + ((1/4 - 1/32) * $t * animate_blade)))) * units;
//blade_width = (1/16 + animate_blade * (3/32 + ((3/4 - 3/32) * $t * animate_blade))) * units;


bolt_size_intervals = 1/16 * units / 2;  // bolt sizes increase by this interval (/ 2 -> radius)
function bolt_size(nominal) = max(1, round(nominal / bolt_size_intervals)) * bolt_size_intervals;

clamp_bolt_radius = bolt_size(sqrt(blade_width));

blade_clearance = 1/32 * units;
stud_radius = bolt_size(sqrt(blade_width * blade_thickness / PI));  //same cross-sectional area as blade (for simplicity modeled as a square bolt)
connector_height = 5 * blade_thickness + 2 * blade_clearance; 

//***
clamp_bolt_radius = .175 / 2 * units;
stud_radius = .175 / 2 * units;
//***

wall_thickness = blade_thickness;

// Spindle
spindle_radius = (blade_width/2) + 2 * clamp_bolt_radius + 2 * wall_thickness;
spindle_clearance = .4;

hub_radius = spindle_radius + 2 * wall_thickness;
hub_height = spindle_radius / 2;
hub_clearance = 2;

// Body
connector_degrees = 360 / (throws * 2);  // degrees between connectors

// Position the connectors so there is sufficient clearance for the blades at the tips of the connectors.
_circumference = (2 * 2 * throws * (blade_width + blade_clearance)); // 2 for connectors and bolts, 2 for both sides
_radius = _circumference / (2 * PI);
switch_radius = max(_radius + blade_width, spindle_radius + blade_width + blade_clearance);

connector_radius = wall_thickness + sqrt(pow(blade_width/2 + blade_clearance, 2) + pow(connector_height/2, 2));

pole_height = connector_radius * 2 + wall_thickness;
carrier_height = (pole_height + blade_thickness) / 2;

// Animation : explode the assembly
min_exploded = 0;
exploded = min_exploded + poles * pole_height * $t * animate_exploded;

echo(blade_thickness=blade_thickness / units, blade_width=blade_width / units);//, blade_length=switch radius * 2 - blade_clearance);
echo(blade_cs=blade_width * blade_thickness, "mm^2", stud_cs=PI*stud_radius*stud_radius);
echo(switch_radius=switch_radius / units, wall_thickness=wall_thickness / units);
echo(connector_height=connector_height / units, connector_width=(blade_width + 2 * blade_clearance) / units);
echo(carrier_height=carrier_height / units);
echo(diameter=(switch_radius + wall_thickness) * 2 / units, degrees=connector_degrees * (throws - 1));
echo(stud_diameter=(stud_radius * 2) / units, bolt_diameter=(clamp_bolt_radius * 2) / units);
echo(pole_height=pole_height/units);


module bar(x, y, z) {
  linear_extrude(z) square([x, y]);
}

module body(height) {
    radius = switch_radius + wall_thickness;
    linear_extrude(height) circle(radius);

    // if the distance between every-other connector is small enough, skip every other bolt
    circ = 2 * PI * (switch_radius + wall_thickness);
    for (i=connectors((circ * (connector_degrees / 360) > (1.5 * units)) ? 1 : 2)) {
        rotate([0, 0, i - connector_degrees / 2]) translate([radius + clamp_bolt_radius, 0, 0]) linear_extrude(height) union() 
        {
            difference() {
                union() {
                    circle(clamp_bolt_radius * 2);
                    translate([-clamp_bolt_radius * 4, -clamp_bolt_radius * 2]) square(clamp_bolt_radius * 4, clamp_bolt_radius * 2);
                }
                circle(clamp_bolt_radius);
            }
        }
    }
}

module endcap() {
    // Body with a solid hub.

  color("lightgrey") {
    difference() {
        body(hub_height + wall_thickness + hub_clearance);
        translate([0, 0, wall_thickness]) cylinder(h=hub_height + hub_clearance + .1, r=switch_radius);
    }
    cylinder(r=hub_radius, h=hub_height);
    for(i=connectors()) {
      rotate([0, 0, i + connector_degrees/2]) translate([0, -wall_thickness/2, 0]) cube([switch_radius, wall_thickness, hub_height]);
    }
  }
}



module handle_body(height) {
      linear_extrude(height) {
        hull() {
          circle(spindle_radius + wall_thickness);
          translate([switch_radius * 1.5, 0, 0]) rotate([0, 0, 45]) square(blade_width, center=true);
          translate([- (switch_radius - blade_width), 0, 0]) circle(blade_width);
        }
      }
}


module handle(height=pole_height) {
  spindle_bearing(hub_height + hub_clearance + spindle_clearance + handle_spindle_clearance, flange=false);
  translate([0, 0, hub_height + hub_clearance + handle_spindle_clearance]) {
    difference() {
      handle_body(height);
      cylinder(r=spindle_radius, h=height + .1);
    }
    spindle_bearing(height, flange=false);
  }
}

module headcap() {
    // Endcap with a through-hole in hub and a spindle bearing
    difference() {
        translate([0, 0, hub_height + hub_clearance]) mirror([0, 0, 1]) endcap();
        translate([0, 0, -.1]) linear_extrude(hub_height * 2 + .2) circle(spindle_radius + spindle_clearance);
    }
    if (recurse) {
      translate([0, 0, exploded]) handle();
    }
}

module tailcap() {
    // Endcap with blind hole in hub to receive the end of the spindle.
    // TODO - this should be a blind hole, but that requires bolt bore holes
    difference() {
        endcap();
        translate([0, 0, -.1]) cylinder(h=hub_height * 2 + .2, r=spindle_radius + spindle_clearance);
    }
    if (recurse) {
      translate([0, 0, wall_thickness + exploded])
      spindle_bearing(hub_height + wall_thickness - spindle_clearance);
    }
}

module blade() {
  blade_radius = switch_radius - blade_clearance;
  rotate([0, 0, connector_degrees / 2 + (animate_rotation * $t * connector_degrees * (throws - 1))])
  intersection() { //trim to switch body
    color("goldenrod") translate([-blade_radius, -blade_width/2, 0]) bar(blade_radius * 2, blade_width, blade_thickness);
    translate([0, 0, -.1]) linear_extrude(blade_thickness + .2) circle(switch_radius - blade_clearance);
  }
}

module spindle_bearing(height=pole_height - carrier_height, flange=true) {
  rotate([0, 0, connector_degrees / 2 + (animate_rotation * $t * connector_degrees * (throws - 1))])
  color("lightgrey") {
    difference() {
      union() {
        cylinder(r=spindle_radius, h=height);
        if (flange) {
          // TODO - make this a radial bearing by r=switch_radius - spindle_clearance?
          translate([0, 0, height - wall_thickness]) cylinder(r=hub_radius, h=wall_thickness);
        }
      }
         
      // bolt holes
      for (i=[90:180:360]) {
        rotate([0, 0, i]) translate([blade_width/2 + wall_thickness + clamp_bolt_radius, 0, -.1]) cylinder(r=clamp_bolt_radius, h=height+.2);
      }
    }
  }
}

module carrier(height=carrier_height) {
  // Holds the blades and provides bearing surfaces to locate the rotors in body (by extending beyond the spindle radius).
  color("darkgrey") difference() {
    spindle_bearing(height, flange=false);
    translate([0, 0, height - blade_thickness + .1]) blade(); // This should be a press fit, no clearance
  }
  if (recurse) {
    translate([0, 0, height - blade_thickness]) blade();
    translate([0, 0, height]) spindle_bearing(pole_height - height);
  }
}

function connectors(skip=1) = [connector_degrees / 2: skip * connector_degrees:360];  // evenly spaced around the periphery
function stops() = [connector_degrees / 6, 180 - connector_degrees / 6,
                   360 - connector_degrees / 6, 180 + connector_degrees / 6];

module pole() {
  boss_height = blade_thickness + stud_radius + wall_thickness;  // stud_radius is approximation of head height
  color("lightgrey") {
    difference() {
      union() {
        body(pole_height);
        //connector bosses
        for (i=connectors()) {
           rotate([0, 0, i]) translate([-(switch_radius + boss_height), 0, pole_height / 2]) rotate([0, 90, 0]) linear_extrude(2 * (switch_radius + boss_height)) circle(connector_radius, center=true);
        }
      }
      // remove the core, but leave the blade guides
      difference() {
        translate([0, 0, -.1]) linear_extrude(pole_height + .2) circle(switch_radius);
        for(i=[1, -1]) {
          translate([0, 0, pole_height / 2 + 2 * wall_thickness * i]) rotate_extrude() translate([switch_radius, 0, 0]) circle(wall_thickness);
        }
      }
      for (i=connectors()) {
        // bolt hole
        rotate([0, 0, i]) translate([0, 0, pole_height / 2]) rotate([0, 90, 0]) linear_extrude(switch_radius + boss_height + .1) circle(stud_radius);
        // bolt head recess
        rotate([0, 0, i]) translate([0, 0, pole_height / 2]) rotate([0, 90, 0]) linear_extrude(switch_radius + stud_radius + blade_thickness) square([connector_height, blade_width + 2 * blade_clearance], center=true);
      }
    }
    // blade stops
    for (i=stops()) {
      rotate([0, 0, i]) translate([switch_radius, 0, pole_height / 2]) cube([wall_thickness*2, wall_thickness, wall_thickness * 3], center=true);
    }
  }

  if (recurse) {
    for (i=connectors()) {
      rotate([0, 0, i]) translate([0, 0, (pole_height - blade_thickness)/ 2]) contactor();
      rotate([0, 0, 180 + i]) translate([0, 0, (pole_height - blade_thickness)/ 2]) contactor();
    }
    carrier();
  }
}

module endcaps() {
  tailcap();
  translate([0, 0,poles * (pole_height + exploded) + (hub_clearance + hub_height)
                  + exploded]) headcap();
}

module switch() {
    // endcaps
    endcaps();
    
    // sparky bits
    for (z=[hub_height + hub_clearance + exploded:pole_height + exploded:hub_height + hub_clearance + exploded + (poles - 1) * (pole_height + exploded)]) {
      translate([0, 0, z]) pole();
    }
}

module contactor() {
  length = blade_width + blade_clearance;
  offset = switch_radius - blade_width;
  translate([offset, -length/2, blade_thickness / 2]) bar(blade_width, length, blade_thickness / 2);
  translate([offset, -length/2, -blade_thickness / 2]) bar(blade_width, length, blade_thickness / 2);
}

//switch();

//body();
//blade();
//contactor();
//endcap();
//endcaps();

// head and handle
//rotate([180, 0, 0]) handle();
//rotate([180, 0, 0]) headcap();

// Poles, repeat for each one
//rotate([180, 0, 0]) spindle_bearing();  // for the top of the stack
//carrier();
pole();

//tailcap bits
//rotate([180, 0, 0]) spindle_bearing(hub_height + wall_thickness - spindle_clearance);     // for the bottom of the stack
//tailcap();


