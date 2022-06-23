public class MultithreadGravitation extends Thread {
  int threadNum;
  boolean finished = false;
  
  public MultithreadGravitation(int threadNum){
    this.threadNum = threadNum;
  }
  
  public void run(){
    for(int i = threadNum; i + threads <= particles.size(); i = i + threads){
      Particle p = particles.get(i);
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
    finished = true;
  }
}
