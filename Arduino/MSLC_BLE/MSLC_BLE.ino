//REQUIRED
#if defined(ARDUINO) 
SYSTEM_MODE(SEMI_AUTOMATIC); 
#endif

#include <stdio.h>
#include <string.h>

// DIGITAL
#define SERVO_PIN 1           //Value range: 0-179 (180)
#define BUTTON_PIN 4          //Value range: 0-1 (2)

// ANALOG
#define POTENTIOMETER_PIN 0   //Value range: 0-4095 (4096)

// COMMANDS
#define MOTOR_TOKEN "m"
#define LED_TOKEN "l"
#define READ_TOKEN "r"

Servo servo;
int potentiometerValue = 0;
int servoDegrees = 0;

int match(char* token, char* target) {
	return strcmp(token,target) == 0;
}

void interpret(char* command, char* buffer) {
	char* token;
	int color[3];
	
	token = strtok(command, " ");

	//Compare the command identifier
	if(match(token, MOTOR_TOKEN)) {
		token = strtok(NULL, " ");
		moveServo(atoi(token));
	} 
	// led command
	// "l r[0-255] g[0-255] b[0-255]"
	else if(match(token, LED_TOKEN)) {
		for(int i = 0; i < 3; ++i) {
			token = strtok(NULL, " ");
			color[i] = atoi(token);
		}
	} 
	// read command
	// "r"
	else if(match(token, READ_TOKEN)) {
		char buffer[256];
		char* b = &*buffer;
		sprintf(b, "m %d\n", servoDegrees);
		sprintf(b, "p %d\n", potentiometerValue);
		sprintf(b, "r %d %d %d\n", color[0], color[1], color[2]);
	} 
	// error state
	else {
		Serial.print("ERROR IN INTERPRETING THE COMMAND\n");
	}
}

void setup() {
	Serial.begin(115200);

	// setup servo
	servo.attach(SERVO_PIN);

	// setup button
	pinMode(BUTTON_PIN, INPUT);
	attachInterrupt(digitalPinToInterrupt(BUTTON_PIN), didPressButton, FALLING);
}

void loop() {
	potentiometerValue = analogRead(POTENTIOMETER_PIN);

	// limiting range to prevent clicking of defective servo
	moveServo(map(potentiometerValue, 0, 4095, 0, 150));
	
	// int buttonValue = digitalRead(BUTTON_PIN);

	// delay(50);
}

void didPressButton() {
	Serial.print("Did press button");
}

void moveServo(int degrees) {
	servoDegrees = degrees;
	servo.write(degrees);
}

