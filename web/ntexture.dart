import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:async';
import 'imageutil.dart';

class NTexture {
  html.ImageElement imageElement;
  gl.Texture texture;

  final int w;
  final int h;
  final double ratioHW;//width / height

  NTexture({this.ratioHW:1.0,this.w:4, this.h:4}) {
  }

  static Future<NTexture> newTexture(String path,{double ratioHW:1.0,int w:4, int h:4}) async {
    print("start load");
    NTexture tex = new NTexture(ratioHW:ratioHW,w:w,h:h);

    tex.imageElement = new html.ImageElement();
    Completer comp = new Completer();
    tex.imageElement.onLoad.listen((e) async {
      print("found ${tex.imageElement.width} ${tex.imageElement.height}");
      tex.imageElement = await ImageUtil.resizeImage(tex.imageElement, nextWidth: 512);
      comp.complete(tex);
    });
    tex.imageElement.onError.listen((e) {
      print("not found");
      comp.completeError(e);
    });
    tex.imageElement.src = path;
    tex.makeVertex();
    return comp.future;
  }

  create(gl.RenderingContext context) {
    this.texture = context.createTexture();
    context.bindTexture(gl.TEXTURE_2D, texture);
    context.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, this.imageElement);
    context.generateMipmap(gl.TEXTURE_2D);
  }

  int get widht => imageElement.clientWidth;

  int get height => imageElement.clientHeight;

  //
  //
  //
  Float32List get vertices => _vertices;
  Uint16List get indexs => _indexs;
  Float32List _vertices = [];
  Uint16List _indexs = [];

  makeEmptyVertices() {
    return new Float32List(vertices.length);
  }

  makeVertex() {
    var __vertices = (<double>[]);
    var __indexs = (<int>[]);

    double xsv = -0.5;
    double ysv = 0.5* ratioHW;
    double sv_w = 1.0/w;
    double sv_h = 1.0/h;

    double xst = 0.0;
    double yst = 0.0;
    double st_w = 1.0/w;
    double st_h = 1.0/h;

    for(int y = 0; y <= h; y++) {
      for (int x = 0; x <= w; x++) {
        __vertices.addAll(<double>[
          xsv + sv_w * x,
          ysv - sv_h * y * ratioHW,
          0.0, /**/1.0, 0.0, 0.0, 1.0, //
          xst + st_w * x,
          xst + st_h * y
        ]);
      }
    }

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        __indexs.addAll(<int>[
          (x + 0) + ((y + 0) * (w + 1)), (x + 1) + ((y + 0) * (w + 1)), (x + 0) + ((y + 1) * (w + 1)),
        ]);
//        indexs.addAll(<int>[
//          (x + 1) + ((y + 0) * (w + 1)), (x + 1) + ((y + 1) * (w + 1)), (x + 0) + ((y + 1) * (w + 1)),
//        ]);
      }
    }
    _vertices = new Float32List.fromList(__vertices);
    _indexs = new Uint16List.fromList(__indexs);

  }

}