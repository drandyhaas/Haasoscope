/*
  Software serial multple serial test
  
  Receives from the hardware serial, sends to software serial.
  Receives from software serial, sends to hardware serial.
 */
#include <SoftwareSerial.h>

SoftwareSerial mySerial(10, 11); // RX, TX

void setup() {
  // Open serial communications and wait for port to open:
  Serial.begin(115200);
  while (!Serial) { ; }// wait for serial port to connect. Needed for native USB port only
  Serial.println("Goodnight moon!");

  // set the data rate for the SoftwareSerial port
  mySerial.begin(57600); //9600 //57600 //115200 //1500000
  delay(1000);
  
  //board id 0 and last board
  mySerial.write(uint8_t(0));
  delay(100);
  mySerial.write(uint8_t(20));
  delay(100);
  
  //samplestosend=256
  mySerial.write(uint8_t(122));
  delay(100);
  mySerial.write(uint8_t(1));
  delay(100);
  mySerial.write(uint8_t(0));
  delay(100);
  
  //downsample=0
  mySerial.write(uint8_t(124));
  delay(100);
  mySerial.write(uint8_t(0));
  delay(100);
  
}

int nbytes=0;
unsigned long previousMillis = 0;
const long interval = 3000;
bool paused = false;

void loop() { // run over and over

  //to get new event, send 100 (prime boards), then 10 (readout board 0)
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= interval && !paused) {
    previousMillis = currentMillis;
    mySerial.write(uint8_t(100));
    delay(10);
    mySerial.write(uint8_t(10));
    Serial.println(String(currentMillis)+": asked for board 0 data");
  }

  while (mySerial.available()) {
    int b = mySerial.read();
    nbytes++;
    if (nbytes<5) Serial.println(String(b,HEX)+" ");
  }
  if (nbytes>=4*256) 
    {
      Serial.println(String(currentMillis)+": got "+String(nbytes)+" bytes in "+String(currentMillis - previousMillis)+" ms");
      nbytes=0;
    }

  // read string from the terminal, echo out over serial as a byte
  while(Serial.available()) {
    String a= Serial.readString();
    Serial.println(String(a.toInt()));
    if (a=="p") paused=!paused;
    else mySerial.write(a.toInt());
  }
}
