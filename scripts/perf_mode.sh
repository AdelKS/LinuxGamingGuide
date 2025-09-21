#!/bin/bash

card=$(ls -d /sys/class/drm/card?/)

# enable manual power profile; not needed for pp_power_profile_mode
#echo low > "${card}device/power_dpm_force_performance_level"

# set power cap, not really needed
#echo 320000000 > "${card}device/hwmon/hwmon2/power1_cap"

# set power profile (POWER_SAVING/3D_FULL_SCREEN
## POWER_SAVING has slightly more power usage (+2W) than 3D_FULL_SCREEN oO
if [[ $1 == "high" ]]; then
    sysctl kernel.split_lock_mitigate=0
    echo "high" > "${card}device/power_dpm_force_performance_level"

    # 1 is 3D_FULL_SCREEN
    #echo 1 > "${card}device/pp_power_profile_mode"
    # voltage offset (+ or -)
    #echo "vo 0" > /sys/class/drm/card0/device/pp_od_clk_voltage
else
    sysctl kernel.split_lock_mitigate=1
    echo "low" > "${card}device/power_dpm_force_performance_level"
    # 2 is POWER_SAVING
    #echo 2 > "${card}device/pp_power_profile_mode"
    # voltage offset (+ or -)
    #echo "vo -100" > /sys/class/drm/card0/device/pp_od_clk_voltage
fi

# commit undervolting changes
#echo "c" > "${card}device/pp_od_clk_voltage"
