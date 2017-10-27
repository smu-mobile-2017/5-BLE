// REQUIRED
#if defined(ARDUINO) 
SYSTEM_MODE(SEMI_AUTOMATIC); 
#endif

/* ============================================= */
/* BEGIN BLE SETTINGS */
/* ============================================= */
#define MIN_CONN_INTERVAL        0x0028
#define MAX_CONN_INTERVAL        0x0190
#define SLAVE_LATENCY            0x0000
#define CONN_SUPERVISION_TIMEOUT 0x03E8

// [CITE] https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.gap.appearance.xml&u=org.bluetooth.characteristic.gap.appearance.xml
#define BLE_PERIPHERAL_APPEARANCE BLE_APPEARANCE_UNKNOWN
#define BLE_DEVICE_NAME "mslc_team_geode"

#define CHARACTERISTIC1_MAX_LEN  15
#define CHARACTERISTIC2_MAX_LEN  15
#define TXRX_BUF_LEN             15

static uint8_t service1_uuid[16]    = { 0x71,0x3d,0x00,0x00,0x50,0x3e,0x4c,0x75,0xba,0x94,0x31,0x48,0xf1,0x8d,0x94,0x1e };
static uint8_t service1_tx_uuid[16] = { 0x71,0x3d,0x00,0x03,0x50,0x3e,0x4c,0x75,0xba,0x94,0x31,0x48,0xf1,0x8d,0x94,0x1e };
static uint8_t service1_rx_uuid[16] = { 0x71,0x3d,0x00,0x02,0x50,0x3e,0x4c,0x75,0xba,0x94,0x31,0x48,0xf1,0x8d,0x94,0x1e };

static uint8_t appearance[2] = {
	LOW_BYTE(BLE_PERIPHERAL_APPEARANCE),
	HIGH_BYTE(BLE_PERIPHERAL_APPEARANCE)
};

static uint8_t change[4] = {
	0x00, 0x00, 0xFF, 0xFF
};

static uint8_t  conn_param[8] = {
	LOW_BYTE(MIN_CONN_INTERVAL), HIGH_BYTE(MIN_CONN_INTERVAL), 
	LOW_BYTE(MAX_CONN_INTERVAL), HIGH_BYTE(MAX_CONN_INTERVAL), 
	LOW_BYTE(SLAVE_LATENCY), HIGH_BYTE(SLAVE_LATENCY), 
	LOW_BYTE(CONN_SUPERVISION_TIMEOUT), HIGH_BYTE(CONN_SUPERVISION_TIMEOUT)
};

static advParams_t adv_params = {
	.adv_int_min   = 0x0030,
	.adv_int_max   = 0x0030,
	.adv_type      = BLE_GAP_ADV_TYPE_ADV_IND,
	.dir_addr_type = BLE_GAP_ADDR_TYPE_PUBLIC,
	.dir_addr      = {0,0,0,0,0,0},
	.channel_map   = BLE_GAP_ADV_CHANNEL_MAP_ALL,
	.filter_policy = BLE_GAP_ADV_FP_ANY
};

static uint8_t adv_data[] = {
	0x02,
	BLE_GAP_AD_TYPE_FLAGS,
	BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE,

	0x08,
	BLE_GAP_AD_TYPE_SHORT_LOCAL_NAME,
	'B','i','s','c','u','i','t',

	0x11,
	BLE_GAP_AD_TYPE_128BIT_SERVICE_UUID_COMPLETE,
	0x1e,0x94,0x8d,0xf1,0x48,0x31,0x94,0xba,0x75,0x4c,0x3e,0x50,0x00,0x00,0x3d,0x71
};

static uint16_t character1_handle = 0x0000;
static uint16_t character2_handle = 0x0000;

static uint8_t characteristic1_data[CHARACTERISTIC1_MAX_LEN] = { 0x01 };
static uint8_t characteristic2_data[CHARACTERISTIC2_MAX_LEN] = { 0x00 };

static btstack_timer_source_t characteristic2;

