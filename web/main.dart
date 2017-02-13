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
  // Create canvas and context
  var canvas = html.document.createElement('canvas');
  html.document.body.children.add(canvas);
  gl.RenderingContext context = canvas.getContext("experimental-webgl");



  // Query extension
  //var OES_texture_float = gl.getExtension('OES_texture_float');
  //if (!OES_texture_float) {
   // throw new Exception("No support for OES_texture_float");
 // }

  // Clear
  //context.viewport(0, 0, canvas.width, canvas.height);
  //context.clearColor(1.0, 0.0, 0.0, 1.0);
  //context.clear(gl.COLOR_BUFFER_BIT);

  // Create texture
  var texture = context.createTexture();
  context.bindTexture(gl.TEXTURE_2D, texture);
  context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  context.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 32, 32, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);


  // Create and attach frame buffer
  var fbo = context.createFramebuffer();
  context.bindFramebuffer(gl.FRAMEBUFFER, fbo);
  context.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
  context.bindTexture(gl.TEXTURE_2D, null);
  if (context.checkFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE) {
    throw new Exception("gl.checkFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE");
  }
  context.bindFramebuffer(gl.FRAMEBUFFER, null);
  // Clear
  context.viewport(0, 0, canvas.width, canvas.height);
  context.clearColor(1.0, 0.0, 0.0, 1.0);
  context.clear(gl.COLOR_BUFFER_BIT);
  Uint8List pixels = new Uint8List(4 * 32 * 32); /////
  context.readPixels(0, 0, 32, 32, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
  print("==ZB=> ${pixels.buffer.asUint8List()}");
}
mainA() async{
  //nonno.main();
  int w = 256;
  int h = 256;
  NGPU ngpu = new NGPU();
  html.document.body.children.add(ngpu.canvasElement);
  ngpu.canvasElement.onMouseMove.listen((html.MouseEvent e) {
    ;
  });
  ngpu.render();
}

class NGPU {
  html.CanvasElement canvasElement;
  NGPUProgrram program;
  gl.RenderingContext context;
  final int width;
  final int height;

  NGPU({this.width: 256, this.height: 256}) {
    canvasElement = new html.CanvasElement(width: width, height: height);
    program = new NGPUProgrram();
    context = canvasElement.getContext3d();
    program.compile(context);

    init();
  }

  gl.Framebuffer frameBuffer;
  gl.Renderbuffer depthBuffer;
  gl.Texture fTexture;
  createFramebuffer(){
    frameBuffer = context.createFramebuffer();
    context.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
    depthBuffer = context.createRenderbuffer();
    //
    context.bindRenderbuffer(gl.RENDERBUFFER,depthBuffer);
    context.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, width, height);
    context.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, depthBuffer);
    //
    fTexture = context.createTexture();
    context.bindTexture(gl.TEXTURE_2D,fTexture);
    context.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);


    context.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fTexture, 0);

    //context.bindTexture(gl.TEXTURE_2D, null);
    //context.bindRenderbuffer(gl.RENDERBUFFER, null);
    //context.bindFramebuffer(gl.FRAMEBUFFER, null);
  }

  init() {
    createFramebuffer();

    //
    //
    Float32List positionData = new Float32List.fromList([
      -1.0,  1.0,  0.0,
      1.0,  1.0,  0.0,
      -1.0, -1.0,  0.0,
      1.0, -1.0,  0.0
    ]);
    Uint16List indexData = new Uint16List.fromList([
      0,2,1,
      1,2,3
    ]);
    gl.Buffer position = context.createBuffer();
    context.bindBuffer(gl.ARRAY_BUFFER, position);
    context.bufferData(gl.ARRAY_BUFFER, positionData, gl.STATIC_DRAW);
    context.bindBuffer(gl.ARRAY_BUFFER, null);
    gl.Buffer index = context.createBuffer();
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexData, gl.STATIC_DRAW);
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
    //
    //

    context.bindBuffer(gl.ARRAY_BUFFER, position);
    context.enableVertexAttribArray(program.vertexPositionLocation);
    context.vertexAttribPointer(program.vertexPositionLocation,3,gl.FLOAT,false, 0,0);
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index);

    context.viewport(0, 0, width, height);
    context.clearColor(0.0,0.0,0.0,1.0);

    //
    //

  }

  render() async {
    int t = new DateTime.now().microsecondsSinceEpoch;
    for(int i=0;i<30;i++)
    {
      await new Future.delayed(new Duration(milliseconds: 200));

      context.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
      int tt = new DateTime.now().microsecondsSinceEpoch;
//      context.uniform1f(program.timeLocation,(tt-t)/10000/100);
      context.clearColor(1.0,0.0,0.0,1.0);
      context.clearDepth(1.0);
      context.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
      //

      //
  //    context.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_SHORT, 0);
      context.flush();
     // context.bindFramebuffer(gl.FRAMEBUFFER, null);
      //

   //   var pixels = new Float32List(256 * 256*4);
   //   context.readPixels( 0, 0, 256, 256, gl.RGBA, gl.FLOAT, pixels);
      context.bindFramebuffer(gl.FRAMEBUFFER, null);
      var pixels = new Uint8List(256 * 256*4);
      context.readPixels( 0, 0, 256, 256, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
      print("==Z=> ${(tt-t)/10000/10000}");
      print("==B=> ${pixels.buffer.asUint8List().sublist(0,100)}");
    }
  }

  createTexture(gl.RenderingContext context) {
    var position_data = new Uint8List.fromList([
      255, 255, 0, 255,
      0, 255, 0, 255,
      0, 0, 255, 255,
      255, 255, 255, 255,
    ]);

    var position_texture = context.createTexture();
    context.bindTexture(gl.TEXTURE_2D, position_texture);

    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    context.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        2,
        2,
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        position_data); //

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
    "uniform float time;",
    "void main() {",
    "  gl_FragColor = vec4(sin(time),cos(time), tan(time), 1.0);",
    "}"
  ].join("\r\n");

  int _vertexPositionLocation;
  gl.UniformLocation _timeLocation;

  int get vertexPositionLocation => _vertexPositionLocation;
  gl.UniformLocation get timeLocation => _timeLocation;


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
    _vertexPositionLocation = context.getAttribLocation(program, "vertexPosition");
    _timeLocation = context.getUniformLocation(program, "time");
    if (doUse) {
      context.useProgram(_program);
    }
    return program;
  }
}
