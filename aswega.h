#include "esphome.h"

#define SENSOR_CNT 4

class Aswega : public PollingComponent, public UARTDevice {
 Sensor *Q1 {nullptr};
 Sensor *Q2 {nullptr};
 Sensor *T1 {nullptr};
 Sensor *T2 {nullptr};
 Sensor *T3 {nullptr};
 Sensor *dT {nullptr};
 Sensor *P {nullptr};
 Sensor *E {nullptr};
 Sensor *V1 {nullptr};
 Sensor *V2 {nullptr};
 Sensor *date {nullptr};
 Sensor *time {nullptr};

 public:
  Aswega(UARTComponent *parent, Sensor *rconn_id, Sensor *dev_serial) : UARTDevice(parent) , Q1(), Q2(), T1(), T2(), T3(), dT(), P(), E(), V1(), V2(), date(), time() {}

  byte cmdGetVersion[7] = {  0x07, 0x02, 0x00, 0x00, 0x00, 0x04, 0xc4 };
  byte vorlaufSet[7]    = {  0x07, 0x00, 0x00, 0x00, 0x19, 0x00, 0xd2 };        //antwort: 1+5 bytes
  byte vorlaufIst[7]    = {  0x07, 0x00, 0x00, 0x00, 0x18, 0x00, 0xd0 };        //antwort: 1+5 bytes
  byte vorlaufSoll[7]   = {  0x07, 0x00, 0x00, 0x00, 0x39, 0x00, 0x92 };       //antwort: 1+4 bytes -> 40
  byte ruecklauf[7]     = {  0x07, 0x00, 0x00, 0x00, 0x98, 0x00, 0xc9 };       //antwort: 1+4 bytes 

  int getParm(byte *cmd, int lcmd) {
    int val;
    write_array(cmd,lcmd);
    delay(1000);
    while(available()<4){}
    if (available()>=4) {
      int len = read();
      int flag = read();
      val  = read()*16 + (read()>>4);
    } else val=0;
    // überflüssige bytes abräumen
    while(available()) {
      int b = read();
    }
    return val;
  }

  void setup() override {
    this->set_update_interval(60000);
  }

  void loop() override {
  }

  void update() override {
    int val=0;
    int b,len,flag;

    val=getParm(vorlaufSoll,sizeof(vorlaufSoll));
    if (Q1 != nullptr)   Q1->publish_state(val);

    val=getParm(vorlaufIst,sizeof(vorlaufIst));
    if (Q2 != nullptr)   Q2->publish_state(val);

    val=getParm(vorlaufSet,sizeof(vorlaufSet));
    if (T1 != nullptr)   T1->publish_state(val);

    val=getParm(ruecklauf,sizeof(ruecklauf));
    if (T2 != nullptr)   T2->publish_state(val);

  }
};