char rx_buf[TXRX_BUF_LEN];
static uint8_t rx_state = 0;
/* ============================================= */
/* END BLE SETTINGS */
/* ============================================= */

// DIGITAL
#define SERVO_PIN 1           //Value range: 0-179 (180)
#define BUTTON_PIN 4          //Value range: 0-1 (2)

// ANALOG
#define POTENTIOMETER_PIN 0   //Value range: 0-4095 (4096)

// COMMANDS
#define MOTOR_TOKEN "m"
#define LED_TOKEN "l"
#define READ_TOKEN "r"

#include <string>
#include <vector>
#include <sstream>

using namespace std;

/* ============================================= */
/* BEGIN BLE FUNCTIONS */
/* ============================================= */
void deviceDidConnect(BLEStatus_t status, uint16_t handle) {
  switch (status) {
	case BLE_STATUS_OK:
		Serial.println("Device connected!");
		break;
	default: 
		break;
  }
}

void deviceDidDisconnect(uint16_t handle){
	Serial.println("Disconnected.");
}

int didWriteData(uint16_t value_handle, uint8_t *buffer, uint16_t size) {
	//Serial.print("Write value handler: ");
	//Serial.println(value_handle, HEX);

	if (character1_handle == value_handle) {
		memcpy(characteristic1_data, buffer, min(size,CHARACTERISTIC1_MAX_LEN));
		/*
		Serial.print("Characteristic1 write value: ");
		for (uint8_t index = 0; index < min(size,CHARACTERISTIC1_MAX_LEN); index++) {
			Serial.print(characteristic1_data[index], HEX);
			Serial.print(" ");
		}
		Serial.println(" ");
		*/
		handleWriteData((char*)characteristic1_data);
	}
	return 0;
}

/*
static void characteristic2_notify(btstack_timer_source_t *ts) {   
	if (Serial.available()) {
		//read the serial command into a buffer
		uint8_t rx_len = min(Serial.available(), CHARACTERISTIC2_MAX_LEN);
		Serial.readBytes(rx_buf, rx_len);
		//send the serial command to the server
		Serial.print("Sent: ");
		Serial.println(rx_buf);
		rx_state = 1;
	}
	if (rx_state != 0) {
		ble.sendNotify(character2_handle, (uint8_t*)rx_buf, CHARACTERISTIC2_MAX_LEN);
		memset(rx_buf, 0x00, 20);
		rx_state = 0;
	}
	// reset
	ble.setTimer(ts, 200);
	ble.addTimer(ts);
}
*/

static void writeData(uint8_t* data, uint8_t data_bytes) {   
	//read the serial command into a buffer
	uint8_t rx_len = min(data_bytes, CHARACTERISTIC2_MAX_LEN);
	memcpy(rx_buf, data, rx_len);

	Serial.print("Sent: ");
	Serial.println(rx_buf);
	rx_state = 1;

	if (rx_state != 0) {
		ble.sendNotify(character2_handle, (uint8_t*)rx_buf, CHARACTERISTIC2_MAX_LEN);
		memset(rx_buf, 0x00, 20);
		rx_state = 0;
	}
}

