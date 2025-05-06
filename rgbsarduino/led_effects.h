// #ifndef LED_EFFECTS_H
// #define LED_EFFECTS_H

// #include <Adafruit_NeoPixel.h>
// #include "config.h"
// // Global timing variables for non-blocking operations
// unsigned long previousMillis = 0;
// unsigned long previousEffectMillis = 0;
// unsigned long previousBreathMillis = 0;
// unsigned long previousChaseMillis = 0;
// unsigned long previousStrobeMillis = 0;
// unsigned long previousColorChangeMillis = 0;

// // State variables for effects
// int breathBrightness = 0;
// bool breathDirection = true; // true for increasing brightness, false for decreasing
// int chasePosition = 0;
// bool strobeState = false;
// int transitionStep = 0;
// uint32_t currentRandomColor = 0;
// uint32_t nextRandomColor = 0;
// int rainDropPosition = -1;
// bool rainDropDirection = true;
// int rainDropIteration = 0;
// uint8_t hueRotation = 0;

// void tatDen();
// void rotatingColors(int wait);
// void nhipDap(int speed);
// void nhipDapWithColor(int speed);
// void nuocChay(uint32_t color, int wait);
// void muaRoi(int speed, int iterations);
// void randomBlink(int wait);
// void strobeEffect(uint32_t color, int wait);
// void chaseEffect(uint32_t color, int wait);
// void singleColor(uint32_t color);
// void randomColors(int wait);
// void smoothRandomColors(int wait);
// uint32_t Wheel(byte WheelPos);

// void resetEffectStates() {
//     breathBrightness = 0;
//     breathDirection = true;
//     chasePosition = 0;
//     strobeState = false;
//     transitionStep = 0;
//     rainDropPosition = -1;
//     rainDropDirection = true;
//     rainDropIteration = 0;
    
//     // Initialize with a random color
//     currentRandomColor = pixels.Color(random(255), random(255), random(255));
//     nextRandomColor = pixels.Color(random(255), random(255), random(255));
// }

// void executeLEDEffects() {
//     // Reset all effect states when effect changes
//     static int lastEffect = -1;
//     if (currentEffect != lastEffect) {
//         resetEffectStates();
//         lastEffect = currentEffect;
//     }
    
//     switch (currentEffect) {
//         case 0:
//             tatDen();
//             break;
//         case 1:
//             pixels.setBrightness(brightness);
//             rotatingColors(speed / 5);
//             break;
//         case 2:
//             pixels.setBrightness(brightness);
//             nhipDap(speed / 10);
//             break;
//         case 3:
//             pixels.setBrightness(brightness);
//             nhipDapWithColor(speed / 10);
//             break;
//         case 4:
//             pixels.setBrightness(brightness);
//             nuocChay(selectedColor, speed);
//             break;
//         case 5:
//             pixels.setBrightness(brightness);
//             muaRoi(speed, 3);
//             break;
//         case 6:
//             pixels.setBrightness(brightness);
//             randomBlink(speed);
//             break;
//         case 7:
//             pixels.setBrightness(brightness);
//             strobeEffect(selectedColor, speed);
//             break;
//         case 8:
//             pixels.setBrightness(brightness);
//             chaseEffect(selectedColor, speed);
//             break;
//         case 9:
//             pixels.setBrightness(brightness);
//             singleColor(selectedColor);
//             break;
//         case 10:
//             pixels.setBrightness(brightness);
//             randomColors(speed);
//             break;
//         case 11:
//             pixels.setBrightness(brightness);
//             smoothRandomColors(speed);
//             break;
//     }
// }

// void nuocChay(uint32_t color, int wait) {
//     unsigned long currentMillis = millis();
    
//     if (currentMillis - previousMillis >= wait) {
//         previousMillis = currentMillis;
        
//         static int position = 0;
//         static bool isLighting = true;
        
//         if (isLighting) {
//             if (position < pixels.numPixels()) {
//                 pixels.setPixelColor(pixels.numPixels() - position - 1, color);
//                 pixels.show();
//                 position++;
//             } else {
//                 position = 0;
//                 isLighting = false;
//             }
//         } else {
//             if (position < pixels.numPixels()) {
//                 pixels.setPixelColor(pixels.numPixels() - position - 1, 0);
//                 pixels.show();
//                 position++;
//             } else {
//                 position = 0;
//                 isLighting = true;
//             }
//         }
//     }
// }

