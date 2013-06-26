//PROCESSING 2.08 beta VERSION
//--works with Syphon; does not work with P1.5 shaders
//--does NOT compile in Processing 2 final; Syphon library needs to be updated.
//based on Stickmanetic by ?
import processing.opengl.*;
import codeanticode.syphon.*;
import ddf.minim.*;

int sW = 800;
int sH = 600;
int sD = 700;
int fps = 60;

SyphonServer server;
PGraphics canvas;

boolean debug = false;
boolean audioTrigger = true;
boolean hideCursor = true;
boolean alphaMode = true;
boolean isadoraEcho = true;
boolean doBacteria = true;
color bgColor = color(0);
boolean showBackground = true;

String[] osceletonNames = {
  "head", "neck", "torso", "l_shoulder", "l_elbow", "l_hand", "r_shoulder", "r_elbow", "r_hand", "l_hip", "l_knee", "l_foot", "r_hip", "r_knee", "r_foot"
};
PVector[] osceletonVec = new PVector[osceletonNames.length];

String spriteFolderHead = "horsebuyer";
String spriteFolderArm = "lightning-h";
String spriteFolderLeg = "lightning-h";
String spriteFolderTorso = "lightning-h";
String spriteSheetBacterium = "bacterium";

String syphonServerName = "Processing Syphon";

float noiseIter = 0.0;
int ballSize = 10;

Minim minim;
AudioInput adc;

int numBacteria = 100;
Bacterium[] bacteria = new Bacterium[numBacteria];
float tractorLimit = 100;

AnimSprite head;

Arm[] arm = new Arm[4];
Leg[] leg = new Leg[4];
Torso torso;

HashMap<Integer, Skeleton> skels = new HashMap<Integer, Skeleton>();

void setup() {
  Settings settings = new Settings("settings.txt");
  //hint( ENABLE_OPENGL_4X_SMOOTH );
  if (hideCursor) noCursor();  
  size(sW, sH, P3D);    // use OPENGL rendering for bilinear filtering on texture
  server = new SyphonServer(this, syphonServerName);
  canvas = createGraphics(sW,sH,P3D);
  frameRate(fps);
  smooth();
  head = new AnimSprite(spriteFolderHead, 12);
  head.playing = false;
  head.s = new PVector(0.8, 0.8);
  if(debug) head.debug = true;
  oscSetup();
  if(audioTrigger){
    minim = new Minim(this);
    adc = minim.getLineIn( Minim.MONO, 512 );
  }
  Arm armInit = new Arm();
  Leg legInit = new Leg();
  for (int i=0;i<arm.length;i++) {
    arm[i] = new Arm(armInit.frames);
    arm[i].makeTexture();
    if(debug) arm[i].debug = true;
    arm[i].p = new PVector(320, 240, 0);
    arm[i].index = int(random(arm[i].frames.length));
  }

  for (int i=0;i<leg.length;i++) {
    leg[i] = new Leg(legInit.frames);
    leg[i].makeTexture();
    if(debug) leg[i].debug = true;
    leg[i].p = new PVector(320, 240, 0);
    leg[i].index = int(random(leg[i].frames.length));
  }    
  torso = new Torso();
  torso.makeTexture();
  if(debug) torso.debug = true;
  torso.p = new PVector(320, 240, 0);

  if(doBacteria){
    Bacterium bacterium = new Bacterium();
    for (int i=0;i<bacteria.length;i++) {
      bacteria[i] = new Bacterium(bacterium.frames);
      bacteria[i].make3D(); //adds a Z axis and other features. You can also makeTexture to control individual vertices.
      bacteria[i].p = new PVector(random(sW), random(sH), random(sD)-(sD/2));
      bacteria[i].index = random(bacteria[i].frames.length);
      bacteria[i].r = 0;
      bacteria[i].t = new PVector(random(sW), random(sH), random(sD)-(sD/2));
      bacteria[i].s = new PVector(0.1,0.1);
      if(debug) bacteria[i].debug = true;
    }
  }

  //setupGl();
  if(showBackground) background(bgColor);
}