void bleSetup() {
	ble.init();

	ble.onConnectedCallback(deviceDidConnect);
	ble.onDisconnectedCallback(deviceDidDisconnect);
	ble.onDataWriteCallback(didWriteData);

	ble.addService(BLE_UUID_GAP);
	ble.addCharacteristic(BLE_UUID_GAP_CHARACTERISTIC_DEVICE_NAME, ATT_PROPERTY_READ|ATT_PROPERTY_WRITE, (uint8_t*)BLE_DEVICE_NAME, sizeof(BLE_DEVICE_NAME));
	ble.addCharacteristic(BLE_UUID_GAP_CHARACTERISTIC_APPEARANCE, ATT_PROPERTY_READ, appearance, sizeof(appearance));
	ble.addCharacteristic(BLE_UUID_GAP_CHARACTERISTIC_PPCP, ATT_PROPERTY_READ, conn_param, sizeof(conn_param));
	ble.addService(BLE_UUID_GATT);
	ble.addCharacteristic(BLE_UUID_GATT_CHARACTERISTIC_SERVICE_CHANGED, ATT_PROPERTY_INDICATE, change, sizeof(change));
	ble.addService(service1_uuid);
	character1_handle = ble.addCharacteristicDynamic(service1_tx_uuid, ATT_PROPERTY_NOTIFY|ATT_PROPERTY_WRITE|ATT_PROPERTY_WRITE_WITHOUT_RESPONSE, characteristic1_data, CHARACTERISTIC1_MAX_LEN);
	character2_handle = ble.addCharacteristicDynamic(service1_rx_uuid, ATT_PROPERTY_NOTIFY, characteristic2_data, CHARACTERISTIC2_MAX_LEN);
	ble.setAdvertisementParams(&adv_params);
	ble.setAdvertisementData(sizeof(adv_data), adv_data);
	ble.startAdvertising();

	// one-shot timer
	/*
	characteristic2.process = &characteristic2_notify;
	ble.setTimer(&characteristic2, 500); // 100ms
	ble.addTimer(&characteristic2);
	*/
}
/* ============================================= */
/* END BLE FUNCTIONS */
/* ============================================= */

Servo servo;
uint16_t potentiometerValue = 0;
uint16_t servoDegrees = 0;
uint8_t currentColor[3] = {0,0,0};

vector<string> tokenize(string input) {
	istringstream iss(input);
	vector<string> tokens;
	for(string token; getline(iss, token, ' '); ) {
		tokens.push_back(token);
	}
	return tokens;
}

int stoi(string numberString) {
	return atoi(numberString.c_str());
}

void handleWriteData(const char* data) {
	Serial.println("Handle write data:");
	Serial.println(data);
	interpret(string(data));
}

void interpret(string command) {	
	auto tokens = tokenize(command);

	//Compare the command identifier
	if(tokens[0] == MOTOR_TOKEN) {
		moveServo(stoi(tokens[1]));
	} 
	// led command
	// "l r[0-255] g[0-255] b[0-255]"
	else if(tokens[0] == LED_TOKEN) {
		uint8_t color[3];
		for(int i = 0; i < 3; ++i) {
			color[i] = stoi(tokens[i+1]);
		}
		RGB.color(color[0],color[1],color[2]);
		currentColor[0] = color[0];
		currentColor[1] = color[1];
		currentColor[2] = color[2];
	}
	// read command
	// "r"
	else if(tokens[0] == READ_TOKEN) {
		uint8_t bytes[10];
		// servo
		bytes[0] = servoDegrees >> 8;
		bytes[1] = servoDegrees & 0xff;

		// potentiometer
		bytes[2] = potentiometerValue >> 8;
		bytes[3] = potentiometerValue & 0xff;

		// led
		bytes[6] = currentColor[0];
		bytes[7] = currentColor[1];
		bytes[8] = currentColor[2];

		// buffer << "m " << servoDegrees << endl;
		// buffer << "p " << potentiometerValue << endl;
		// buffer << "r " << color[0] << " " << color[1] << " " << color[2] << endl;

		bytes[9] = '\0';
		
		writeData(bytes, 10);
	} 
	// error state
	else {
		Serial.println("Could not interpret command:");
		Serial.println(command.c_str());
	}
}

void setup() {
	RGB.control(true);
	Serial.begin(115200);
	
	bleSetup();

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
	Serial.println("Did press button");
	if(currentColor[0] == 0 && currentColor[1] == 0 && currentColor[2] == 0) {
		RGB.color(255,255,255);
		currentColor[0] = 255;
		currentColor[1] = 255;
		currentColor[2] = 255;
	} else {
		RGB.color(0,0,0);
		currentColor[0] = 0;
		currentColor[1] = 0;
		currentColor[2] = 0;
	}
}

void moveServo(int degrees) {
	int delta = abs(servoDegrees-degrees);
	if(delta >= 4) {
		servoDegrees = degrees;
		servo.write(degrees);
	}
}