// void muaRoi(int speed, int iterations) {
//     unsigned long currentMillis = millis();
    
//     if (currentMillis - previousMillis >= speed) {
//         previousMillis = currentMillis;
        
//         // Clear the previous drop
//         if (rainDropPosition >= 0 && rainDropPosition < NUMPIXELS) {
//             pixels.setPixelColor(rainDropPosition, pixels.Color(0, 0, 0));
//         }
        
//         if (rainDropDirection) {
//             // Moving down
//             rainDropPosition++;
//             if (rainDropPosition >= NUMPIXELS) {
//                 rainDropPosition = NUMPIXELS - 1;
//                 rainDropDirection = false;
//             }
//         } else {
//             // Moving up
//             rainDropPosition--;
//             if (rainDropPosition < 0) {
//                 rainDropIteration++;
//                 if (rainDropIteration >= iterations * 2) { // *2 because we have up and down movements
//                     rainDropIteration = 0;
//                 }
//                 rainDropPosition = 0;
//                 rainDropDirection = true;
//             }
//         }
        
//         // Set the new drop with random color
//         if (rainDropPosition >= 0 && rainDropPosition < NUMPIXELS) {
//             int rgb1 = random(255);
//             int rgb2 = random(255);
//             int rgb3 = random(255);
//             pixels.setPixelColor(rainDropPosition, pixels.Color(rgb1, rgb2, rgb3));
//         }
        
//         pixels.show();
//     }
// }

// void nhipDap(int speed) {
//     unsigned long currentMillis = millis();
    
//     if (currentMillis - previousBreathMillis >= speed) {
//         previousBreathMillis = currentMillis;
        
//         if (breathDirection) {
//             breathBrightness++;
//             if (breathBrightness >= 255) {
//                 breathDirection = false;
//             }
//         } else {
//             breathBrightness--;
//             if (breathBrightness <= 0) {
//                 breathDirection = true;
//                 // Generate new random color when we reach zero brightness
//                 int rgb1 = random(255);
//                 int rgb2 = random(255);
//                 int rgb3 = random(255);
//                 uint32_t color = pixels.Color(rgb1, rgb2, rgb3);
//                 pixels.fill(color, 0, NUMPIXELS);
//             }
//         }
        
//         pixels.setBrightness(breathBrightness);
//         pixels.show();
//     }
// }

// void nhipDapWithColor(int speed) {
//     unsigned long currentMillis = millis();
    
//     if (currentMillis - previousBreathMillis >= speed) {
//         previousBreathMillis = currentMillis;
        
//         if (breathDirection) {
//             breathBrightness++;
//             if (breathBrightness >= 255) {
//                 breathDirection = false;
//             }
//         } else {
//             breathBrightness--;
//             if (breathBrightness <= 0) {
//                 breathDirection = true;
//                 // Use the selected color
//                 pixels.fill(selectedColor, 0, NUMPIXELS);
//             }
//         }
        
//         pixels.setBrightness(breathBrightness);
//         pixels.show();
//     }
// }

// void tatDen() {
//     static bool alreadyCleared = false;
    
//     if (!alreadyCleared) {
//         pixels.clear();
//         pixels.show();
//         alreadyCleared = true;
//     }
    
//     // When we change to a different effect, set it back to false
//     if (currentEffect != 0) {
//         alreadyCleared = false;
//     }
// }

// void rotatingColors(int wait) {
//     unsigned long currentMillis = millis();
    
//     if (currentMillis - previousMillis >= wait) {
//         previousMillis = currentMillis;
        
//         for (int i = 0; i < pixels.numPixels(); i++) {
//             pixels.setPixelColor(i, Wheel((hueRotation + i * 256 / pixels.numPixels()) & 255));
//         }
//         pixels.show();
//         hueRotation++;
//     }
// }

// void randomBlink(int wait) {
//     unsigned long currentMillis = millis();
    
//     if (currentMillis - previousMillis >= wait) {
//         previousMillis = currentMillis;
        
//         static bool isOn = false;
        
//         if (isOn) {
//             pixels.clear();
//             isOn = false;
//         } else {
//             for (int i = 0; i < pixels.numPixels(); i++) {
//                 pixels.setPixelColor(i, pixels.Color(random(255), random(255), random(255)));
//             }
//             isOn = true;
//         }
        
//         pixels.show();
//     }
// }

