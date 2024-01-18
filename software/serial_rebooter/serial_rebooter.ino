/*
Serial UART control of Haasoscope rebooter
Board: Arduino Nano
Processor: ATmega168
*/

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);  // pin 13
  digitalWrite(LED_BUILTIN,HIGH);
  Serial.begin(9600);
  Serial.println("Arduino Connected");
}

String input;
void loop() {
    //USAGE: haasoscope on/off
    if(Serial.available()){
        input = Serial.readStringUntil('\n');
        Serial.println("Read: " + input);
        if(input.substring(0, 10) == "haasoscope") {
          if (input.substring(11,13) == "on") {
            Serial.println("on");
            digitalWrite(LED_BUILTIN,HIGH);
          }
          else if (input.substring(11,14) == "off"){
            Serial.println("off");
            digitalWrite(LED_BUILTIN,LOW);
          }
        }
    }
}
