//
// Scalable high-power switch.
//
// Todo:
//    - Detent ring for solid contact engagement.
//    - make the blades simple bars that are fully recessed into the rotor by flat bottom, segemented integral spindle (no splines or clearances), make rotors diamond shaped rather than full rings.
//    - terminology
//    - missalign bolts and studs
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

$fa = 2;
$fs = 0.1;

// This hacks $t to run it forward and backwards to get an expanding/contracting view.
_ = $t;
$t = abs(.5 - $t) * 2;

inches_to_mm = 25.4;
units = inches_to_mm;  // only apply to base variables, not derived!!!

throws = 3;
poles = 2;

// Blades - amperage
blade_thickness = 3/16 * units;
blade_width = 3/8 * units;

//blade_thickness = 3/16 * units * $t;
//blade_width = 1/2 * units * $t;

blade_clearance = 1/32 * units;

// Body
num_bolts = 4;
clamp_bolt_radius = 1/4 / 2 * units;

// The switch is large enough to allow the contactors sufficient space that the blade doesn't contact more than one at a time.
connector_degrees = 360/num_bolts; //the throws are arranged between bolts (arbitrarily)

// the connector circumference is what is needed to position the contactors with sufficient clearance
connector_circ = (2 * throws * (blade_width + blade_clearance) - blade_width) / (connector_degrees / 360);
connector_radius = connector_circ / (2 * 3.14);
switch_radius = connector_radius + blade_width;
switch_diameter = switch_radius * 2;
wall_thickness = switch_radius * .1;

// rotor
stud_radius = 3/8 / 2* units; // radius of the contactor studs
stator_height = stud_radius * 5;
carrier_radius = switch_radius - blade_width - blade_clearance;

// Spindle
spindle_radius = carrier_radius * .4;
num_splines = 6;
spindle_clearance = .4;

hub_diameter = spindle_radius * 2 * 2;
hub_height = hub_diameter * .5;
hub_clearance = 2;

// handle
handle_radius = spindle_radius * 2;
handle_height = handle_radius * 1;


exploded = 2 * stator_height * $t;

module bar(x, y, z) {
  linear_extrude(z) square([x, y]);
}

module body(height) {
    radius = switch_radius + wall_thickness;
    
    linear_extrude(height) circle(radius);
    for (i = [0:360/num_bolts:360]) {
         rotate([0, 0, i]) translate([radius + clamp_bolt_radius, 0, 0]) linear_extrude(height) union() 
        {
            difference() {
                union() {
                    circle(clamp_bolt_radius);
                    translate([-clamp_bolt_radius * 2, -clamp_bolt_radius]) square(clamp_bolt_radius * 2, clamp_bolt_radius);
                }
                circle(clamp_bolt_radius / 2);
            }
        }
    }
}

module spindle(length, through_hole_radius=3, clearance=0) {
    // Splined spindle with through hole for screwing handle on to.
  color("lightgrey") {
    radius = spindle_radius + clearance;
    spline_width = (2 * spindle_radius * 3.1415) / (num_splines * 2) - clearance;
    linear_extrude(length) difference() {
        circle(radius);
        for (i = [0:360/num_splines:360]) {
            rotate([0, 0, i]) translate([spindle_radius - spline_width / 2, - spline_width / 2 ,0 ]) square(spline_width);
        }
        circle(through_hole_radius);
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
    linear_extrude(hub_height) circle(hub_diameter / 2);
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

module carrier(height, radius=carrier_radius) {
  difference() {
    linear_extrude(height) circle(radius);
    translate([0, 0, -.1]) spindle(handle_height + .2, 0, spindle_clearance);
  }
}

module handle() {
  carrier(handle_radius * .75, handle_radius);
}
    
module stator(height) {
  // Input_contactor is the ring that the contactors are bolted to.
  // connector_arc_angle is the degrees through which the connectors are arranged

  color("lightgrey") {
    difference() {
      body(height);
      translate([0, 0, -.1]) linear_extrude(height + .2) circle(switch_radius);
      for (i=[0:connector_degrees/(throws-1):connector_degrees]) {
        translate([0, 0, height / 2]) rotate([0, 90, i]) linear_extrude(switch_radius + wall_thickness + .1) circle(stud_radius);
      }
    }
  }

  for (i=[0:connector_degrees/(throws-1):360/num_bolts]) {
    rotate([0, 0, i]) translate([0, 0, height / 2]) contactor();
  }
}

module blade() {
  offset = spindle_radius + wall_thickness;
  blade_radius = switch_radius - blade_clearance;
  length = blade_radius - offset;
  intersection() { //trim to switch body
    color("goldenrod") {
      translate([0, 0, -blade_thickness/2]) carrier(blade_thickness, spindle_radius + blade_width / 2);
      for (i=[0, 180]) {  // where do you want the connector tabs on the blade?
        rotate([0, 0, i]) translate([offset, -blade_width/2, -blade_thickness/2]) bar(length, blade_width, blade_thickness);
      }

      difference() {
        translate([0, 0, -blade_thickness/2]) carrier(blade_thickness, blade_radius);
        translate([0, 0, -switch_radius]) rotate([0, 0, 180 + (360 / num_bolts) / 2]) rotate_extrude(angle=360 - 360/num_bolts) translate([0, 0, switch_radius + .1]) square(switch_diameter);
      }
    }
    translate([0, 0, -blade_thickness/2 -.1]) linear_extrude(blade_thickness + .2) circle(switch_radius - blade_clearance);
  }
}


module _rotor(height) {
    // Holds the rotating contactors, 2 identical pieces hold the contactors.
    color("darkgrey")
    difference() {
      carrier(height);
      blade();
    }
}

module rotor() {
  // comprised of 2 mirror pieces, one top, one bottom that clamp the contactors.
  _height = stator_height / 2;
  rotate([0, 0, $t * connector_degrees]) translate([0, 0, _height]) {
    rotate([180, 0, 0]) _rotor(_height);
    _rotor(_height);
    blade();
  }
}

module switch() {
    // endcaps
    tailcap();
    translate([0, 0, poles * (stator_height + exploded) + exploded + 2 * (hub_clearance + hub_height)]) rotate([180, 0, 0]) headcap();
    
    //spindle
    translate([0, 0, wall_thickness + $t * (poles * stator_height)]) spindle((hub_height + hub_clearance) * 2 //2 endcaps
                                               + poles * stator_height      //contactors
                                               - wall_thickness                //tailcap wall thickness
                                               + handle_height);
    translate([0, 0, poles * (stator_height + exploded)
                     + 2 * (hub_clearance + hub_height + exploded)]) handle();
    
    // sparky bits
    for (z=[hub_height + hub_clearance + exploded:stator_height + exploded:hub_height + hub_clearance + exploded + (poles - 1) * (stator_height + exploded)]) {
      translate([0, 0, z]) stator(stator_height);
      translate([0, 0, z]) rotor(stator_height);
    }
}

module contactor() {
  length = blade_width * 1.2;
  offset = switch_radius - blade_width;
  translate([offset, -length/2, blade_thickness / 2 / 2]) bar(blade_width, length, blade_thickness / 2);
  translate([offset, -length/2, -blade_thickness / 2 / 2 - blade_thickness / 2]) bar(blade_width, length, blade_thickness / 2);
}

switch();
//spindle();
//tailcap();
//headcap();
//handle();
//blade();
//_rotor(5);
//rotor();
//contactor();
//stator(stator_height);