// void chaseEffect(uint32_t color, int wait) {
//     unsigned long currentMillis = millis();
    
//     if (currentMillis - previousChaseMillis >= wait) {
//         previousChaseMillis = currentMillis;
        
//         // Clear the previous position
//         pixels.setPixelColor(chasePosition, 0);
        
//         // Move to the next position
//         chasePosition = (chasePosition + 1) % pixels.numPixels();
        
//         // Set the new position
//         pixels.setPixelColor(chasePosition, color);
//         pixels.show();
//     }
// }

// void strobeEffect(uint32_t color, int wait) {
//     unsigned long currentMillis = millis();
    
//     if (currentMillis - previousStrobeMillis >= wait) {
//         previousStrobeMillis = currentMillis;
        
//         if (strobeState) {
//             pixels.clear();
//         } else {
//             pixels.fill(color, 0, NUMPIXELS);
//         }
        
//         pixels.show();
//         strobeState = !strobeState;
//     }
// }

// void singleColor(uint32_t color) {
//     static uint32_t lastColor = 0;
    
//     // Only update if the color has changed
//     if (color != lastColor) {
//         for (int i = 0; i < NUMPIXELS; i++) {
//             pixels.setPixelColor(i, color);
//         }
//         pixels.show();
//         lastColor = color;
//     }
// }

// void randomColors(int wait) {
//     unsigned long currentMillis = millis();
    
//     if (currentMillis - previousColorChangeMillis >= wait) {
//         previousColorChangeMillis = currentMillis;
        
//         uint32_t color = pixels.Color(random(255), random(255), random(255));
//         for (int i = 0; i < NUMPIXELS; i++) {
//             pixels.setPixelColor(i, color);
//         }
//         pixels.show();
//     }
// }

// void smoothRandomColors(int wait) {
//     unsigned long currentMillis = millis();
//     int transitionDuration = 5000; // Total time to transition between colors (in ms)
//     int steps = 256; // Number of steps in the transition
//     int stepDelay = transitionDuration / steps; // Time for each step
    
//     if (currentMillis - previousColorChangeMillis >= stepDelay) {
//         previousColorChangeMillis = currentMillis;
        
//         if (transitionStep >= steps) {
//             // Transition complete, setup for next transition
//             currentRandomColor = nextRandomColor;
//             nextRandomColor = pixels.Color(random(255), random(255), random(255));
//             transitionStep = 0;
//         }
        
//         // Calculate interpolated color
//         uint8_t r = ((uint8_t)(currentRandomColor >> 16) * (steps - transitionStep) + 
//                      (uint8_t)(nextRandomColor >> 16) * transitionStep) / steps;
//         uint8_t g = ((uint8_t)(currentRandomColor >> 8) * (steps - transitionStep) + 
//                      (uint8_t)(nextRandomColor >> 8) * transitionStep) / steps;
//         uint8_t b = ((uint8_t)(currentRandomColor) * (steps - transitionStep) + 
//                      (uint8_t)(nextRandomColor) * transitionStep) / steps;
        
//         uint32_t color = pixels.Color(r, g, b);
        
//         for (int i = 0; i < NUMPIXELS; i++) {
//             pixels.setPixelColor(i, color);
//         }
//         pixels.show();
        
//         transitionStep++;
//     }
// }

// uint32_t Wheel(byte WheelPos) {
//     WheelPos = 255 - WheelPos;
//     if (WheelPos < 85) {
//         return pixels.Color(255 - WheelPos * 3, 0, WheelPos * 3);
//     }
//     if (WheelPos < 170) {
//         WheelPos -= 85;
//         return pixels.Color(0, WheelPos * 3, 255 - WheelPos * 3);
//     }
//     WheelPos -= 170;
//     return pixels.Color(WheelPos * 3, 255 - WheelPos * 3, 0);
// }

// // Function to release RMT resources when LEDs are not in use
// void releaseNeoPixelResources() {
//     tatDen(); // Turn off all LEDs
//     // rmt_channel_t channel = (rmt_channel_t)(pixels.getPin()); // Get the RMT channel used by NeoPixel
//     // rmt_driver_uninstall(channel); // Uninstall the RMT driver
// }

// // Function to reinitialize NeoPixel when needed again
// void reinitNeoPixel() {
//     pixels.begin();
//     pixels.setBrightness(brightness);
// }

// #endif