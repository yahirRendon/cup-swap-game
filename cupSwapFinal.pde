/****************************************************************************** 
 * Project:  Simple Cup Swap Game
 * Move the cups to guess the proper order by getting the number of 
 * cups in the correct position after each guess. 
 * 
 * 
 * Notes:
 * - LEFT CLICK on cups to select and swap
 * - SPACE to reset cups
 * - RIGHT ARROW to change number of cups in play
 * 
 ******************************************************************************/
PFont font;                    // font for text  
PImage[] cupImagesOriginal;    // hold original loaded images
PImage[] cupImages;            // array of cup images shuffled   
ArrayList<Cup> cups;           // array of cup objects
int[] targetOrder;             // array containing targer order for cups

int cupImgWidth;               // witdth of cup image
int cupImgHeight;              // height of cup image
int numCups;                   // number of cups in play (3-5)
int numCupsCorrect;            // number of cups matching target order
int numGuessesRound;           // number of guesses per round
int numGuessesTotal;           // number of total guess in game
int round;                     // the game round

boolean waitingToSwap;         // track when to swap cups after moving
Cup firstSelected;             // track when cup is first clicked
Cup swapCupA, swapCupB;        // track two cups to be swapped a and b

int gameDelay;                 // delay amount between rounds
int gameTimer;                 // set time for game delay
boolean roundOver;             // trigger game delay when round is over

int winTimer;
int winCupDelay;
int winCupCounter;
int winIncAmt;

/******************************************************************************
 * 
 * setup sketch
 * 
 *****************************************************************************/
void setup() {
  size(800, 800);
  textAlign(CENTER, CENTER);
  
  surface.setTitle("cup swap");

  font = createFont("Montserrat-Light.ttf", 32);
  textFont(font);

  cupImgWidth = 120;
  cupImgHeight = 120;

  numCups = 5;
  cupImages = new PImage[5];
  cupImagesOriginal = new PImage[5];
  cupImagesOriginal[0] = loadImage("coffee_cup.png");
  cupImagesOriginal[1] = loadImage("paper_cup.png");
  cupImagesOriginal[2] = loadImage("plastic_cup.png");
  cupImagesOriginal[3]  = loadImage("plain_cup.png");
  cupImagesOriginal[4] = loadImage("tea_cup.png");

  int[] shuffled = shuffledIndices(5);
  for (int i = 0; i < 5; i++) {
    cupImages[i] = cupImagesOriginal[shuffled[i]];
  }

  waitingToSwap = false;
  firstSelected = null;
  swapCupA = null;
  swapCupB = null;

  generateCups();

  roundOver = false;
  round = 1;
  numGuessesRound = 0;
  numGuessesTotal = 0;
  numCupsCorrect = 0;
  gameDelay = 4000;
  gameTimer = millis();
  
  winCupCounter = 0;
  winIncAmt = 1;
  winCupDelay = 150;
  winTimer = millis();
}

/******************************************************************************
 * 
 * draw sketch
 * 
 *****************************************************************************/
void draw() {
  background(255, 253, 242);
  textSize(12);

  // display and update cup animations
  for (Cup c : cups) {
    c.update();
    c.display();
  }

  // swap cup in cups index after arc moving animation
  if (waitingToSwap) {
    if (!swapCupA.isMoving && !swapCupB.isMoving) {
      int indexA = cups.indexOf(swapCupA);
      int indexB = cups.indexOf(swapCupB);

      // swap cup positions in the array
      cups.set(indexA, swapCupB);
      cups.set(indexB, swapCupA);
      waitingToSwap = false;
    }
  }

  // display game text and trigger round delays
  fill(80);
  if (roundOver) {
    
    textSize(32);
    text("winner!", width/2, 635);
    
    // up/down cup animation on win
    if (millis() > winTimer + winCupDelay) {
      winTimer = millis();
      Cup curCup = cups.get(winCupCounter);
      if(curCup.y != curCup.yHome) {
        curCup.setupMovement(curCup.x, curCup.yHome, 250, "VERTICAL");
        
      } else {
        curCup.setupMovement(curCup.x, curCup.yHome - 40, 250, "VERTICAL");
      }
      winCupCounter = winCupCounter + winIncAmt;
      if (winCupCounter > numCups - 1 || winCupCounter < 0) winIncAmt *= -1;
      if(winCupCounter < 0) winCupCounter = 0;
      if(winCupCounter > numCups -1) winCupCounter = numCups - 1;
    }
    
    if (millis() > gameTimer + gameDelay) {   
      generateCups();
      round++;
      numGuessesRound = 0;
      roundOver = false;
      numCupsCorrect = 0;
      winCupCounter = 0;
      winIncAmt = 1;
    }
  }

  textSize(16);
  text("round guesses", 100, 30);
  text(numGuessesRound, 100, 60);
  text("round", width/2, 30);
  text(round, width/2, 60);
  text("total guesses", width - 100, 30);
  text(numGuessesTotal, width - 100, 60);

  if (numGuessesRound != 0 && !roundOver) {
    textSize(16);
    text("cups correct", width/2, 620);
    textSize(28);
    text(numCupsCorrect, width/2, 650);
  }
}

