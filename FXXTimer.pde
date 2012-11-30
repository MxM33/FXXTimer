import ddf.minim.*;
import controlP5.*;


String version = "0";
String revision = "1";


ControlP5 cp5;
ControlWindow controlWindow;
MultiList pl;

int a=0;
Minim minim;

int t, count;
boolean alarm;

int[] round_idx = new int[200];
 int next_round=0;
String playlist_file = "playlist.m3u";

int prev_file,next_file=0;

int num_string;
String[] tfiles;
String timer;

int mode=1;
int roller = 1;

int tround,tgroup;
int troundmax=0,tgroupmax=0;  

int minutus=0,secundus=0;
int  timer_state,player_state = 0;

AudioPlayer pfile;
PFont Dfont,Tfont;

void setup()
{
  int cnt =0;
  size(350, 280, P3D); 
  frame.setTitle("FXXTimer v" +version + "." + revision );
  cp5 = new ControlP5(this);
  controlWindow = cp5.addControlWindow("playlist", 50, 100, 250, 400)
    .hideCoordinates()
    .setBackground(color(40))
    .hide()
    ;
  
  Dfont = createFont("Arial Bold",100);
  Tfont = createFont("Arial Bold",25);
  tfiles = loadStrings(playlist_file);
  
  pl = cp5.addMultiList("myList",20,20,80,12)
          .moveTo(controlWindow)
          ;
  for( int i=0; i < tfiles.length; i++){ // разбор плейлиста
    //println(tfiles[i]);
    if (tfiles[i].charAt(0) == '#'){  // нужны только комменты
       String[] gr = splitTokens(tfiles[i],", "); // находим строку # ROUND 1, GROUP 1 и берем из нее номер группы  и тура
       if (gr.length > 2){
         if (gr[1].equals( "ROUND")) {
           round_idx[cnt++] = i; // позицию в плейлисте в массив индексов
           tround = int(gr[2]); troundmax=tround;
           tgroup = int(gr[4]); if (tgroup>tgroupmax) tgroupmax=tgroup;
          //println(gr);
         }
       }
     }
    }
  MultiListButton b;
  cnt=0;
  for (int i=1;i<=troundmax;i++){ // расставляем менюшки по местам
    b = pl.add("Round "+ i,i);
    b.setHeight(20);
    b.setWidth(100);
    b.setColorBackground(color(64,0,0));
    for(int j=1;j<=tgroupmax;j++){
      b.add("Round "+i+j*10,cnt).setLabel("group"+j);
      b.setHeight(20);
      b.setColorBackground(color(64,0,0));
      //print (round_idx[cnt]+" " );
    cnt++;  
    }//println(" ");
  }
  tround = 1;
  tgroup = 1;
  t = second();
  timer = nf(minutus,2)+':'+nf(secundus,2);
  minim = new Minim(this);
  
  next_file = 0;
  while ((tfiles[next_file].charAt(0) == '#')&&(next_file < tfiles.length)) next_file++; // ищем первый не комментарий
  prev_file = next_file;
  pfile = minim.loadFile(tfiles[next_file], 2048);
  pfile.play(pfile.length()-1);
  next_round=0;
  mode = 1; // счет назад
}

