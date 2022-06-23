public class Particle{
  PVector pos;
  PVector vel;
  int mass;
  PVector acc = new PVector();
  
  public Particle(PVector pos, PVector vel, int mass){
    this.pos = pos;
    this.vel = vel;
    this.mass = mass;
  }
  
  void update(PVector totalForce) {
    //Verlet Integration implementation : https://en.wikipedia.org/wiki/Verlet_integration [Algorithmic representation]
    PVector new_pos = new PVector();
    PVector.add(pos, PVector.add( PVector.mult(vel,dt), PVector.mult(acc, dt*dt*0.5)), new_pos);
    PVector new_acc = new PVector();
    PVector.div(totalForce, mass, new_acc);
    PVector new_vel = new PVector();
    PVector.add(vel, PVector.mult(PVector.add(acc, new_acc), (dt * 0.5)), new_vel);
    if(pos == new_pos){
      println("A particle with totalForce: " + totalForce + " has not moved");
    }
    pos = new_pos;
    vel = new_vel;
    acc = new_acc;
  }
  
  void display() {
    stroke(255, 255, 255, 100);
    if(showAsVectors){
      PVector normVel = new PVector();
      PVector.div(vel, vel.mag(), normVel);
      PVector normAcc = new PVector();
      PVector.div(acc, acc.mag(), normAcc);
      strokeWeight(1);
      stroke(vel.mag() * 2, 255 - vel.mag() * 1.5, 0, 100);
      line(pos.x, pos.y, pos.x + normVel.x * 5, pos.y + normVel.y * 5);
      //line(pos.x, pos.y, pos.x + normAcc.x * 3, pos.y + normAcc.y * 3);
      return;
    }
    strokeWeight(sqrt(mass));
    point(pos.x, pos.y);
  }
}
