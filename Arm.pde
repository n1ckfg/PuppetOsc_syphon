class Arm extends Limb{
  
    Arm(){
      super(spriteFolderArm,12);
      init();
    }
    
    Arm(PImage[] _name){
      super(_name,12);
      init();
    }
    
    void init(){
      super.init();
      landscape = true;
    }    
    
}
