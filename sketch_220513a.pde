//              ABOUT
//This is a Java application that runs
//N-Body[1] simulations using the Barnes-
//Hut[2] algorithm and CPU multi-threading.
//It's built using the Processing Library.
//It runs simulations on the order of
//10^4 N.

//[1] = https://en.wikipedia.org/wiki/N-body_problem
//[2] = https://en.wikipedia.org/wiki/Barnes%E2%80%93Hut_simulation
import java.util.ArrayList;

//SETTINGS
static int N = 10000;
static float vel = 50;
static int topMass = 5;
static float G = 50; //gravitational constant
static boolean singleGalaxy = true; //a single Galaxy [true] or a system of Galaxies / Superclusters [false] (use different settings of G and vel for these, example G *  5 for false)
static boolean dynamicTimestep = true; //keeps at constant simulation speed at the cost of accuracy for larger values of N //overrides dt value
static boolean multithread = true; //RUNS FORCE CALCULATIONS SIMULTANEOUSLY ACROSS THREADS
static boolean showTree = false; //show the Barnes-Hut tree
static boolean showAsVectors = true; //show as vectors instead of points

//MORE ADVANCED SETTINGS?
static int threads = 12;
float dt = 0.01;
float noiseScale = 0.02;
float rootWidth = 5000; //only the initial rootWidth for the first instantiation
static int margin = 20;
static int frameRateMax = 120;

ArrayList<Particle> particles = new ArrayList<Particle>(N);
TreeNode root = new TreeNode(0,0, 800);

void setup(){
  size(1000, 1000, P2D);
  frameRate(frameRateMax);
  background(0);
  
  for(int i = 0; i < N; i++){
    PVector pos = getPos();
    PVector velocity = new PVector();
    if(singleGalaxy){
      PVector displacement = new PVector();
      PVector.sub(pos, new PVector(width/2, height/2), displacement);
      float distance = dist(width/2 , height/2, pos.x, pos.y);
      if(displacement.y > 0){
        velocity = new PVector(-1, displacement.x/displacement.y);
      }else{
        velocity = new PVector(1, -displacement.x/displacement.y);
      }
      velocity.normalize();
      velocity.mult((vel*sqrt(distance + 1))/5); //CONSTANT ANGULAR VELOCITY (ish)
      //velocity.mult(vel); //CONSTANT VELOCITY
    }else{
      velocity = new PVector(random(-vel,vel), random(-vel,vel));
    }
    int mass = int(random(1,topMass));
    particles.add(new Particle(pos, velocity, mass));
  }
}
//PERLIN NOISE WIEGHTED SPAWNS
float radius = 400;
PVector getPos(){
  PVector bestPos = new PVector();
  float bestNoise = 0;
  for(int i = 0; i < 40; i++){ // --- HIGHER VALUES FOR i's LIMIT WILL CLUSTER BODIES MORE TIGHTLY ---
    PVector position = new PVector(random((width/2)-radius,(width/2)+radius), random((height/2)-radius,(height/2)+radius));
    float weight;
    if(singleGalaxy){
      weight =  1 / sqrt( pow( dist( width/2, height/2, position.x, position.y ),2 ) + 2 ); //[SEE https://www.desmos.com/calculator/ghc8wu9ahr]
    }else{
      weight = 1;
    }
    if( noise(position.x * noiseScale, position.y * noiseScale) * weight > bestNoise){
      bestPos = position;
      bestNoise = noise(position.x * noiseScale, position.y * noiseScale) * weight;
    }
  }
  return bestPos;
}

void draw(){
  background(0);
  //showVectors(3);
  
  instantiateTree();
  //per particle calculations
  float greatestDist = 0;
  for (Particle particle : particles){
    particle.display();
    if(abs(particle.pos.x - width/2) > greatestDist){
      greatestDist = abs(particle.pos.x - width/2);
    }
    if(abs(particle.pos.y - height/2) > greatestDist){
      greatestDist = abs(particle.pos.y - height/2);
    }
    root.addParticle(particle); //add particle to tree
  }
  rootWidth = greatestDist; //dynamically scale the tree
  if(dynamicTimestep){
    updateTimestep();
  }
  root.updateCOM(); //recursively update the center of mass for each node [see TreeNode]
  if(!multithread){
    calcGravitation(); //solve for forces in each particle [see Gravitation]
  }else{
    calcGravitationThreaded(); //solves for forces in each particles, split between threads [see Multithread Gravitation]
  }
  showError(); //display error statistics
  if(showTree){
    root.display(); //show the area of each node and each non-leaf's center of mass
  }
  //root.displayOnlyCOM(); //show ONLY each non-leaf's center of mass
  
  text("Framerate: " + frameRate, 0, 10);
}

void instantiateTree(){
  float rootX = root.COM.x - rootWidth - margin;
  float rootY = root.COM.y - rootWidth - margin ;
  root = new TreeNode(rootX,rootY, 2*rootWidth + 2* margin);
  text("rootWidth | <--> | " + int(2*rootWidth) + "units" + " = " + int((2*rootWidth / width)*100) + "%", 0, 20);
}


PVector lastCOM = new PVector(0,0);
PVector COM = new PVector(0,0);
PVector COMVel = new PVector(0,0);
PVector lastCOMVel = new PVector(0,0);
void showError(){
  COM = root.COM;
  PVector.sub(COM, lastCOM, COMVel);
  COMVel.div(dt);
  text("Per frame acceleration error: " + PVector.div(PVector.sub(COMVel, lastCOMVel),1), 0, 30);
  text("root center of mass veloctiy: " + COMVel, 0, 40);
  lastCOM = COM;
  lastCOMVel = COMVel;
}

void updateTimestep(){
  dt = 1/(5*frameRate);
  text("dt: " + dt, 0, 50);
}


ArrayList<PVector> prevCOMs = new ArrayList<PVector>();
ArrayList<PVector> newCOMs = new ArrayList<PVector>();
ArrayList<PVector> avgCOMVel = new ArrayList<PVector>();
void showVectors(int depth){ // depth 0 = only root | depth 1 = root's children | depth 2 = root's children children | ... //TODO: REPLACE ALL OF THIS WITH A SYSTEM THAT SHOWS FORCE VECTORS
   newCOMs = getCOMs(root, depth);
   if(prevCOMs.size() == newCOMs.size()){
     for(int i = 0; i < newCOMs.size() - 1; i++){
       PVector COMVel = new PVector();
       PVector.sub(newCOMs.get(i), prevCOMs.get(i), COMVel);
       avgCOMVel.add(COMVel);
       stroke(255,0,0, 100);
       ellipse(newCOMs.get(i).x, newCOMs.get(i).y, 2,2);
     }
   }
   prevCOMs = new ArrayList<PVector>(newCOMs.size());
   prevCOMs.addAll(newCOMs);
}

ArrayList<PVector> getCOMs(TreeNode node, int depth){
  ArrayList<PVector> COMs = new ArrayList<PVector>();
  if(!node.leaf && depth != 0){
    for(int j = 0; j < 4; j++){
      TreeNode child = node.children[j];
      COMs.addAll(getCOMs(child, depth - 1));
    }
  }
  COMs.add(node.COM);
  return COMs;
}
