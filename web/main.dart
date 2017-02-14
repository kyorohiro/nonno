import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:async';
import 'imageutil.dart';
import 'ntexture.dart';
import 'nprogram.dart';
import 'dart:math' as math;
import 'nonno.dart' as nonno;

math.Random rand = new math.Random.secure();

main() async {
  nonno.main();
}

/*
main() async {
  NGPU ngpu = new NGPU(size: 8);
  html.document.body.children.add(ngpu.canvasElement);
  ngpu.render();
}*/

class NGPU {
  final int size;

  //
  //
  gl.RenderingContext context;
  html.CanvasElement canvasElement;
  NGPUProgrram program;
  gl.Framebuffer frameBuffer;
  gl.Renderbuffer depthBuffer;
  gl.Texture fTexture;

  html.ImageData imdata;
  math.Random rand = new math.Random.secure();
  Uint8List pixels;

  NGPU({this.size: 32}) {
    html.CanvasRenderingContext2D ctx = new html.CanvasElement(width: size, height: size).getContext("2d");
    imdata = ctx.createImageData(size, size); // ImageData作る
    var i = 0;
    pixels = new Uint8List(size * size * 4);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        var color = (x % 2 == 0 ? 255 : 0); //rand.nextInt(255);
        pixels[i] = imdata.data[i++] = color;
        pixels[i] = imdata.data[i++] = color;
        pixels[i] = imdata.data[i++] = color;
        pixels[i] = imdata.data[i++] = 255;
      }
    }
    canvasElement = new html.CanvasElement(width: size, height: size);
    canvasElement.style.width = "32px";
    canvasElement.style.height = "32px";
    program = new NGPUProgrram();
    context = canvasElement.getContext3d();
    program.compile(context);
    init();
  }


  Float32List positionData;
  Uint16List indexData;
  gl.Buffer position;
  gl.Buffer index;

  bindFramebuffer() {
    positionData = new Float32List.fromList(
        [
          -1.0, 1.0, 0.0,
          1.0, 1.0, 0.0,
          -1.0, -1.0, 0.0,
          1.0, -1.0, 0.0
        ]
    );
    indexData = new Uint16List.fromList([
      0, 1, 2,
      2, 3, 1
    ]);
    position = context.createBuffer();
    context.bindBuffer(gl.ARRAY_BUFFER, position);
    context.bufferData(gl.ARRAY_BUFFER, positionData, gl.STATIC_DRAW);
    //context.bindBuffer(gl.ARRAY_BUFFER, null);
    index = context.createBuffer();
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexData, gl.STATIC_DRAW);
    //∂context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
    //
    context.bindBuffer(gl.ARRAY_BUFFER, position);
    context.enableVertexAttribArray(program.vertexPositionLocation);
    context.vertexAttribPointer(program.vertexPositionLocation, 3, gl.FLOAT, false, 0, 0);
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index);
  }

  ootexture() {
    var texture = context.createTexture();
    context.bindTexture(gl.TEXTURE_2D, texture);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    context.bindTexture(gl.TEXTURE_2D, texture);
//    context.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, imdata);
    context.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        size,
        size,
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        pixels);
//    context.generateMipmap(gl.TEXTURE_2D);
  }

  init() {
    createFramebuffer();
    var ext = context.getExtension('OES_texture_float');
    if (ext == null) {
      throw new Exception("No support for OES_texture_float");
    }
    bindFramebuffer();
    ootexture();
  }

  render() {
    context.clearColor(0.0, 0.0, 1.0, 1.0);
    context.clearDepth(1.0);
    context.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    context.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
    context.bindBuffer(gl.ARRAY_BUFFER, position);
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index);
    context.uniform1f(program.sizeLocation, size);
    context.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_SHORT, 0);
    context.flush();

    {
      var pixels = new Uint8List(size * size * 4);
      context.readPixels(
          0,
          0,
          size,
          size,
          gl.RGBA,
          gl.UNSIGNED_BYTE,
          pixels);
      print("==B=> ${pixels.buffer.asUint8List()}");
    }
  }

  createFramebuffer() {
    frameBuffer = context.createFramebuffer();
    context.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
    depthBuffer = context.createRenderbuffer();
    //
    context.bindRenderbuffer(gl.RENDERBUFFER, depthBuffer);
    context.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, size, size);
    context.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, depthBuffer);
    //
    fTexture = context.createTexture();
    context.bindTexture(gl.TEXTURE_2D, fTexture);
    context.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        size,
        size,
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        null);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);

    context.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fTexture, 0);
    context.bindTexture(gl.TEXTURE_2D, null);
  }
}

class NGPUProgrram {
  // calc position
  String vertextShaderSrc = const [
    "attribute vec3 vertexPosition;",
    "void main() {",
    "  gl_Position = vec4(vertexPosition, 1.0);",
    "}",
  ].join("\r\n");

  // write to pixel
  String fragmentShaderSrc = const [
    "precision mediump float;",
    "uniform sampler2D texture;",
    "uniform float time;",
    "uniform float size;",
    "void main() {",
//    "   gl_FragColor = texture2D(texture, gl_FragCoord.xy/size);",
    "}",
  ].join("\r\n");

  gl.UniformLocation sizeLocation;
  int vertexPositionLocation;
  gl.UniformLocation timeLocation;

  gl.Program get program => _program;
  gl.Program _program;

  gl.Program compile(gl.RenderingContext context, {bool doUse: true}) {
    gl.Shader vertexS = context.createShader(gl.VERTEX_SHADER);
    gl.Shader fragmS = context.createShader(gl.FRAGMENT_SHADER);
    context.shaderSource(vertexS, vertextShaderSrc);
    context.compileShader(vertexS);
    context.shaderSource(fragmS, fragmentShaderSrc);
    context.compileShader(fragmS);
    if (false == context.getShaderParameter(vertexS, gl.COMPILE_STATUS)) {
      throw new Exception(["failed to comile vertex shader: ", //
      context.getShaderInfoLog(vertexS)
      ].join("\r\n"));
    }
    if (false == context.getShaderParameter(fragmS, gl.COMPILE_STATUS)) {
      throw new Exception(["failed to comile fragment shader: ", //
      context.getShaderInfoLog(fragmS)
      ].join("\r\n"));
    }

    //
    // link program
    _program = context.createProgram();
    context.attachShader(program, vertexS);
    context.attachShader(program, fragmS);
    context.linkProgram(program);

    if (false == context.getProgramParameter(program, gl.LINK_STATUS)) {
      throw new Exception(["failed to link program: ", //
      context.getProgramInfoLog(program)
      ].join("\r\n"));
    }
    vertexPositionLocation = context.getAttribLocation(program, "vertexPosition");
    timeLocation = context.getUniformLocation(program, "time");
    sizeLocation = context.getUniformLocation(program, "size");
    if (doUse) {
      context.useProgram(_program);
    }
    return program;
  }
}
/*

*/