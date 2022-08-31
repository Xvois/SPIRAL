
import java.util.*;

static float THETA = 0.5; //Threshold value for Barnes-Hut
static float EPSILON = 2; //Smoothing factor for when r --> 0
float validity;
ArrayList<TreeNode> targets;

void calcGravitation(){
  for(Particle p : particles){
    targets = traverseNode(root, p);
    PVector totalForce = new PVector();
    for(TreeNode target : targets){
      PVector newForce = getForce(target,p);
      if(newForce != null){
        totalForce.add(newForce);
      }
    }
    p.update(totalForce);
  }
}

void calcGravitationThreaded(){
  ArrayList<MultithreadGravitation> activeThreads = new ArrayList<MultithreadGravitation>();
  for(int i = 0; i < threads; i++){
    MultithreadGravitation thread = new MultithreadGravitation(i);
    thread.start();
    activeThreads.add(thread);
  }
  MultithreadGravitation masterThread = new MultithreadGravitation(threads);
  masterThread.run();
  activeThreads.add(masterThread);
  boolean ready = false; //MASTER THREAD ENSURES THAT ALL CALCULATIONS ARE COMPLETE BEFORE MOVING FORWARD
  while(ready == false){
    ready = true;
    for(MultithreadGravitation thread : activeThreads){
      //print("Thread " + thread.threadNum + " " + thread.finished + " ");
      if(!ready){break;}
      else if(!thread.finished){
        ready = false;
      }
    }
  }
}


ArrayList<TreeNode> traverseNode(TreeNode node, Particle p){
  ArrayList<TreeNode> validNodes = new ArrayList<TreeNode>();
  if(node.leaf || validity(node, p) < THETA){
    validNodes.add(node);
    return validNodes;
  }
  for(TreeNode child : node.children){
    validNodes.addAll(traverseNode(child, p));
  }
  return validNodes;
}

float validity(TreeNode node, Particle p){
  float nodeWidth = node.w;
  PVector displacement = new PVector();
  displacement.x = node.COM.x - p.pos.x;
  displacement.y = node.COM.y - p.pos.y;
  float distance = displacement.mag();
  return (nodeWidth / distance);
}

PVector getForce(TreeNode node, Particle p){
  int greatestMass;
  PVector displacement = PVector.sub(node.COM, p.pos);
  float distance = dist(node.COM.x, node.COM.y, p.pos.x, p.pos.y);
  if(node.leaf){
     if(node.totalMass > p.mass){
       greatestMass = node.totalMass;
     }else{
       greatestMass = p.mass;
     }
  }else{
    greatestMass = 0;
  }
  if(distance < greatestMass){
    return null;
  }
  float smoothedDistance = sqrt( pow(distance,2) + pow(EPSILON, 2) );
  float gravitationMag = G * ( ( p.mass * node.totalMass) / (smoothedDistance * smoothedDistance ) );
  PVector normDisplacement = displacement.div(distance);
  PVector force = normDisplacement.mult(gravitationMag);
  return force;
}
