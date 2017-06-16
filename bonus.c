#include "Arduino.h"

int glob_a;
int glob_b;

void setup() {
  pinMode(13, OUTPUT);
}

int add(int a) {
  int b = 2000;
  glob_a = glob_a + 1000;
  glob_b = glob_a + 2000;
  if(glob_a == 8000)
  {
    glob_a = a;
  }
  return b;
}

void loop() {
  int a = 1000;
  int b;
  b = add(a);
  digitalWrite(13, HIGH);
  delay(glob_a);
  digitalWrite(13, LOW);
  delay(glob_b);
}
