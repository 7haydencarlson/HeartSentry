#include <SoftwareSerial.h>
#include <math.h>
#include <HX711_ADC.h>
#include <EEPROM.h>

// ---------- Bluetooth Serial ----------
#define TX_PIN 3
#define RX_PIN 2
SoftwareSerial BTSerial(RX_PIN, TX_PIN);

// ---------- Sine Wave Generation ----------
const int interval = 100;
unsigned long previousMillis = 0;
float angle = 0.0;
const float step = 5.0;
bool measuring = false;

// ---------- Load Cell ----------
const int HX711_dout = 4;
const int HX711_sck = 5;
HX711_ADC LoadCell(HX711_dout, HX711_sck);

const int calVal_eepromAdress = 0;
const int tareOffsetVal_eepromAdress = 4;
float calibrationValue = 696.0;
long tare_offset = 0;

// ---------- Setup ----------
void setup() {
  Serial.begin(9600);
  BTSerial.begin(9600);
  Serial.println("Initializing...");

  LoadCell.begin();

  EEPROM.get(tareOffsetVal_eepromAdress, tare_offset);
  EEPROM.get(calVal_eepromAdress, calibrationValue);
  LoadCell.setTareOffset(tare_offset);

  unsigned long stabilizingtime = 2000;
  LoadCell.start(stabilizingtime, false);
  if (LoadCell.getTareTimeoutFlag() || LoadCell.getSignalTimeoutFlag()) {
    Serial.println("HX711 Timeout. Check wiring.");
    while (1);
  }

  LoadCell.setCalFactor(calibrationValue);
  Serial.print("Startup complete. Calibration factor: ");
  Serial.println(calibrationValue);
  Serial.println("Send 'r' to calibrate, 't' to tare, or 'c' to manually change cal factor.");
}

// ---------- Loop ----------
void loop() {
  static bool newDataReady = false;
  if (LoadCell.update()) newDataReady = true;

  // Serial terminal commands
  if (Serial.available()) {
    char inByte = Serial.read();
    if (inByte == 'r') calibrate();
    else if (inByte == 't') tareAndSave();
    else if (inByte == 'c') changeSavedCalFactor();
  }

  // Bluetooth commands
  if (BTSerial.available()) {
    Serial.println("Available!");
    String cmd = BTSerial.readStringUntil('\n');
    cmd.trim();
    Serial.println("BT command: " + cmd);

    if (cmd == "START") measuring = true;
    else if (cmd == "STOP") measuring = false;
    else if (cmd == "TARE") tareAndSave();
    else if (cmd.startsWith("CAL:")) {
      float known_mass = cmd.substring(4).toFloat();
      if (known_mass > 0) {
        performBluetoothCalibration(known_mass);
      } else {
        Serial.println("Invalid CAL mass.");
      }
    }
  }

  // Measurement and transmission
  if (measuring && millis() - previousMillis >= interval) {
    previousMillis = millis();

    float sineValue = sin(radians(angle));
    angle += step;
    if (angle >= 360.0) angle -= 360.0;

    float weight = newDataReady ? LoadCell.getData() : 0.0;
    newDataReady = false;
    Serial.print

    BTSerial.write((uint8_t*)&sineValue, sizeof(sineValue));
    BTSerial.write((uint8_t*)&weight, sizeof(weight));
    Serial.print("Sending -> ECG (sine): ");
    Serial.print(sineValue);
    Serial.print("  | Weight: ");
    Serial.println(weight);
  }
}

// ---------- Bluetooth Calibration ----------
void performBluetoothCalibration(float known_mass) {
  Serial.println("*** Bluetooth Calibration ***");

  LoadCell.refreshDataSet();
  float newCal = LoadCell.getNewCalibration(known_mass);

  if (newCal > 0) {
    calibrationValue = newCal;
    LoadCell.setCalFactor(calibrationValue);
    EEPROM.put(calVal_eepromAdress, calibrationValue);
    #if defined(ESP8266) || defined(ESP32)
      EEPROM.commit();
    #endif
    Serial.print("New calibration factor: ");
    Serial.println(calibrationValue);
    Serial.println("Calibration saved to EEPROM.");
  } else {
    Serial.println("Calibration failed. Invalid result.");
  }
}

// ---------- Tare ----------
void tareAndSave() {
  Serial.println("Taring...");
  LoadCell.tare();
  tare_offset = LoadCell.getTareOffset();
  EEPROM.put(tareOffsetVal_eepromAdress, tare_offset);
  #if defined(ESP8266) || defined(ESP32)
    EEPROM.commit();
  #endif
  LoadCell.setTareOffset(tare_offset);
  Serial.print("New tare offset: ");
  Serial.println(tare_offset);
}

// ---------- Serial-based Calibration ----------
void calibrate() {
  Serial.println("*** Calibration Mode ***");
  Serial.println("1) Ensure scale is empty and stable.");
  Serial.println("2) Send 't' to tare.");

  bool done = false;
  while (!done) {
    LoadCell.update();
    if (Serial.available() > 0 && Serial.read() == 't') {
      LoadCell.tareNoDelay();
    }
    if (LoadCell.getTareStatus()) {
      Serial.println("Tare complete.");
      done = true;
    }
  }

  Serial.println("Place known mass on scale and enter value (grams): ");
  float known_mass = 0;
  while (known_mass == 0) {
    LoadCell.update();
    if (Serial.available() > 0) {
      known_mass = Serial.parseFloat();
      if (known_mass != 0) {
        Serial.print("Known mass: ");
        Serial.println(known_mass);
      }
    }
  }

  LoadCell.refreshDataSet();
  float newCal = LoadCell.getNewCalibration(known_mass);
  Serial.print("New calibration factor: ");
  Serial.println(newCal);
  Serial.println("Save to EEPROM? (y/n)");

  bool confirm = false;
  while (!confirm) {
    if (Serial.available() > 0) {
      char inByte = Serial.read();
      if (inByte == 'y') {
        calibrationValue = newCal;
        EEPROM.put(calVal_eepromAdress, calibrationValue);
        #if defined(ESP8266) || defined(ESP32)
          EEPROM.commit();
        #endif
        LoadCell.setCalFactor(calibrationValue);
        Serial.println("Calibration saved.");
        confirm = true;
      } else if (inByte == 'n') {
        Serial.println("Calibration not saved.");
        confirm = true;
      }
    }
  }

  Serial.println("*** Calibration Complete ***");
}

// ---------- Manual Calibration Edit ----------
void changeSavedCalFactor() {
  Serial.print("Current cal factor: ");
  Serial.println(calibrationValue);
  Serial.println("Enter new value:");

  float newCal = 0;
  while (newCal == 0) {
    if (Serial.available()) {
      newCal = Serial.parseFloat();
      if (newCal != 0) {
        calibrationValue = newCal;
        LoadCell.setCalFactor(calibrationValue);
        Serial.print("New cal factor: ");
        Serial.println(calibrationValue);
      }
    }
  }

  Serial.println("Save to EEPROM? (y/n)");
  bool confirm = false;
  while (!confirm) {
    if (Serial.available()) {
      char inByte = Serial.read();
      if (inByte == 'y') {
        EEPROM.put(calVal_eepromAdress, calibrationValue);
        #if defined(ESP8266) || defined(ESP32)
          EEPROM.commit();
        #endif
        Serial.println("Calibration saved.");
        confirm = true;
      } else if (inByte == 'n') {
        Serial.println("Calibration not saved.");
        confirm = true;
      }
    }
  }
}
