#ifndef LED_EFFECTS_H
#define LED_EFFECTS_H

#include <Adafruit_NeoPixel.h>
#include "config.h"

void tatDen();  // Declare tatDen function
void rotatingColors(int wait);  // Declare rotatingColors function
void nhipDap(int speed);  // Declare nhipDap function
void nhipDapWithColor(int speed);  // Declare nhipDapWithColor function
void nuocChay(uint32_t color, int wait);  // Declare nuocChay function
void muaRoi(int speed, int iterations);  // Declare muaRoi function
void randomBlink(int wait);  // Declare randomBlink function
void strobeEffect(uint32_t color, int wait);  // Declare strobeEffect function
void chaseEffect(uint32_t color, int wait);  // Declare chaseEffect function
void singleColor(uint32_t color);  // Declare singleColor function
void randomColors(int wait);  // Declare randomColors function
void smoothRandomColors(int wait);  // Declare smoothRandomColors function
uint32_t Wheel(byte WheelPos);  // Declare Wheel function

void executeLEDEffects() {
    switch (currentEffect) {
        case 0:
            tatDen();
            break;
        case 1:
            pixels.setBrightness(brightness);
            rotatingColors(speed / 5);
            break;
        case 2:
            pixels.setBrightness(brightness);
            nhipDap(speed / 10);
            break;
        case 3:
            pixels.setBrightness(brightness);
            nhipDapWithColor(speed / 10);
            break;
        case 4:
            pixels.setBrightness(brightness);
            nuocChay(selectedColor, speed);
            break;
        case 5:
            pixels.setBrightness(brightness);
            muaRoi(speed, 3);
            break;
        case 6:
            pixels.setBrightness(brightness);
            randomBlink(speed);
            break;
        case 7:
            pixels.setBrightness(brightness);
            strobeEffect(selectedColor, speed);
            break;
        case 8:
            pixels.setBrightness(brightness);
            chaseEffect(selectedColor, speed);
            break;
        case 9:
            pixels.setBrightness(brightness);
            singleColor(selectedColor);
            break;
        case 10:
            pixels.setBrightness(brightness);
            randomColors(speed);
            break;
        case 11:
            pixels.setBrightness(brightness);
            smoothRandomColors(speed);
            break;
    }
    pixels.setBrightness(brightness);
}

void nuocChay(uint32_t color, int wait) {
    for (int i = pixels.numPixels(); i >= 0; i--) {
        pixels.setPixelColor(i, color);
        pixels.show();
        delay(wait);
    }
    for (int i = pixels.numPixels(); i >= 0; i--) {
        pixels.setPixelColor(i, 0);
        pixels.show();
        delay(wait);
    }
}

void muaRoi(int speed, int iterations) {
    for (int iter = 0; iter < iterations; iter++) {
        for (int i = NUMPIXELS - 1; i >= 0; i--) {
            int rgb1 = random(255);
            int rgb2 = random(255);
            int rgb3 = random(255);

            pixels.setPixelColor(i, pixels.Color(rgb1, rgb2, rgb3));
            pixels.show();
            delay(speed);

            pixels.setPixelColor(i, pixels.Color(0, 0, 0));
        }

        for (int i = 0; i < NUMPIXELS; i++) {
            int rgb1 = random(255);
            int rgb2 = random(255);
            int rgb3 = random(255);

            pixels.setPixelColor(i, pixels.Color(rgb1, rgb2, rgb3));
            pixels.show();
            delay(speed);

            pixels.setPixelColor(i, pixels.Color(0, 0, 0));
        }
    }
}

void nhipDap(int speed) {
    int rgb1 = random(255);
    int rgb2 = random(255);
    int rgb3 = random(255);
    uint32_t color = pixels.Color(rgb1, rgb2, rgb3);

    for (int j = 0; j < 255; j++) {
        pixels.fill(color, 0, NUMPIXELS);
        pixels.setBrightness(j);
        pixels.show();
        delay(speed);
    }

    for (int j = 255; j >= 0; j--) {
        pixels.fill(color, 0, NUMPIXELS);
        pixels.setBrightness(j);
        pixels.show();
        delay(speed);
    }
}

void nhipDapWithColor(int speed) {
    for (int j = 0; j < 255; j++) {
        pixels.fill(selectedColor, 0, NUMPIXELS);
        pixels.setBrightness(j);
        pixels.show();
        delay(speed);
    }

    for (int j = 255; j >= 0; j--) {
        pixels.fill(selectedColor, 0, NUMPIXELS);
        pixels.setBrightness(j);
        pixels.show();
        delay(speed);
    }
}

void tatDen() {
    pixels.clear();
    pixels.show();
}

void rotatingColors(int wait) {
    static uint8_t hue = 0;
    for (int i = 0; i < pixels.numPixels(); i++) {
        pixels.setPixelColor(i, Wheel((hue + i * 256 / pixels.numPixels()) & 255));
    }
    pixels.show();
    hue++;
    delay(wait);
}

void randomBlink(int wait) {
    for (int i = 0; i < pixels.numPixels(); i++) {
        pixels.setPixelColor(i, pixels.Color(random(255), random(255), random(255)));
    }
    pixels.show();
    delay(wait);
    pixels.clear();
    pixels.show();
    delay(wait);
}

void chaseEffect(uint32_t color, int wait) {
    for (int i = 0; i < pixels.numPixels(); i++) {
        pixels.setPixelColor(i, color);
        pixels.show();
        delay(wait);
        pixels.setPixelColor(i, 0);
    }
}

void strobeEffect(uint32_t color, int wait) {
    pixels.fill(color, 0, NUMPIXELS);
    pixels.show();
    delay(wait);
    pixels.clear();
    pixels.show();
    delay(wait);
}

void singleColor(uint32_t color) {
    for (int i = 0; i < NUMPIXELS; i++) {
        pixels.setPixelColor(i, color);
    }
    pixels.show();
}

void randomColors(int wait) {
    uint32_t colllor = pixels.Color(random(255), random(255), random(255));
    for (int i = 0; i < NUMPIXELS; i++) {
        pixels.setPixelColor(i, colllor);
    }
    pixels.show();
    delay(wait);
}

void smoothRandomColors(int wait) {
    uint32_t currentColor = pixels.Color(random(255), random(255), random(255));
    uint32_t nextColor = pixels.Color(random(255), random(255), random(255));

    for (int j = 0; j < 256; j++) {
        uint8_t r =
                ((uint8_t)(currentColor >> 16) * (255 - j) + (uint8_t)(nextColor >> 16) * j) / 255;
        uint8_t g =
                ((uint8_t)(currentColor >> 8) * (255 - j) + (uint8_t)(nextColor >> 8) * j) / 255;
        uint8_t b = ((uint8_t)(currentColor) * (255 - j) + (uint8_t)(nextColor) * j) / 255;
        uint32_t color = pixels.Color(r, g, b);

        for (int i = 0; i < NUMPIXELS; i++) {
            pixels.setPixelColor(i, color);
        }
        pixels.show();
        delay(wait / 256);
    }
}

uint32_t Wheel(byte WheelPos) {
    WheelPos = 255 - WheelPos;
    if (WheelPos < 85) {
        return pixels.Color(255 - WheelPos * 3, 0, WheelPos * 3);
    }
    if (WheelPos < 170) {
        WheelPos -= 85;
        return pixels.Color(0, WheelPos * 3, 255 - WheelPos * 3);
    }
    WheelPos -= 170;
    return pixels.Color(WheelPos * 3, 255 - WheelPos * 3, 0);
}

#endif