/******************************************************************************
 * KEY PRESSED
 * 
 * SPACE         | submit guess
 * RIGHT ARROW   | cycle through num cups playable
 *****************************************************************************/
void keyPressed() {

  if (key == ' ') {
    checkCupOrder();
    //test = true;
  }

  if (key == CODED) {
    if (keyCode == RIGHT) {
      numCups++;
      if (numCups > 5) numCups = 3;
      generateCups();
      resetGameStats();
    }
  }
}

/******************************************************************************
 * MOUSE PRESSED
 * 
 * LEFT CLICK             | select/deslect cups
 *****************************************************************************/
void mouseClicked() {
  if (mouseButton == LEFT) {
    for (Cup c : cups) {
      if (c.hover()) {
        // no cup selected
        if (firstSelected == null) {
          firstSelected = c; 
          c.setupMovement(c.x, c.yHome - 40, 250, "VERTICAL");
          // if cup already selected
        } else if (c == firstSelected) {
          c.setupMovement(c.x, c.yHome, 250, "VERTICAL");
          firstSelected = null;
          // two different cups selected
        } else if (c != firstSelected) {
          c.setupMovement(firstSelected.x, firstSelected.yHome, 700, "ARC");
          firstSelected.setupMovement(c.x, c.yHome, 700, "ARC");
          // set up swap
          swapCupA = c;
          swapCupB = firstSelected;
          waitingToSwap = true;
          firstSelected = null;
        }
      }
    }
  }
}

/******************************************************************************
 * create a shuffled array of indices using Fisher–Yates algorithm
 *
 * returns a newly shuffled array of length n
 *****************************************************************************/
int[] shuffledIndices(int n) {
  int[] idx = new int[n];
  for (int i = 0; i < n; i++) {
    idx[i] = i;
  }
  for (int i = n-1; i > 0; i--) {
    int j = int(random(i+1));
    int tmp = idx[i];
    idx[i] = idx[j];
    idx[j] = tmp;
  }
  return idx;
}

/******************************************************************************
 * 
 * generate a new arrangement of cups, target order, and spawn animations
 *****************************************************************************/
void generateCups() {

  // shuffle the array of cupImages to get unique image order
  int[] shuffled = shuffledIndices(5);
  for (int i = 0; i < 5; i++) {
    cupImages[i] = cupImagesOriginal[shuffled[i]];
  }

  // add unique order cups and ids to cups array
  cups = new ArrayList<Cup>();
  int[] mixedOrder = shuffledIndices(numCups);
  for (int i = 0; i < numCups; i++) {
    int dex = mixedOrder[i];
    int xOffset = width/2 - ((numCups * cupImgWidth)/2);
    int yOffset = height/2 - cupImgHeight/2;
    int xCur = xOffset + i * cupImgWidth;
    int yCur = yOffset;
    cups.add(new Cup(dex, xCur, yCur, cupImages[dex]));
  }

  // move cups to center and animate
  for (int i = 0; i < numCups; i++) {
    cups.get(i).setToCenter();
    cups.get(i).arcToHome();
  }

  // set target order with none matching to start
  int numCorrect  = numCups;
  while (numCorrect >= 1) {
    targetOrder = shuffledIndices(numCups);
    numCorrect = 0;
    for (int i = 0; i < cups.size(); i++) {
      if (cups.get(i).id == targetOrder[i]) numCorrect++;
    }
  }

  // for testing
  //for (int i = 0; i < targetOrder.length; i++) {
  //  print(targetOrder[i] + " ");
  //}
  //println();
}


/******************************************************************************
 * Check cups arrangement to target order and update game statistics
 *
 *
 *****************************************************************************/
void checkCupOrder() {
  numGuessesRound++;
  numGuessesTotal++;
  int numCorrect  = 0;
  for (int i = 0; i < cups.size(); i++) {
    if (cups.get(i).id == targetOrder[i]) numCorrect++;
  }
  numCupsCorrect = numCorrect;
  if (numCorrect == numCups) {
    roundOver = true;
    gameTimer = millis();
    winTimer = millis();
  }
}

/******************************************************************************
 * reset the game numbers/statestics
 *
 *
 *****************************************************************************/
