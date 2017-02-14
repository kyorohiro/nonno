import 'package:test/test.dart' as unit;
import 'package:nonno/nonno.dart' as non;
import 'dart:math' as mat;

void main() {

  unit.test("basic a", () {
    non.Particles ps = new non.Particles(2,2);
    ps.getParticle(2,2).a.x += 10.0;
    print("A: ${ps}");
    ps.calcs();
    ps.move(1.0);
    print("B: ${ps}");
  });
  /*
  unit.test("basic a", () {
    non.Particle p1 = new non.Particle(10.0, 20.0, 10.0);
    non.Particle p2 = new non.Particle(0.0, 0.0, 10.0);
    unit.expect(p1.angle(p2) < -2.0, true);
    unit.expect(p2.angle(p1) < 1.2 && p2.angle(p1) > 0.0, true);
  });

  unit.test("basic a", () {
    non.Particle p1 = new non.Particle(10.0, 10.0, 10.0);
    non.Particle p2 = new non.Particle(0.0, 0.0, 10.0);
    unit.expect(p2.distance(p1) < 15.0 && p2.distance(p1) > 14.0, true);
  });
  */

}