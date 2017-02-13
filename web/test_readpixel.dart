import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:async';
import 'imageutil.dart';
import 'ntexture.dart';
import 'nprogram.dart';
import 'dart:math' as math;
import 'nonno.dart' as nonno;


main() async {
  // Create canvas and context
  html.CanvasElement canvas = html.document.createElement('canvas');
  html.document.body.children.add(canvas);
  gl.RenderingContext context = canvas.getContext3d();
  var ext;
  ext = context.getExtension('OES_texture_float');
  if(ext == null){
    throw new Exception("No support for OES_texture_float");
    return;
  }


  // Create texture
  var texture = context.createTexture();
  context.bindTexture(gl.TEXTURE_2D, texture);
  context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  context.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 32, 32, 0, gl.RGBA, gl.FLOAT, null);


  // Create and attach frame buffer
  var fbo = context.createFramebuffer();
  context.bindFramebuffer(gl.FRAMEBUFFER, fbo);
  context.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
  context.bindTexture(gl.TEXTURE_2D, null);
  if (context.checkFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE) {
    throw new Exception("gl.checkFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE");
  }
  context.clearColor(1.0, 1.0, 0.0, 1.0);
  context.clear(gl.COLOR_BUFFER_BIT);

  Float32List pixels = new Float32List(4 * 32 * 32);
  context.readPixels(0, 0, 32, 32, gl.RGBA, gl.FLOAT, pixels);
  print("==ZB=> ${pixels.buffer.asFloat32List()}");
}
