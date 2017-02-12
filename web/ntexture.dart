import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:async';
import 'imageutil.dart';

class NTexture {
  html.ImageElement imageElement;
  gl.Texture texture;

  static Future<NTexture> newTexture(String path) async {
    print("start load");
    NTexture tex = new NTexture();

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

}