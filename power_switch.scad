//
// Scalable high-power switch.
//
// Todo:
//    - Detent ring for solid contact engagement.
// Bugs:
//    - throws = 1 doesn't work
//    - skip doesn't work right (at all?)
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
// Bearings:
//   tailcap - blind hole for radial and one-way thrust
//   headcap - through hole for radial
//   top carrier - one way thrust to keep spindle locked into body.

//$fn = 36;

// Animation : expand then contract
_ = $t;
$t = abs(.5 - $t) * 2;


// Constants
pi = 3.1415;
inches_to_mm = 25.4;
units = inches_to_mm;  // only apply to base variables, not derived!!!
recurse = true;

throws = 3 + round(2 * $t);
poles = 2;

// Blades - amperage
blade_thickness = 3/16 * units;
blade_width = 1/2 * units;
clamp_bolt_radius = blade_width / 4;

// Animation - scale the amperage
//blade_thickness = (1/32 + (1/4 - 1/32) * $t) * units;
//blade_width = (3/32 + (3/4 - 3/32) * $t) * units;

stud_radius = blade_width / 4;
connector_width = stud_radius * 4;
blade_clearance = 1/32 * units;

wall_thickness = blade_width * .2;  // how sturdy is the switch

// Spindle
spindle_radius = (blade_width/2) + 2 * clamp_bolt_radius + 2 * wall_thickness;
spindle_clearance = .4;

hub_radius = spindle_radius + wall_thickness;
hub_height = hub_radius / 2;
hub_clearance = 2;

// Body
connector_degrees = 360 / (throws * 2);  // degrees between connectors

// The connector circumference is what is needed to position the contactors with sufficient clearance.
connector_circ = (2 * 2 * throws * (connector_width + 2 * blade_clearance));
connector_radius = connector_circ / (2 * pi) + blade_width;
switch_radius = max(connector_radius, spindle_radius + blade_width + blade_clearance);


pole_height = stud_radius * 2 * 2 * 1.5; // radius->diameter, head is 2x body, clearance


// handle
handle_radius = spindle_radius * 2;
handle_height = handle_radius * 1;

// Animation : explode the assembly
min_exploded = 50;
exploded = min_exploded + 2 * pole_height * $t;

echo(blade_thickness=blade_thickness / units, blade_width=blade_width / units);
echo(cs_area=blade_width * blade_thickness, "mm^2");
echo(diameter=(switch_radius + wall_thickness) * 2 / units, degrees=connector_degrees * (throws - 1));
echo(stud_diameter=(stud_radius * 2) / units);


module bar(x, y, z) {
  linear_extrude(z) square([x, y]);
}

module body(height) {
    radius = switch_radius + wall_thickness;
    linear_extrude(height) circle(radius);

    // if the distance between every-other connector is small enough, skip every other bolt
    circ = 2 * pi * (switch_radius + wall_thickness);
    skip = (circ * (connector_degrees / 360) < 2 * units) ? 1 : 2;

    for (i=connectors()) {
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
        body(hub_clearance + hub_height);
        translate([0, 0, wall_thickness]) linear_extrude(hub_height + .1) circle(switch_radius);
    }
    linear_extrude(hub_height) circle(hub_radius);
  }
}

module headcap() {
    // Endcap with a through-hole in hub.
    difference() {
        endcap();
        translate([0, 0, -.1]) linear_extrude(hub_height * 2 + .2) circle(spindle_radius + spindle_clearance);
    }
}

module tailcap() {
    // Endcap with blind hole in hub to receive the end of the spindle.
    difference() {
        endcap();
        translate([0, 0, wall_thickness]) linear_extrude(hub_height * 2 + .2) circle(spindle_radius + spindle_clearance);
    }
}

module blade() {
  blade_radius = switch_radius - blade_clearance;
  intersection() { //trim to switch body
    color("goldenrod") translate([-blade_radius, -blade_width/2, -blade_thickness/2]) bar(blade_radius * 2, blade_width, blade_thickness);
    translate([0, 0, -.1]) linear_extrude(blade_thickness + .2) circle(switch_radius - blade_clearance);
  }
}