void draw() 
{
  
  background(70); 
  if ( t == second()) {  // текущая секунда
      if (player_state==1){ // говорилке 'можно'
      if (tfiles[next_file].charAt(0) != '#'){ // играем любой не комментарий
         if (!pfile.isPlaying()){ // сейчас не играется открываем следующий по списку
            if (pfile != null){ // закрываем предыдущий файлик
               pfile.close();
               //println("close");
               }
           //println(tfiles[next_file]);
           pfile = minim.loadFile(tfiles[next_file],2048); // выбираем следующий и проигрываем
           if (pfile==null)
             println("cannot open " + tfiles[next_file] );
           prev_file = next_file; //  номер текущего играемого файла 
           pfile.play();
           
           String[] gr = splitTokens(tfiles[next_file],", _."); // разбираем имя файла по кусочкам
           println(gr.length);println(gr);
          // выставляем таймер в соответствии
           switch(gr.length){
             case 4:
               if((gr[2].equals("working"))||(gr[2].equals("allup"))||(gr[2].equals("ales"))||(gr[2].equals("poker"))){ 
                 minutus = int (gr[0]);  // XX_min_working.mp3
                 secundus = 0;
                 timer_state = 2; 
                 }
               if (gr[2].equals("landing")){ // XX_sec_landing.mp3
                 minutus = 0;
                 secundus = int (gr[0]);
                 timer_state = 2; // приостановить проигрывание на время работы таймера
                 } 
               break;
            case 6:
               if(gr[4].equals("prep")){ // XX_min_XX_sec_prep.mp3
                 minutus = int (gr[0]);
                 secundus = int(gr[2]);
                 timer_state = 2; 
               }  
             default:
               break;  
            }
           
            next_file++; // следующий !
           }
           else{ // сейчас проигрывается файл
           }
          }
        else{ // обработка комментария в плейлисте
          String[] gr = splitTokens(tfiles[next_file++],", "); // находим строку # ROUND 1, GROUP 1 и берем из нее номер группы  и тура
          //println(gr);
          if (gr.length > 2){
          if (gr[1].equals( "ROUND")) {
            tround = int(gr[2]); 
            tgroup = int(gr[4]); 
            }
           }
         } 
      }
      else
        pfile.pause();
      //println(timer_state);
      if (timer_state > 0){ // если таймеру 'можно считать' 
        timer = nf(minutus,2)+':'+nf(secundus,2); // новое время
        //timer = nf(hour(),2)+':'+nf(minute(),2)+':'+nf(second(),2);
        } 
      }
     else{ // начало следующей секунды
       t = second();
       
       // перекинуть цыфры в табло
       // println("A"+nf(minutus,2)+nf(secundus,2));
       //
       
       switch(mode){ 
        case 1: // счет назад минуты : секунды
         if (timer_state > 0){
          if ((minutus == 0) && (secundus == 0)) timer_state=0; // таймер счет закончил
          else if (secundus-- <= 0) {
           minutus--;
           secundus=59;
           }
          }
         break;
        case 2: // счет вперед минуты : секунды
         if (timer_state > 0){
          if (secundus++ > 60) {
           minutus++;
           secundus=0;
           }
          }
          break;
         }
        if (pfile.isPlaying()){ 
          switch(roller){
            case 1: roller=2;break;
             case 2: roller=3;break;
             case 3: roller=4;break;
             case 4: roller=1;break;
            }
         }
     }
  //textFont(Tfont);
  //fill(128, 128, 255); 
  
  textFont(Tfont);
  text("Тур",70,30);
  text("Группа",220,30);
  
  if (player_state==0)
    text("#",150,30);
  else
    text(">",150,30);
  if (pfile.isPlaying()){ 
          switch(roller){
            case 1: text("|", 20,250);break;
             case 2: text("/", 20,250);break;
             case 3: text("-", 20,250);break;
             case 4: text("\\",20,250);break;
            }
         }
  String[] sf = split(tfiles[prev_file],"."); // отбросим .mp3
  text(sf[0],50,250); // название проигрываемого файла 
  
  textFont(Dfont);
  fill(255, 255, 255); 
  
  text(tround,50,120);
  text(tgroup,250,120);
  text(timer,50,210);
}

void controlEvent(ControlEvent theEvent) {
  //println(theEvent.getController().getId());
  println(tfiles[round_idx[int(theEvent.value())]] );
 /* 
  String[] gr = splitTokens(tfiles[next_file++],", "); // находим строку # ROUND 1, GROUP 1 и берем из нее номер группы  и тура
  if (gr.length > 2){
  if (gr[1].equals( "ROUND")) {
     tround = int(gr[2]); 
     tgroup = int(gr[4]); 
     }
  }*/ 
  next_file = round_idx[int(theEvent.value())];
  pfile.pause();
  //pfile.play(pfile.length()); // перемотать в конец
  timer_state=1;
  minutus=0;
  secundus=0;
  
}


void keyPressed()
{
  
  if ((key==' ')&& (cp5.window("playlist") != null)){ 
    
    if (cp5.window("playlist").isVisible()) 
      cp5.window("playlist").hide();
    else 
      cp5.window("playlist").show();
  }
  if ( key == 'p' ){
   player_state ^= 1;
   if (player_state == 0) 
     timer_state = 0;
   else{
     timer_state = 1;
     pfile.play();
   }
   }
}

void stop()
{
  pfile.close();
  minim.stop();
  super.stop();
}

