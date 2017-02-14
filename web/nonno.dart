import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:async';
import 'imageutil.dart';
import 'ntexture.dart';
import 'nprogram.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vec;
import 'package:nonno/nonno.dart' as non;

main() async {
  Nonno nonno = await Nonno.newNonno("assets/ic.jpg",width: 512, height: 512);
  html.document.body.append(nonno.element);
  await nonno.init();
  //for(int i=0;i<30;i++)
  while (true) {
    await nonno.anime();
    await new Future.delayed(new Duration(milliseconds: 20));
  }
}


class Nonno {
  final int width;
  final int height;
  final int cellSize;
  html.CanvasElement _canvas;
  final String texturePath;

  Nonno._private(this.texturePath, {this.width: 256, this.height: 256, this.cellSize: 20}) {
    _canvas = new html.CanvasElement(width: this.width, height: this.height);

  }

  static Future<Nonno> newNonno(String texturePath, {int width: 256, int height: 256, int cellSize: 20}) async {
    Nonno ret = new Nonno._private(texturePath, width: width, height: height, cellSize: cellSize);
    await ret.init();
    return ret;
  }

  gl.RenderingContext context;

  gl.Buffer vertexBuffer;
  gl.Buffer indexBuffer;
  gl.Buffer optBuffer;
  NProgram nprogram;
  NTexture nTexture;

  init() async {
    double ratioHW = width / height;
    context = _canvas.getContext3d();
    context.viewport(0, 0, this.width, this.height);

    nprogram = new NProgram();
    nprogram.compile(context);

    //
    nTexture = await NTexture.newTexture(texturePath, ratioHW: ratioHW, h: 256, w: 256,fh: 12,fw: 12);
    await nTexture.create(context);
    //
    //


    vertexBuffer = context.createBuffer();
    indexBuffer = context.createBuffer();
    optBuffer = context.createBuffer();
  }


  math.Random rand = new math.Random();

  anime() {
    //

    {
      final vSize = 3;
      final cSize = 4;
      final tSize = 2;
      final optSize = 3;
      final strideSize = (vSize + cSize + tSize + optSize) * Float32List.BYTES_PER_ELEMENT;
      final colorOffset = (vSize) * Float32List.BYTES_PER_ELEMENT;
      final texOffset = (vSize + cSize) * Float32List.BYTES_PER_ELEMENT;
      final optOffset = (vSize + cSize + tSize) * Float32List.BYTES_PER_ELEMENT;

      context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
      context.enableVertexAttribArray(nprogram.vertexPositionLocation);
      context.enableVertexAttribArray(nprogram.colorLocation);
      context.enableVertexAttribArray(nprogram.texCoordLocation);
      context.enableVertexAttribArray(nprogram.optPositionLocation);
      context.vertexAttribPointer(nprogram.vertexPositionLocation, vSize, gl.FLOAT, false, strideSize, 0);
      context.vertexAttribPointer(nprogram.colorLocation, cSize, gl.FLOAT, false, strideSize, colorOffset);
      context.vertexAttribPointer(nprogram.texCoordLocation, tSize, gl.FLOAT, false, strideSize, texOffset);
      context.vertexAttribPointer(nprogram.optPositionLocation, optSize, gl.FLOAT, false, strideSize, optOffset);
    }

    //
        {
      context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
      context.bufferData(gl.ARRAY_BUFFER, nTexture.vertices, gl.STATIC_DRAW);
    }
    {
      context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
      context.bufferData(gl.ELEMENT_ARRAY_BUFFER, nTexture.indexs, gl.STATIC_DRAW);
    }
    context.clearColor(0.0, 0.3, 0.3, 0.5);
    context.clear(gl.COLOR_BUFFER_BIT);
    context.drawElements(gl.TRIANGLES, nTexture.indexs.length, gl.UNSIGNED_SHORT, 0);
    context.flush();
    nTexture.updateOpt();
    nTexture.updateOpt();
    nTexture.updateOpt();
  }

  html.Element get element => _canvas;

  //
  //
  //
  double zz = 0.0;


  updateOptB() {
    for (int y = 0; y <= nTexture.h; y++) {
      for (int x = 0; x <= nTexture.w; x++) {
        nTexture.setOpt(x, y,//
            math.sin(math.PI / 12 * zz) * 0.2, //
            math.cos(math.PI / 12 * zz) * 0.2, 0.0);
      }
    }
    zz++;
  }
}