module spindle_block() {
  color("lightgrey") {
    difference () {
      linear_extrude(pole_height / 2) {
        difference() {
          circle(spindle_radius + wall_thickness);
         
          // bolt holes
          for (i=[90:180:360]) {
            rotate([0, 0, i]) translate([blade_width/2 + wall_thickness + clamp_bolt_radius, 0, 0]) circle(clamp_bolt_radius);
          }
        }
      }
    }
  }
}

module carrier() {
  // Holds the blades and provides bearing surfaces to locate the rotors in body (by extending beyond the spindle radius).
  height = pole_height / 2;
  translate([0, 0, height]) {
    color("darkgrey") difference() {
      spindle_block();
      blade(); // This should be a press fit, no clearance
    }
    if (recurse) {
      blade();
    }
  }
}

module rotor() {
  // carrier, and spindle block assembly
  rotate([0, 0, connector_degrees / 2 + $t * connector_degrees * (throws - 1)]) {
    carrier();
    spindle_block();
  }
}

function connectors() = [connector_degrees / 2: connector_degrees:360];  // evenly spaced around the periphery
function stops() = [0, 180];

module pole() {
  boss_radius = stud_radius * 3;
  boss_height = blade_thickness + stud_radius + wall_thickness;  // stud_radius is approximation of head height
  color("lightgrey") {
    difference() {
      union() {
        body(pole_height);
        for (i=connectors()) {
           rotate([0, 0, i]) translate([-(switch_radius + boss_height), 0, pole_height / 2]) rotate([0, 90, 0]) linear_extrude(2 * (switch_radius + boss_height)) circle(boss_radius);
        }
      }
      // core and blade guides
      difference() {
        translate([0, 0, -.1]) linear_extrude(pole_height + .2) circle(switch_radius);
        for(i=[1, -1]) {
          translate([0, 0, pole_height / 2 + blade_thickness * i]) rotate_extrude() translate([switch_radius, 0, 0]) circle(wall_thickness);
        }
      }
      for (i=connectors()) {
        // bolt hole
        rotate([0, 0, i]) translate([0, 0, pole_height / 2]) rotate([0, 90, 0]) linear_extrude(switch_radius + boss_height + .1) circle(stud_radius);
        // connector recess
        rotate([0, 0, i]) translate([0, 0, pole_height / 2]) rotate([0, 90, 0]) linear_extrude(switch_radius + stud_radius + blade_thickness) square(connector_width, center=true);
      }
    }
    // blade stops
    linear_extrude(pole_height)
    for (i=stops()) {
      rotate([0, 0, i]) translate([switch_radius - blade_width/2, 0, 0]) square([blade_width, blade_thickness], center=true);
    }
  }

  if (recurse) {
    for (i=connectors()) {
      rotate([0, 0, i]) translate([0, 0, pole_height / 2]) contactor();
      rotate([0, 0, 180 + i]) translate([0, 0, pole_height / 2]) contactor();
    }
    rotor();
  }
}

module switch() {
    // endcaps
    tailcap();
    translate([0, 0, poles * (pole_height + exploded) + exploded + 2 * (hub_clearance + hub_height)]) rotate([180, 0, 0]) headcap();
    
    // sparky bits
    for (z=[hub_height + hub_clearance + exploded:pole_height + exploded:hub_height + hub_clearance + exploded + (poles - 1) * (pole_height + exploded)]) {
      translate([0, 0, z]) pole();
    }
}

module contactor() {
  length = connector_width + blade_clearance;
  offset = switch_radius - blade_width;
  translate([offset, -length/2, blade_thickness / 2 / 2]) bar(blade_width, length, blade_thickness / 2);
  translate([offset, -length/2, -blade_thickness / 2 / 2 - blade_thickness / 2]) bar(blade_width, length, blade_thickness / 2);
}

//switch();
//tailcap();
//headcap();
//handle();
//blade();
//carrier();
//rotor();
//contactor();
//body();
pole();

