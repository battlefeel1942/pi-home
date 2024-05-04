def main():

    currentDateAndTime = datetime.datetime.now()
    
    #Heatpump Enabled
    heatpumpMainControlBoolean = hass.states.get('input_boolean.heatpump').state

    # Current State
    hvacMode = hass.states.get('climate.lounge').state
    heatPumpLastChanged = hass.states.get('climate.lounge').last_changed
    loungeAnttributes = hass.states.get('climate.lounge').attributes
    currentTemperature = loungeAnttributes.get('current_temperature')
    targetTemperature = loungeAnttributes.get('temperature')
    currentHumidity = loungeAnttributes.get('current_humidity')
    fanMode = loungeAnttributes.get('fan_mode')
    swingMode = loungeAnttributes.get('swing_mode')
    
    # Optimal settings
    perfectTemperature = hass.states.get('input_select.perfect_temperature').state
    perfectTemperature = float(perfectTemperature)    
    temperatureLimitHigh = perfectTemperature + 1.5
    temperatureLimitLow = perfectTemperature - 1.5
    temperatureDifference = round(abs(currentTemperature - perfectTemperature), 2)
    hoursAllowedWithNoSignal = 1 #1 hour
    hoursAdded = datetime.timedelta(hours = hoursAllowedWithNoSignal) #01:00:00
    resetTime = heatPumpLastChanged + hoursAdded #reset after 1 hour (send off signal)

    # Helpers (indicated by is..)
    isOn = True if hvacMode != 'off' else False
    isOff = True if hvacMode == 'off' else False
    isBelowUpperLimit = True if currentTemperature <= temperatureLimitHigh else False
    isAboveLowerLimit = True if currentTemperature >= temperatureLimitLow else False
    isInPerfectTemperatureRange = True if isBelowUpperLimit and isAboveLowerLimit else False
    # isPerfectConditions = True if isInPerfectTemperatureRange and isPerfectHumidity else False
    isPastResetTime = True if currentDateAndTime.timestamp() > resetTime.timestamp() else False

    if heatpumpMainControlBoolean == "off":
        logger.info("Disabled by master boolean - Exiting")
        return # break out of function - Heatpump will continue from last state

    #Simple time reset. Sometimes the signal from the Sensibo doesnt reach the AC unit
    if isPastResetTime or (isInPerfectTemperatureRange and isOn):
    #if isPastResetTime or isPerfectConditions:
        logger.info("Reset time has past or is perfect timperature - Send turn_off call")
        hass.services.call("climate", "turn_off", {
            "entity_id": "climate.lounge",
        })
        logger.info("climate" + " - " + "turn_off")

    #Setting HVAC mode essentailly turns it on with that mode
    setFanMode = "quiet"
    setSwingMode = "stopped"
    setHvacMode = hvacMode

    if not isInPerfectTemperatureRange:

        # Check if it is too hot
        if not isBelowUpperLimit:
            if hvacMode != "cool":
                #time.sleep(5)
                logger.info("climate" + " - " + "set_hvac_mode" + " - " + "cool")
                hass.services.call("climate", "set_hvac_mode", {
                    "entity_id": "climate.lounge",
                    "hvac_mode": "cool" 
                }) 
                logger.info("Set Mode/Temperature - Mode: cool | Temperature: " + str(temperatureLimitLow))

        # Check if it is too cold
        if not isAboveLowerLimit:  
            if hvacMode != "heat":
                #time.sleep(5)
                logger.info("climate" + " - " + "set_hvac_mode" + " - " + "heat")
                hass.services.call("climate", "set_hvac_mode", {
                    "entity_id": "climate.lounge",
                    "hvac_mode": "heat" 
                }) 
                logger.info("Set Mode/Temperature - Mode: heat | Temperature: " + str(temperatureLimitHigh))
                

        if temperatureDifference > 2: 
            setFanMode = "low"
            setSwingMode = "horizontal"
        
        if temperatureDifference > 3: 
            setFanMode = "medium"
            setSwingMode = "both"

        if temperatureDifference > 4: 
            setFanMode = "high"
            setSwingMode = "rangeFull"

        if fanMode != setFanMode :
            logger.info("climate" + " - " + "fanMode" + " - " + fanMode)
            logger.info("climate" + " - " + "set_fan_mode" + " - " + setFanMode)
            hass.services.call("climate", "set_fan_mode", {
                "entity_id": "climate.lounge",
                "fan_mode": setFanMode 
            })
            logger.info("fanMode != setFanMode | fanMode: " + str(fanMode) + "setFanMode: " + str(setFanMode))
            
        if swingMode != setSwingMode :
            logger.info("climate" + " - " + "swingMode" + " - " + swingMode)
            logger.info("climate" + " - " + "setSwingMode" + " - " + setSwingMode)
            hass.services.call("climate", "set_swing_mode", {
                "entity_id": "climate.lounge",
                "swing_mode": setSwingMode 
            })
            logger.info("swingMode != setSwingMode: " + str(swingMode) + "setSwingMode: " + str(setSwingMode))
        
        if str(round(targetTemperature)) != str(round(perfectTemperature)):
            logger.info("climate" + " - " + "targetTemperature" + " - " + str(targetTemperature))
            logger.info("climate" + " - " + "set_temperature" + " - " + str(perfectTemperature))
            hass.services.call("climate", "set_temperature", {
                "entity_id": "climate.lounge",
                "temperature": round(perfectTemperature)
            })
            logger.info("str(round(targetTemperature)) != str(round(perfectTemperature)): " + str(round(targetTemperature)) + "setSwingMode: " + str(round(perfectTemperature)))

    else: 
        logger.info("Everything is perfect")

main()