void drawBone(float joint1[], float joint2[]) {
  if ((joint1[0] == -1 && joint1[1] == -1) || (joint2[0] == -1 && joint2[1] == -1))
    return;

  float dx = (joint2[0] - joint1[0]) * width;
  float dy = (joint2[1] - joint1[1]) * height;
  float steps = 2 * sqrt(pow(dx, 2) + pow(dy, 2)) / ballSize;
  float step_x = dx / steps / width;
  float step_y = dy / steps / height;

  for (int i=0; i<=steps; i++) {
    canvas.ellipse((joint1[0] + (i*step_x))*width, 
    (joint1[1] + (i*step_y))*height, 
    ballSize, ballSize);
  }
}


void draw() {
  //background(bgColor);
  //drawGl();
  drawMain();
}

void drawMain() {
  canvas.beginDraw();
  if (alphaMode && showBackground) {
    canvas.noStroke();
    canvas.fill(bgColor, 50);
    canvas.rectMode(CORNER);
    canvas.rect(0, 0, width, height);
  }
  else {
    if(showBackground) canvas.background(bgColor);
  }

  for (Skeleton s: skels.values()) {

    //"head", "neck", "torso", "l_shoulder", "l_elbow", "l_hand", "r_shoulder", "r_elbow", "r_hand", "l_hip", "l_knee", "l_foot", "r_hip", "r_knee", "r_foot"
    if(isadoraEcho){
      osceletonVec[0] = new PVector(s.headCoords[0],s.headCoords[1],s.headCoords[2]);
      osceletonVec[1] = new PVector(s.neckCoords[0],s.neckCoords[1],s.neckCoords[2]);
      osceletonVec[2] = new PVector(s.torsoCoords[0],s.torsoCoords[1],s.torsoCoords[2]);
      osceletonVec[3] = new PVector(s.lShoulderCoords[0],s.lShoulderCoords[1],s.lShoulderCoords[2]);
      osceletonVec[4] = new PVector(s.lElbowCoords[0],s.lElbowCoords[1],s.lElbowCoords[2]);
      osceletonVec[5] = new PVector(s.lHandCoords[0],s.lHandCoords[1],s.lHandCoords[2]);
      osceletonVec[6] = new PVector(s.rShoulderCoords[0],s.rShoulderCoords[1],s.rShoulderCoords[2]);
      osceletonVec[7] = new PVector(s.rElbowCoords[0],s.rElbowCoords[1],s.rElbowCoords[2]);
      osceletonVec[8] = new PVector(s.rHandCoords[0],s.rHandCoords[1],s.rHandCoords[2]);
      osceletonVec[9] = new PVector(s.lHipCoords[0],s.lHipCoords[1],s.lHipCoords[2]);
      osceletonVec[10] = new PVector(s.lKneeCoords[0],s.lKneeCoords[1],s.lKneeCoords[2]);
      osceletonVec[11] = new PVector(s.lFootCoords[0],s.lFootCoords[1],s.lFootCoords[2]);
      osceletonVec[12] = new PVector(s.rHipCoords[0],s.rHipCoords[1],s.rHipCoords[2]);
      osceletonVec[13] = new PVector(s.rKneeCoords[0],s.rKneeCoords[1],s.rKneeCoords[2]);
      osceletonVec[14] = new PVector(s.rFootCoords[0],s.rFootCoords[1],s.rFootCoords[2]);
    }
    
    if (debug) {
      //Head
      canvas.ellipse(s.headCoords[0]*width, 
      s.headCoords[1]*height + 10, 
      ballSize*5, ballSize*6);

      //Head to neck 
      drawBone(s.headCoords, s.neckCoords);
      //Center upper body
      //drawBone(lShoulderCoords, rShoulderCoords);
      drawBone(s.headCoords, s.rShoulderCoords);
      drawBone(s.headCoords, s.lShoulderCoords);
      drawBone(s.neckCoords, s.torsoCoords);
      //Right upper body
      drawBone(s.rShoulderCoords, s.rElbowCoords);
      drawBone(s.rElbowCoords, s.rHandCoords);
      //Left upper body
      drawBone(s.lShoulderCoords, s.lElbowCoords);
      drawBone(s.lElbowCoords, s.lHandCoords);
      //Torso
      //drawBone(rShoulderCoords, rHipCoords);
      //drawBone(lShoulderCoords, lHipCoords);
      drawBone(s.rHipCoords, s.torsoCoords);
      drawBone(s.lHipCoords, s.torsoCoords);
      //drawBone(lHipCoords, rHipCoords);
      //Right leg
      drawBone(s.rHipCoords, s.rKneeCoords);
      drawBone(s.rKneeCoords, s.rFootCoords);
      //  drawBone(rFootCoords, lHipCoords);
      //Left leg
      drawBone(s.lHipCoords, s.lKneeCoords);
      drawBone(s.lKneeCoords, s.lFootCoords);
      //  drawBone(lFootCoords, rHipCoords);
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //--
    leg[0].j1 = new PVector(s.rHipCoords[0]*width, s.rHipCoords[1]*height);
    leg[0].j2 = new PVector(s.rKneeCoords[0]*width, s.rKneeCoords[1]*height);
    leg[1].j1 = leg[0].j2;
    leg[1].j2 = new PVector(s.rFootCoords[0]*width, s.rFootCoords[1]*height);
    //--
    leg[2].j1 = new PVector(s.lHipCoords[0]*width, s.lHipCoords[1]*height);
    leg[2].j2 = new PVector(s.lKneeCoords[0]*width, s.lKneeCoords[1]*height);
    leg[3].j1 = leg[2].j2;
    leg[3].j2 = new PVector(s.lFootCoords[0]*width, s.lFootCoords[1]*height);
    //--
    arm[0].j1 = new PVector(s.rShoulderCoords[0]*width, s.rShoulderCoords[1]*height);
    arm[0].j2 = new PVector(s.rElbowCoords[0]*width, s.rElbowCoords[1]*height); 
    arm[1].j1 = arm[0].j2;
    arm[1].j2 = new PVector(s.rHandCoords[0]*width, s.rHandCoords[1]*height);
    //--
    arm[2].j1 = new PVector(s.lShoulderCoords[0]*width, s.lShoulderCoords[1]*height);
    arm[2].j2 = new PVector(s.lElbowCoords[0]*width, s.lElbowCoords[1]*height);
    arm[3].j1 = arm[2].j2;
    arm[3].j2 = new PVector(s.lHandCoords[0]*width, s.lHandCoords[1]*height);  

    //--
    torso.j1 = new PVector(s.neckCoords[0]*width, s.neckCoords[1]*height);
    torso.j2 = new PVector(s.torsoCoords[0]*width, 50+s.torsoCoords[1]*height);
    //--
    head.p = new PVector(s.headCoords[0]*width, s.headCoords[1]*height);
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    if (debug) {
      for (float j[]: s.allCoords) {
        canvas.ellipse(j[0]*width, j[1]*height, ballSize*2, ballSize*2);
      }
    } 
    //s.body.createShape(s.edges);
  }

  torso.run();

  leg[0].run();
  leg[2].run();
  arm[0].run();
  arm[2].run();

  if(audioTrigger) head.index = int(trackVolume(13, 75, 2));
  head.run();
  leg[1].run();
  leg[3].run();
  arm[1].run();
  arm[3].run();

  if(doBacteria){
    for (int i=0;i<bacteria.length;i++) {
      
      bacteria[i].run();
  
      if(dist(bacteria[i].p.x,bacteria[i].p.y,bacteria[i].p.z,bacteria[i].t.x,bacteria[i].t.y,bacteria[i].t.z)>50){
        canvas.noFill();
        canvas.strokeWeight(random(1, 5));
        canvas.stroke(255, 50, 0, random(1, 5));
        canvas.beginShape();
        canvas.vertex(bacteria[i].p.x, bacteria[i].p.y, bacteria[i].p.z);
        //vertex(mouseX, mouseY, 0);
        canvas.vertex(head.p.x,head.p.y, 0);
        canvas.endShape();
      }
    }
  }
  canvas.imageMode(CORNER);
  if(isadoraEcho) oscSend(1);
  canvas.endDraw();
  server.sendImage(canvas); //3.  canvas goes to Syphon server
  image(canvas,0,0);
}

float trackVolume(float _scale, float _amp, float _floor) {
  try{
    float volumeLevel=0;  //must reset to 0 each frame before measuring
    for (int i = 0; i < adc.bufferSize() - 1; i++) {
      if ( abs(adc.mix.get(i)) > volumeLevel ) {
        volumeLevel = abs(adc.mix.get(i));
      }
    }
    float returnVal = (_scale * (volumeLevel * _amp))/_scale;
    if (returnVal>_floor) {
      if (returnVal > _scale) returnVal = _scale;
      return returnVal;
    }
    else {
      return 0;
    }
  }catch(Exception e){
    return 0;
  }
}

public void stop() {
  minim.stop();
  super.stop();
}

