// Говорящий таймер для соревнований F3K,F3J,F5J

// использовался Processing v1.5.1 http://processing.org
// библиотеки minim,controP5 v1.5.2

// ---Принцип работы---
// анализируется текстовый файл playlist.m3u,на этой основе в нужные моменты 
// запускается обратный отсчет на экране и дублируется на табло 

// ---Управление--- 
// 'p' старт/пауза проигрывания файла и таймера.
// 'r' вызов участников для начала соревнований (resume_after_pause.mp3)
// 'пробел' - открыть/закрыть окно с выбором доступных туров и групп.
// выбор нужной комбинации тура/группы останавливает таймер и начинает 
// последовательность от нужной позиции до конца плейлиста 

// Ваши предложения и замечания принимаются на smaxim33@mail.ru
// версия 0.3 19.05.2013


import ddf.minim.*;
import controlP5.*;
import processing.serial.*;

String version = "0";
String revision = "2";

String RS_port ="COM1"; // порт к которому прицеплено табло. обмен на 9600
String ports[];
boolean port_F;

Serial TxPort;

ControlP5 cp5,errw;
ControlWindow controlWindow;
Textarea errArea;
MultiList pl;
Slider pp;

int a=0;
Minim minim;

int t, count;
boolean alarm;

int[] round_idx = new int[300];  // массив индексов с номерами строк с которых начинаются туры.
int next_round=0;
String playlist_file = "playlist.m3u";

int prev_file,next_file=0;
int play_position;

int num_string;
String[] tfiles;
String timer;
String err= "Error in playlist.m3u\n\r";

int mode=1;
int roller = 1;

int tround,tgroup;
int troundmax=0,tgroupmax=0;  

int minutus=0,secundus=0;
int summary_time;
int  timer_state,player_state = 0;

AudioPlayer pfile;
PFont Dfont,Tfont;

boolean fileExists(String path) {
  File file=new File(dataPath(path));
//  println(dataPath(path));
 if (file.exists())
   return true;
  else 
    return false;
} 


