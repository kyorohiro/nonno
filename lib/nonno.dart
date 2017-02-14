import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vec;


class Particles {
  final int w;
  final int h;
  List<Particle> ps = [];

  String toString() {
    return " ${ps}";
  }
  Particles(this.w, this.h) {
    ps = new List<Particle>((w + 2) * (h + 2));
    for (int y in [0, h+1]) {
      for (int x = 0; x < w+2; x++) {
        setParticle(x, y, new Particle(x * 10.0, y * 10.0, 10.0,fix: true));
      }
    }
    for (int x in [0, w+1]) {
      for (int y = 0; y < h+2; y++) {
        setParticle(x, y, new Particle(x * 10.0, y * 10.0, 10.0,fix: true));
      }
    }

    for (int y = 1; y < h+1; y++) {
      for (int x = 1; x < w+1 ; x++) {
        setParticle(x, y, new Particle(x * 10.0, y * 10.0, 10.0,fix: false));
      }
    }
  }

  void setParticle(int x, int y,Particle v) {
    ps[y * (w+2) + x] = v;
  }
  Particle getParticle(int x, int y) {
    return ps[y * (w+2) + x];
  }
  Particle get(int x, y) {
    return ps[y * (w+2) + x];
  }

  calcs() {
    for (int y = 1; y < h; y++) {
      for (int x = 1; x < w; x++) {
        calc(x, y);
      }
    }
  }
  move() {
    for (int y = 1; y < h; y++) {
      for (int x = 1; x < w; x++) {
        calc(x, y);
      }
    }
  }

  calc(int x, int y) {
    Particle m = get(x, y);
    m.calcs(<Particle>[
      get(x - 1, y),
    get(x + 1, y),
    get(x, y + 1),
    get(x, y - 1)
    ]);
  }
}

class Particle {
  vec.Vector3 p;
  vec.Vector3 a;
  double m;
  double k = 0.2;
  double r = 10.0;
  bool fix = false;

  String toString() {
    return ({"p":p, "a":a, "m":m, "k":k, "r": r, "fix":fix}).toString()+"\r\n";
  }

  Particle(double x, double y, this.m, {this.fix: false}) {
    p = new vec.Vector3(x, y, 0.0);
    a = new vec.Vector3(0.0,0.0,0.0);
  }

  move(double t){
    if(fix == false) {
      p.x += a.x * t;
      p.y += a.y * t;
      p.z += a.z * t;
    }
  }

  calcs(List<Particle> ps) {
    for (Particle p in ps) {
      vec.Vector3 l = this.calc(p);
      a = a.add(l);
    }
  }

  vec.Vector3 calc(Particle a) {
    double d = this.distance(a);
    double f = k * (d - r);
    double o = this.angle(a);
    return new vec.Vector3(f * math.cos(o), f * math.sin(o), 0.0);
  }

  double distance(Particle a) {
    return p.distanceTo(a.p);
  }

  double angle(Particle a) {
    return math.atan2(a.p.y - this.p.y, a.p.x - this.p.x);
  }

}