void resetGameStats() {
  roundOver = false;
  round = 1;
  numGuessesRound = 0;
  numGuessesTotal = 0;
  numCupsCorrect = 0;
  winCupCounter = 0;
}



/******************************************************************************
 * class for creating a cup object with animations
 *
 * 
 *****************************************************************************/
class Cup {
  float x, y;                  // the x and y values (pixels)
  float yHome, xHome;          // the home/start x and y values (pixels)
  PImage img;                  // the cup image
  int id;                      // the cup id
  boolean selected;            // track if the cup has been selected

  // for animations
  float startX, startY;
  float targetX, targetY;
  float startTime;
  float duration;
  boolean isMoving;
  String moveType;
  float arcHeight;

  /******************************************************************************
   * constructor
   * 
   * @param  id         the unique cup id
   * @param  x          the x position of the cup
   * @param  y          the y position of the cup
   * @param  img        the image of the 
   *****************************************************************************/
  Cup(int id, float x, float y, PImage img) {
    this.id = id;
    this.x = x;
    this.y = y;
    this.yHome = y;
    this.xHome = x;
    this.img = img;
    this.selected = false;

    this.startX = -Float.MIN_VALUE;
    this.startY = -Float.MIN_VALUE;
    this.targetX = -Float.MIN_VALUE;
    this.targetY = -Float.MIN_VALUE;
    this.startTime = millis();
    this.duration = -Float.MIN_VALUE;
    this.isMoving = false;
    this.moveType = null;
    this.arcHeight = random(100, 160);
  }

  /******************************************************************************
   * determine if mouse is over cup
   *
   * return true if hover else return false
   *****************************************************************************/
  boolean hover() {
    float xmid = this.x + cupImgWidth/2;
    float ymid = this.y + cupImgHeight/2;
    //ellipse(xmid, ymid, 100, 100);
    if (dist(mouseX, mouseY, xmid, ymid) < 50) {
      return true;
    } else {
      return false;
    }
  }

  /******************************************************************************
   * method to set x value to center of sketch
   *****************************************************************************/
  void setToCenter() {
    this.x = width/2;
    this.x = this.yHome;
  }

  /******************************************************************************
   * helper method to move to home x and y position in arc motion
   *****************************************************************************/
  void arcToHome() {
    this.setupMovement(this.xHome, this.yHome, int(random(600, 750)), "ARC");
  }

  /******************************************************************************
   * helper method to move cup vertically
   *****************************************************************************/
  void moveVertical(float targetX, float targetY, float duration) {
    this.setupMovement(targetX, targetY, duration, "VERTICAL");
  }

  /******************************************************************************
   * helper method to move cup horizontally
   *****************************************************************************/
  void moveHorizontal(float targetX, float targetY, float duration) {
    this.setupMovement(targetX, targetY, duration, "HORIZONTAL");
  }

  /******************************************************************************
   * helper method method to move cup in arc 
   *****************************************************************************/
  void moveArc(float targetX, float targetY, float duration) {
    this.setupMovement(targetX, targetY, duration, "ARC");
  }

  /******************************************************************************
   * method to set up values for moving cup
   *****************************************************************************/
  void setupMovement(float tx, float ty, float dur, String type) {
    this.startX = x;
    this.startY = y;
    this.targetX = tx;
    this.targetY = ty;
    this.duration = dur;
    this.startTime = millis();
    this.moveType = type;
    this.isMoving = true;
    this.arcHeight = random(180, 260);
  }

  /******************************************************************************
   * update animations
   *****************************************************************************/
  void update() {
    if (!this.isMoving) return;

    float t = (millis() - this.startTime) / this.duration;
    t = constrain(t, 0, 1);

    if (this.moveType.equals("VERTICAL")) {
      this.x = this.startX;
      this.y = lerp(this.startY, this.targetY, t);
      
    } else if (this.moveType.equals("HORIZONTAL")) {
      this.x = lerp(this.startX, this.targetX, t);
      this.y = this.startY;
   
    } else if (this.moveType.equals("ARC")) {
      // Linear x and y interpolation
      float lx = lerp(this.startX, this.targetX, t);
      float ly = lerp(this.startY, this.targetY, t);

      // Parabolic arc using sine for smooth up-down
      float arcY = -sin(PI * t) * this.arcHeight;
      this.x = lx;
      this.y = ly + arcY;

    }

    if (t >= 1) {
      this.isMoving = false;
      this.x = int(this.x);
      this.y = int(this.y);
      
    }
  }

  /******************************************************************************
   * display the cup
   *****************************************************************************/
  void display() {
    image(this.img, this.x, this.y);
    //fill(0);
    //text("id:" + id, x, y);
  }
}
