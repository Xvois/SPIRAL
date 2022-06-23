class TreeNode{
  float x, y, w;
  int totalMass;
  PVector COM;
  
  int numOfParticles;
  TreeNode[] children;
  
  boolean hasParticle;
  Particle particle;
  boolean leaf;
  
  public TreeNode(float x, float y, float w){
    this.x = x;
    this.y = y;
    this.w = w;
    
    this.numOfParticles = 0;
    this.leaf = true;
    this.hasParticle = false;
    this.particle = null;
    this.children = new TreeNode[4];
    
    this.totalMass = 0;
    this.COM = new PVector();
  }
  
  void fragment(){
    //clockwise
    //|-----|-----|
    //|  1  |  2  |
    //|-----|-----|
    //|  4  |  3  |
    //|-----|-----|
    float newW = w * 0.5;
     children[0] = new TreeNode(x, y, newW);
     children[1] = new TreeNode(x + newW, y, newW);
     children[2] = new TreeNode(x + newW, y + newW, newW);
     children[3] = new TreeNode(x, y + newW, newW);
     this.leaf = false;
  }
  
  void addParticle(Particle p){
   if (this.leaf) {
        if (this.particle != null) {
          Particle a = this.particle;
          Particle b = p;
  
          this.numOfParticles++;
          this.totalMass += b.mass;
  
          TreeNode cur = this;
          int qA = cur.index(a);
          int qB = cur.index(b);
          while (qA == qB) {
            cur.fragment();
            cur = cur.children[qA];
            qA = cur.index(a);
            qB = cur.index(b);
            
            cur.totalMass += a.mass + b.mass;
            cur.numOfParticles += 2;
          }
  
          cur.fragment();
          cur.children[qA].particle = a;
          cur.children[qB].particle = b;
  

          cur.children[qA].numOfParticles++;
          cur.children[qB].numOfParticles++;
          
          cur.children[qA].totalMass += a.mass;
          cur.children[qB].totalMass += b.mass;
  
          this.particle = null;
          return;
        }
        this.totalMass += p.mass;
        this.particle = p;
        this.numOfParticles++;
        return;
      }
  
      // Not a leaf
      this.leaf = false;
      this.totalMass += p.mass;
      this.numOfParticles++;
      this.children[this.index(p)].addParticle(p);
    }
  
  int index(Particle p){
    PVector pos = p.pos;
    if(pos.y < y + w*0.5){
      return pos.x < x + w*0.5 ? 0 : 1;
    }
    return pos.x < x + w*0.5 ? 3 : 2;
  }
  
  void updateCOM(){
     PVector SMV = getSMV();
     if(SMV != null){
      COM = SMV.div(totalMass);
     }
    if(!this.leaf){
      for(TreeNode child : children){
        child.updateCOM();
      }
    }
    if( COM.x != COM.x ){
      COM = new PVector();
    }
  }
  
  PVector getSMV(){
    PVector SMV = new PVector(); //SUMMED MASS VECTOR
    if(this.leaf){
      if(this.particle == null){
        return null;
      }
      SMV.x = this.particle.pos.x * this.particle.mass;
      SMV.y = this.particle.pos.y * this.particle.mass;
      return SMV;
    }
    for(TreeNode child : children){
      if(child.particle != null || !child.leaf){
        SMV.add(child.getSMV());
      }
    }
    return SMV;
  }
  
  void display(){
    noFill();
    stroke(255,255,255);
    strokeWeight(0.5);
    rect(x,y,w,w);
    stroke(255,0,0);
    if(!this.leaf){
      ellipse(COM.x, COM.y, 5, 5);
    }
    for(TreeNode child : children){
      if(child != null){
        child.display();
      }
    }
  }
  void displayOnlyCOM(){
    noFill();
    stroke(255,0,0);
    strokeWeight(0.5);
    if(!this.leaf){
      ellipse(COM.x, COM.y, 5, 5);
    }
    for(TreeNode child : children){
      if(child != null){
        child.displayOnlyCOM();
      }
    }
  }
}
