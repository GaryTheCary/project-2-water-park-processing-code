import glitchP5.*; 
import neurosky.*;
import org.json.*;
import codeanticode.syphon.*;
import maxlink.*;


Cell[][] cellArray;     
int cellSize = 3;      
int numX, numY;     

PGraphics canvas;
SyphonServer server;
MaxLink link = new MaxLink(this, "bouncer");

attention atten;
meditation medi;
analysis anal;

//variables for the eeg sensor
ThinkGearSocket neuroSocket;
int attention=0;
int prevAtten = 0;
int preMedi = 0;
int meditation=0;
int difAtten = 0;
int difMedi = 0;

//variables for my shader
PShader myShader;
String shaderName = "shader.glsl";

//variables for texting
float af;
float mf;


class attention
{
  float attentionFactor;
  String notice;
  attention() {
  }

  String attentionFLevel(float mat)
  {
    attentionFactor = mat;
    if (attentionFactor<40)
    {
      notice = "low";
    }

    if (attentionFactor>=40&&attentionFactor<60)
    {
      notice = "medi";
    }

    if (attentionFactor>=60&&attentionFactor<=100)
    {
      notice = "high";
    }

    return notice;
  }
}

class meditation
{
  float meditationFactor;
  String notice;
  meditation() {
  }

  String meditationFLevel(float mme)
  {
    meditationFactor = mme;
    if (meditationFactor<40)
    {
      notice = "low";
    }

    if (meditationFactor>=40&&meditationFactor<60)
    {
      notice = "medi";
    }

    if (meditationFactor>=60&&meditationFactor<=100)
    {
      notice = "high";
    }

    return notice;
  }
}

class analysis {
  attention a;
  meditation m;
  String emotion;
  float frequency;
  float stateIndex;

  analysis() {
  }

  String state(attention ma, meditation mm)
  {
    a = ma;
    m = mm;

    if (a.notice == "low"&&m.notice=="low")
    {
      emotion = "sleepy";
    }

    if (a.notice == "low"&&m.notice=="medi")
    {
      emotion = "just so so";
    }

    if (a.notice == "low"&&m.notice=="high")
    {
      emotion = "debalance";
    }

    if (a.notice == "medi"&&m.notice=="low")
    {
      emotion = "just so so";
    }

    if (a.notice == "medi"&&m.notice=="medi")
    {
      emotion = "impressive";
    }

    if (a.notice == "medi"&&m.notice=="high")
    {
      emotion = "impressive";
    }

    if (a.notice == "high"&&m.notice=="low")
    {
      emotion = "deblance";
    }

    if (a.notice == "high"&&m.notice=="medi")
    {
      emotion = "impressive";
    }

    if (a.notice == "high"&&m.notice=="high")
    {
      emotion = "superb";
    }
    return emotion;
  }

  float setFrequency()
  {
    if (emotion == "sleepy")
    {
      frequency = 0/*random(80,90)*/;
    }
    if (emotion == "just so so")
    {
      frequency = 0/*random(70,80)*/;
    }
    if (emotion == "impressive")
    {
      frequency = 0/*random(60,70)*/;
    }
    if (emotion == "debalance")
    {
      frequency = 0/*random(50,60)*/;
    }
    if (emotion == "superb")
    {
      frequency = random(50, 60);
    }

    return frequency;
  }

  float setIndex()
  {
    if (emotion == "sleepy")
    {
      stateIndex = 0;
    }
    if (emotion == "just so so")
    {
      stateIndex = 1;
    }
    if (emotion == "impressive")
    {
      stateIndex = 2;
    }
    if (emotion == "deblance")
    {
      stateIndex = 3;
    }
    if (emotion == "superb")
    {
      stateIndex = 4;
    }

    return stateIndex;
  }
}

class Cell {
  float x, y;
  float state;      
  float nextState;  
  float lastState = 0; 
  Cell[] neighbours;

  Cell(float ex, float why) 
  {
    x = ex * cellSize;
    y = why * cellSize;
    nextState = ((x/600) + (y/600)) * 14 ;  
    state = nextState;
    neighbours = new Cell[0];
  }

  void addNeighbour(Cell cell) {
    neighbours = (Cell[])append(neighbours, cell);
  }

  void calcNextState() 
  {
    float total = 0;        
    for (int i=0; i < neighbours.length; i++)
    {  
      total += neighbours[i].state;
    }          
    float average = int(total/8);

    if (average == 255)
    {
      nextState = 0;
    } else if (average == 0)
    {
      nextState = 255;
    } else 
    {
      if (anal.emotion == "sleepy")
      {
        nextState = state + average;
      }
      if (anal.emotion == "just so so")
      {
        nextState = state + average - random(5, 10);
      }
      if (anal.emotion == "deblance")
      {
        nextState = state + average - random(10, 20);
      }
      if (anal.emotion == "impressive")
      {
        nextState = state + average + 5;
      }
      if (anal.emotion == "superb")
      {
        nextState = state + average + 20;
      }

      if (lastState > 0)
      {
        nextState -= lastState;
      }   
      if (nextState > 255)
      {
        nextState = 255;
      } else if (nextState < 0)
      {
        nextState = 0;
      }
      lastState = state;
    }
  }

