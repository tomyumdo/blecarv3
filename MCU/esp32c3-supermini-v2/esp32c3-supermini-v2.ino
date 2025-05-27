#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ESP32Servo.h>

#define BLE_NAME "MINICAR-MCU"
#define SERVICE_UUID "8e364c66-68eb-4dd4-ad06-5306e465ec3b"
#define CHARACTERISTIC_UUID_TX "a44823e4-283c-4392-9c36-1665b378f41f"
#define CHARACTERISTIC_UUID_RX "e5f2bb3c-4188-4ea3-b6e3-04a78cd5033d"

#define LED 0


#define AIN1 10
#define AIN2 20
#define PWMA 21
#define BIN1 8
#define BIN2 7
#define PWMB 6
#define STBY 9

#define CH1 1
#define CH2 2
#define CH3 3

#define FORWARD 1
#define BACKWARD 2
#define TURNLEFT 3
#define TURNRIGHT 4

#define SPEED 64

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristicTX = NULL;
BLECharacteristic* pCharacteristicRX = NULL;

Servo myservo;

// BLE Server Callback
class ServerCallback : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    Serial.println("Client Connected!");
  };

  void onDisconnect(BLEServer* pServer) {
    Serial.println("Client disconnecting... Waiting for new connection");
    pServer->startAdvertising();  // restart advertising
  }
};

// BLE RX Callback
class RXCallback : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    uint8_t* data = pCharacteristic->getData();
    int size = pCharacteristic->getLength();
    int value;

    if (size <= 1) {
      return;
    }

    switch (data[0]) {
      case CH1:
        Serial.printf("Forward/Backward Command: %d\n", data[1]);

        if (data[1] == FORWARD) {
          digitalWrite(AIN1, LOW);
          digitalWrite(AIN2, HIGH);
          analogWrite(PWMA, SPEED);
        } else if (data[1] == BACKWARD) {
          digitalWrite(AIN1, HIGH);
          digitalWrite(AIN2, LOW);
          analogWrite(PWMA, SPEED);
        } else {
          digitalWrite(AIN1, LOW);
          digitalWrite(AIN2, LOW);
          analogWrite(PWMA, 0);
        }
        break;
      case CH2:
        Serial.printf("Left/Right Command: %d\n", data[1]);

        if (data[1] == TURNLEFT) {
          digitalWrite(BIN1, HIGH);
          digitalWrite(BIN2, LOW);
          analogWrite(PWMB, 255);
        } else if (data[1] == TURNRIGHT) {
          digitalWrite(BIN1, LOW);
          digitalWrite(BIN2, HIGH);
          analogWrite(PWMB, 255);
        } else {
          digitalWrite(BIN1, LOW);
          digitalWrite(BIN2, LOW);
          analogWrite(PWMB, 0);
        }
        break;
      case CH3:
        Serial.printf("LED Command: %d\n", data[1]);
        if (data[1] == 1) {
          digitalWrite(LED, HIGH);
        } else {
          digitalWrite(LED, LOW);
        }
        break;
      default:
        break;
    }

  }
};

static void initial() {
  pinMode(LED, OUTPUT);
  pinMode(AIN1, OUTPUT);
  pinMode(AIN2, OUTPUT);
  pinMode(BIN1, OUTPUT);
  pinMode(BIN2, OUTPUT);
  pinMode(PWMA, OUTPUT);
  pinMode(PWMB, OUTPUT);
  pinMode(STBY, OUTPUT);
  digitalWrite(STBY, HIGH);
  digitalWrite(LED, LOW);

  digitalWrite(AIN1, LOW);
  digitalWrite(AIN2, LOW);
  analogWrite(PWMA, 0);
  digitalWrite(BIN1, LOW);
  digitalWrite(BIN2, LOW);
  analogWrite(PWMB, 0);  
}

void setup() {
  Serial.begin(115200);

  // Initialization
  initial();

  // Create the BLE Device
  BLEDevice::init(BLE_NAME);
  Serial.print("\n");
  Serial.printf("BLE Server Mac Address: %s\n", BLEDevice::getAddress().toString().c_str());

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallback());

  // Create the BLE Service
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic For notifying
  pCharacteristicTX = pService->createCharacteristic(
    CHARACTERISTIC_UUID_TX,
    BLECharacteristic::PROPERTY_NOTIFY);

  // Create a BLE Descriptor
  pCharacteristicTX->addDescriptor(new BLE2902());

  // Create a BLE Characteristic For reading
  pCharacteristicRX = pService->createCharacteristic(
    CHARACTERISTIC_UUID_RX,
    BLECharacteristic::PROPERTY_WRITE);
  pCharacteristicRX->setCallbacks(new RXCallback());

  // Create a BLE Descriptor
  pCharacteristicRX->addDescriptor(new BLE2902());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  Serial.println("Waiting a client connection to notify...");
}

void loop() {
  delay(1);
}