void setup()
{
  int cnt =0,jj;
  
  size(350, 280, P2D); 
  frame.setTitle("FXXTimer v" +version + "." + revision );
  cp5 = new ControlP5(this);
  controlWindow = cp5.addControlWindow("playlist", 50, 100, 250, 400)
    .hideCoordinates()
    .setBackground(color(0))
    .hide()
    ;
  errw = new ControlP5(this);
  

  errArea = errw.addTextarea("error_text")
                  .setPosition(1,1)
                  .setSize(350,280)
                  .setFont(createFont("",14,false))
                  .setLineHeight(18)
                  .setColor(color(255,0,0))
                  .setColorBackground(color(200,200,200))
                  .hide()
                  .setId(10);
                  ;
  
  Dfont = createFont("Arial Bold",100,false);
  Tfont = createFont("Arial Bold",25,false);
  tfiles = loadStrings(playlist_file);
  
  pl = cp5.addMultiList("myList",20,20,80,12)
          .moveTo(controlWindow)
          .setId(2);
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
    else { //не комментарий. файл? есть такой?
      if (!fileExists(tfiles[i])){ // ошибка в названии
        err = err + "line " + (i+1) +" : " + tfiles[i] +"\n"; 
        errArea.setText(err).show();
        }
    } 
    }
  MultiListButton b;
  cnt=0;
  for (int i=1;i<=troundmax;i++){ // расставляем менюшки по местам
    b = pl.add("Round "+ i,i);
    b.setHeight(20)
    .setWidth(100)
    .setColorBackground(color(64,0,0))
    .setId(3);
    ;
    for(int j=1;j<=tgroupmax;j++){
      b.add("Round "+i+j*10,cnt).setLabel("group"+j)
      .setHeight(20)
      .setColorBackground(color(64,0,0))
      .setId(4)
      ;
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
  pfile.play(pfile.length());
  
  //pp.setRange(0,float(pfile.length()/100));
  //pp.setValue(pfile.position()/100);
  
  next_round=0;
  mode = 1; // счет назад
  
  ports = Serial.list();
  println(ports);
  // проверка на наличие сом порта
  port_F = false;
  for (jj=0;jj < ports.length;jj++){
    if (ports[jj].equals(RS_port)) port_F = true;
       }
   if(port_F == false) 
     errArea.setText(RS_port + " Not found").show(); //  ошибка при указании порта или такого нет.
   else
     TxPort = new Serial(this,RS_port,9600);
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
               }
           //println(next_file + ":" + tfiles[next_file]);
           pfile = minim.loadFile(tfiles[next_file],2048); // выбираем следующий и проигрываем
          // float range = pfile.length()/100;
          // pp.setRange(0,range);
           
           prev_file = next_file; //  номер текущего играемого файла 
           pfile.play();
           String[] gr = splitTokens(tfiles[next_file],", _."); // разбираем имя файла по кусочкам. разделители , _ .
          // println(gr.length);println(gr);
          // выставляем таймер в "соответствии c длинной
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
             //int pos = pfile.position()/100;
             // pp.setValue(pos);
           }
          }
        else{ // обработка комментария в плейлисте
          String[] gr = splitTokens(tfiles[next_file++],", "); // находим строку # ROUND 1, GROUP 1 и берем из нее номер группы  и тура
          if (gr.length > 2){
          if (gr[1].equals( "ROUND")) { // отображаем тур/группу
            tround = int(gr[2]); 
            tgroup = int(gr[4]); 
            if(port_F == true){ // и на табло, но только если порт есть
               TxPort.write("A"+nf(tround,2)+nf(tgroup,2));
               TxPort.write(10);
               TxPort.write(13);
               println("A"+nf(tround,2)+nf(tgroup,2));
               }
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
       
       //--------------------- перекинуть цифры в табло--------------------------------------------
       if((timer_state > 0)&&(port_F == true)){ // только если таймер считает и порт есть
         TxPort.write("A"+nf(minutus,2)+nf(secundus,2));
         TxPort.write(10);
         TxPort.write(13);
         println("A"+nf(minutus,2)+nf(secundus,2));
         }
       //------------------------------------------------------------------------------------------
      
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
  
  if (player_state==0)  // рисуем индикацию работает/стоит
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
  text(sf[0],50,250); // рисуем название проигрываемого файла 
  
  textFont(Dfont);
  fill(255, 255, 255); 
  
  text(tround,50,120); // тур
  text(tgroup,250,120);// группа
  text(timer,50,210);  // время
}

void controlEvent(ControlEvent theEvent) {     
  //println(theEvent.getController().getId());
  //println(theEvent.value());

  switch(theEvent.getController().getId()){
    case (1):
      break;
    case (2):  
    case (4):  // выбор начала произвольного тура/группы из менюшки выбираемой "пробелом" 
      player_state = 0;
      timer_state = 0;
      //println(tfiles[round_idx[int(theEvent.value())]] );
      String[] gr = splitTokens(tfiles[next_file++],", "); // находим строку # ROUND 1, GROUP 1 и берем из нее номер группы  и тура
      //println(gr);
      if (gr.length > 2){
      if (gr[1].equals( "ROUND")) { // отображаем тур/группу
         tround = int(gr[2]); 
         tgroup = int(gr[4]); 
         if(port_F == true){ // и на табло, но только если порт есть
           TxPort.write("A"+nf(tround,2)+nf(tgroup,2));
           TxPort.write(10);
           TxPort.write(13);
           println("A"+nf(tround,2)+nf(tgroup,2));
           }
         }
      }
      if (pfile != null)
        pfile.play(pfile.length());
      next_file = round_idx[int(theEvent.value())];
      minutus  =0;
      secundus =0;
      break;  
    }
  
}

void keyPressed()
{
  
  if ((key==' ')&& (cp5.window("playlist") != null)){ // закрыть открыть окно выбора туров и групп
    if (cp5.window("playlist").isVisible()) 
      cp5.window("playlist").hide();
    else 
      cp5.window("playlist").show();
  }
  if ( key == 'p' ){ // старт стоп таймера
   player_state ^= 1;
   if (player_state == 0) 
     timer_state = 0;
   else{
     timer_state = 1;
     pfile.play();
   }
   }
  if (key == 'r'){ // после перерыва чтобы позвать участников к старту
      pfile = minim.loadFile("resume_after_pause.mp3",2048); // При старте проговорить типа "Господа пауза закончилась..." и проигрываем
      pfile.play();
      text("resume_after_pause.mp3",50,250); // рисуем название проигрываемого файла 
      player_state = 1;
      timer_state = 0;
      minutus=3;
      secundus=0;
  } 
}

void stop()
{
  pfile.close();
  minim.stop();
  TxPort.stop();
  super.stop();
  
}

