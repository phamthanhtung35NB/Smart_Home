#ifndef NTP_CLIENT_H
#define NTP_CLIENT_H

#include <NTPClient.h>
#include "config.h"

void initTimeClient() {
    timeClient.begin();
    timeClient.setTimeOffset(25200);
    timeClient.forceUpdate();
}

#endif