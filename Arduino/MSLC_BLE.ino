//REQUIRED
#if defined(ARDUINO) 
SYSTEM_MODE(SEMI_AUTOMATIC); 
#endif

  //Define digital pins
#define SERVO_PIN 1           //Value range: 0-179 (180)
#define BUTTON_PIN 4          //Value range: 0-1 (2)

  //Define analog pins
#define POTENTIOMETER_PIN 0   //Value range: 0-4095 (4096)

Servo servo;

volatile int state = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);

  pinMode(BUTTON_PIN, INPUT);

  servo.attach(SERVO_PIN);
  attachInterrupt(digitalPinToInterrupt(BUTTON_PIN), changeState, FALLING);
}

int potent_val = 0;
int servo_deg = 0;
bool should_run_servo = true;

void loop() {
  potent_val = analogRead(POTENTIOMETER_PIN);

  if(should_run_servo) {
    servo_deg = map(potent_val, 0, 4095, 0, 150); //Using 150 instead of 179 because there was
                                                    // a lot of clicking when the higher degrees
                                                    // were used. Wanted to spare a servo.
    if(state == 0) {
      servo.write(servo_deg);
    } else if (state == 1) {
      servo.write(162-servo_deg);
    }
  }
  should_run_servo = !should_run_servo;
  
  int button_val = digitalRead(BUTTON_PIN);
                                            
  Serial.print("Servo degree:: "); Serial.println(servo_deg);
  Serial.print("Button value:: "); Serial.println(button_val);
  delay(50);
}

void changeState() {
  state ++;
  if(state > 1) {
    state = 0;
  }
}