  void drawMe(PGraphics mcanvas) {
    state = nextState;
    mcanvas.noStroke();
    mcanvas.fill(state);    
    mcanvas.rect(x, y, cellSize, cellSize);
  }
}

void setup()
{
  ThinkGearSocket neuroSocket = new ThinkGearSocket(this);
  try {
    neuroSocket.start();
  } 
  catch (Exception e) {
    println("Is ThinkGear running??");
  }
  size(600, 600, OPENGL);
  canvas = createGraphics(600, 600, OPENGL);
  smooth();
  atten = new attention();
  medi = new meditation();
  anal = new analysis();
  numX = floor(width/cellSize);
  numY = floor(height/cellSize);
  restart(); 
  server = new SyphonServer(this, "Processing Syphon");

  //shader test
  myShader = loadShader(shaderName);
  myShader.set("resolution", float(width), float(height)); 
  myShader.set("time", (float)(millis() / 1000.0));
}

void restart() {
  cellArray = new Cell[numX][numY];  
  for (int x = 0; x<numX; x++) {
    for (int y = 0; y<numY; y++) {  
      Cell newCell = new Cell(x, y);  
      cellArray[x][y] = newCell;
    }
  }          


  for (int x = 0; x < numX; x++) {
    for (int y = 0; y < numY; y++) {  

      int above = y-1;    
      int below = y+1;    
      int left = x-1;      
      int right = x+1;      

      if (above < 0) { 
        above = numY-1;
      }  
      if (below == numY) { 
        below = 0;
      }  
      if (left < 0) { 
        left = numX-1;
      }  
      if (right == numX) { 
        right = 0;
      }  

      cellArray[x][y].addNeighbour(cellArray[left][above]);  
      cellArray[x][y].addNeighbour(cellArray[left][y]);    
      cellArray[x][y].addNeighbour(cellArray[left][below]);  
      cellArray[x][y].addNeighbour(cellArray[x][below]);  
      cellArray[x][y].addNeighbour(cellArray[right][below]);  
      cellArray[x][y].addNeighbour(cellArray[right][y]);  
      cellArray[x][y].addNeighbour(cellArray[right][above]);  
      cellArray[x][y].addNeighbour(cellArray[x][above]);
    }
  }
}


void draw()
{
  canvas.beginDraw();
  canvas.background(0);
  //fft.forward( jingle.mix );
  af = map(mouseX, 0, width, 0, 100);
  mf = map(mouseY, 0, height, 0, 100);
  //  if(meditation == 0&&attention == 0)
  //  {
  //    myShader.set("time", (float)(millis() / 1000.0));
  //    canvas.shader(myShader);
  //    canvas.noStroke();
  //    canvas.fill(0);
  //    canvas.rect(0, 0, width, height);  
  //  }
  //  //water ripple
  //  else
  {
    for (int x = 0; x < numX; x++) 
    {
      for (int y = 0; y < numY; y++)
      {
        cellArray[x][y].calcNextState();
      }
    }

    for (int x = 0; x < numX; x++)
    {
      for (int y = 0; y < numY; y++) 
      {
        cellArray[x][y].drawMe(canvas);
      }
    }
  }
  medi.meditationFLevel(meditation);
  atten.attentionFLevel(attention);
  //medi.meditationFLevel(mf);
  //atten.attentionFLevel(af);
  anal.state(atten, medi);
  //print to test
  println("meditation: "+meditation);
  println("attention: "+attention);
  println("state: " + anal.emotion);
  //set the frequency
  anal.setFrequency();
  //println("frequency is : " + anal.frequency);
  //println("stateIndex is : " + anal.stateIndex);
  anal.setIndex();
  link.output(0, int(anal.frequency));
  link.output(1, int(anal.stateIndex));
  canvas.endDraw();
  image(canvas, 0, 0);
  server.sendImage(canvas);
}

void mousePressed() 
{
  restart();
}

void poorSignalEvent(int sig) {
  println("SignalEvent "+sig);
}

public void attentionEvent(int attentionLevel) {
  println("Attention Level: " + attentionLevel);
  attention = attentionLevel;
}


void meditationEvent(int meditationLevel) {
  println("Meditation Level: " + meditationLevel);
  meditation = meditationLevel;
}

void blinkEvent(int blinkStrength) {

  println("blinkStrength: " + blinkStrength);
  //blinkstrength = blinkStrength;
}

public void eegEvent(int delta, int theta, int low_alpha, int high_alpha, int low_beta, int high_beta, int low_gamma, int mid_gamma) {
  println("delta Level: " + delta);
  println("theta Level: " + theta);
  println("low_alpha Level: " + low_alpha);
  println("high_alpha Level: " + high_alpha);
  println("low_beta Level: " + low_beta);
  println("high_beta Level: " + high_beta);
  println("low_gamma Level: " + low_gamma);
  println("mid_gamma Level: " + mid_gamma);
}

void rawEvent(int[] raw) {
  //println("rawEvent Level: " + raw);
}  

void stop() {
  neuroSocket.stop();
  super.stop();
}

