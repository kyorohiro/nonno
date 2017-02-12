import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:async';
import 'imageutil.dart';
import 'ntexture.dart';
import 'nprogram.dart';
import 'dart:math' as math;

main() async {
  Nonno nonno = await Nonno.newNonno("assets/ic.jpg");
  html.document.body.append(nonno.element);
  await nonno.init();
  for(int i=0;i<30;i++) {
    await nonno.anime();
    await new Future.delayed(new Duration(milliseconds: 500));
  }
}


class Nonno {
  final int width;
  final int height;
  final int cellSize;
  html.CanvasElement _canvas;
  final String texturePath;

  Nonno._private(this.texturePath, {this.width: 600, this.height: 400, this.cellSize: 20}) {
    _canvas = new html.CanvasElement(width: this.width, height: this.height);
  }

  static Future<Nonno> newNonno(String texturePath, {int width: 600, int height: 400, int cellSize: 20}) async {
    Nonno ret = new Nonno._private(texturePath,width:width,height:height,cellSize: cellSize);
    await ret.init();
    return ret;
  }

  gl.RenderingContext context;


  gl.Buffer vertexBuffer;
  gl.Buffer indexBuffer;
  NProgram nprogram;
  NTexture nTexture;
  init() async {
    double ratioHW = width / height;
    context = _canvas.getContext3d();
    context.viewport(0, 0, this.width, this.height);

    nprogram = new NProgram();
    nprogram.compile(context);

    //
    nTexture = await NTexture.newTexture(texturePath,ratioHW:ratioHW,h: 10,w:10);
    await nTexture.create(context);
    //
    //

    final vSize = 3;
    final cSize = 4;
    final tSize = 2;
    final strideSize = (9) * Float32List.BYTES_PER_ELEMENT;
    final colorOffset = (3) * Float32List.BYTES_PER_ELEMENT;
    final texOffset = (7) * Float32List.BYTES_PER_ELEMENT;

    vertexBuffer = context.createBuffer();
    indexBuffer = context.createBuffer();

    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.enableVertexAttribArray(nprogram.vertexPositionLocation);
    context.enableVertexAttribArray(nprogram.colorLocation);
    context.enableVertexAttribArray(nprogram.texCoordLocation);
    context.vertexAttribPointer(nprogram.vertexPositionLocation, vSize, gl.FLOAT, false, strideSize, 0);
    context.vertexAttribPointer(nprogram.colorLocation, cSize, gl.FLOAT, false, strideSize, colorOffset);
    context.vertexAttribPointer(nprogram.texCoordLocation, tSize, gl.FLOAT, false, strideSize, texOffset);

  }


  math.Random rand = new math.Random();

  anime() {
    //
    //
    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.bufferData(gl.ARRAY_BUFFER, nTexture.vertices, gl.STATIC_DRAW);
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, nTexture.indexs, gl.STATIC_DRAW);
    // context.clear( gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT );
    context.clearColor(0.0, 0.3, 0.3, 0.5);
//    context.clearColor(rand.nextInt(100)/100, rand.nextInt(100)/100, rand.nextInt(100)/100, rand.nextInt(100)/100);
    context.clear(gl.COLOR_BUFFER_BIT);
    context.drawElements(gl.TRIANGLES, nTexture.indexs.length, gl.UNSIGNED_SHORT, 0);
    context.flush();
  }

  html.Element get element => _canvas;
}