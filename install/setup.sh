#!/bin/bash
#
#  setup.sh - Mycodo install script
#
#  Usage: sudo /bin/bash ~/Mycodo/install/setup.sh
#

INSTALL_DIRECTORY=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd -P )
INSTALL_CMD="/bin/bash ${INSTALL_DIRECTORY}/mycodo/scripts/upgrade_commands.sh"
INSTALL_DEP="/bin/bash ${INSTALL_DIRECTORY}/mycodo/scripts/dependencies.sh"
LOG_LOCATION=${INSTALL_DIRECTORY}/install/setup.log
INSTALL_TYPE="Full"

if [ "$EUID" -ne 0 ]; then
    printf "Please run as root: \"sudo /bin/bash ${INSTALL_DIRECTORY}/install/setup.sh\"\n";
    exit 1
fi

WHIPTAIL=$(command -v whiptail)
exitstatus=$?
if [ $exitstatus != 0 ]; then
    printf "\nwhiptail not installed. Install it with 'sudo apt-get install whiptail' then try the install again.\n"
    exit 1
fi

NOW=$(date)
printf "### Mycodo installation initiated $NOW\n" 2>&1 | tee -a ${LOG_LOCATION}

clear
LICENSE=$(whiptail --title "Mycodo Installer: License Agreement" \
                   --backtitle "Mycodo" \
                   --yesno "Mycodo is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nMycodo is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License along with Mycodo. If not, see gnu.org/licenses\n\nDo you agree to the license terms?" \
                   20 68 \
                   3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus != 0 ]; then
    printf "Mycodo install canceled by user" 2>&1 | tee -a ${LOG_LOCATION}
    exit 1
fi

clear
INSTALL_TYPE=$(whiptail --title "Mycodo Installer: Install Type" \
                        --backtitle "Mycodo" \
                        --notags \
                        --menu "\nSelect the Install Type:\n\nFull: Install all dependencies\nMinimal: Install a minimal set of dependencies\nCustom: Select which dependencies to install\n\nIf unsure, choose 'Full Install'" \
                        20 68 3 \
                        "full" "Full Install (recommended)" \
                        "minimal" "Minimal Install" \
                        "custom" "Custom Install" \
                        3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
    printf "Mycodo install canceled by user" 2>&1 | tee -a ${LOG_LOCATION}
    exit 1
fi
printf "\nInstall Type: $INSTALL_TYPE\n" >>${LOG_LOCATION} 2>&1

if [ "$INSTALL_TYPE" == "custom" ]; then
    clear
    DEP_STATUS=$(whiptail --title "Mycodo Install: Custom" \
                          --backtitle "Mycodo" \
                          --notags \
                          --separate-output \
                          --checklist "Dependencies to Install\n\nScroll down to view more dependencies available to install." \
                          20 68 11 \
                          'Adafruit_ADS1x15' "Adafruit_ADS1x15" off \
                          'Adafruit_BME280' "Adafruit_BME280" off \
                          'Adafruit_BMP' "Adafruit_BMP" off \
                          'Adafruit_CCS811' "Adafruit_CCS811" off \
                          'Adafruit_GPIO' "Adafruit_GPIO" off \
                          'Adafruit_MCP3008' "Adafruit_MCP3008" off \
                          'Adafruit_TMP' "Adafruit_TMP" off \
                          'bluepy' "bluepy" off \
                          'btlewrap' "btlewrap" off \
                          'MCP342x' "MCP342x" off \
                          'miflora' "miflora" off \
                          'numpy' "numpy" off \
                          'pigpio' "pigpio" off \
                          'quick2wire' "quick2wire" off \
                          'rpi_rp' "quick2wire" off \
                          'sht_sensor' "sht_sensor" off \
                          'tsl2561' "tsl2561" off \
                          'tsl2591' "tsl2591" off \
                          'w1thermsensor' "w1thermsensor" off \
                          'wiringpi' "WiringPi" off \
                          3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        printf "Mycodo install canceled by user" 2>&1 | tee -a ${LOG_LOCATION}
        exit 1
    fi
fi

abort()
{
    printf "
**********************************
** ERROR During Mycodo Install! **
**********************************

An error occurred that may have prevented Mycodo from
being installed properly!

Open to the end of the setup log to view the full error:
${INSTALL_DIRECTORY}/install/setup.log

Please contact the developer by submitting a bug report
at https://github.com/kizniche/Mycodo/issues with the
pertinent excerpts from the setup log located at:
${INSTALL_DIRECTORY}/install/setup.log
" 2>&1 | tee -a ${LOG_LOCATION}
    exit 1
}

trap 'abort' 0

set -e

clear
SECONDS=0
NOW=$(date)
printf "#### Mycodo installation began $NOW\n" 2>&1 | tee -a ${LOG_LOCATION}

${INSTALL_CMD} update-swap-size 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} update-apt 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} uninstall-apt-pip 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} update-packages 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} setup-virtualenv 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} update-pip3 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} update-pip3-packages 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} initialize 2>&1 | tee -a ${LOG_LOCATION}

if [ "$INSTALL_TYPE" != "minimal" ]; then
    printf "\n#### Minimal install selected. Skipping extra package installation.\n" 2>&1 | tee -a ${LOG_LOCATION}
elif [ "$INSTALL_TYPE" != "full" ]; then
    printf "\n#### Full install selected. Installing all extra packages.\n" 2>&1 | tee -a ${LOG_LOCATION}
else
    printf "\n#### Custom install selected. Installing custom packages.\n" 2>&1 | tee -a ${LOG_LOCATION}
fi

if [ "$INSTALL_TYPE" == "custom" ]; then
    for dep in $DEP_STATUS
    do
        if [ "$dep" == "Adafruit_ADS1x15" ]; then
            ${INSTALL_DEP} Adafruit_ADS1x15 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "Adafruit_BME280" ]; then
            ${INSTALL_DEP} Adafruit_BME280 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "Adafruit_BMP" ]; then
            ${INSTALL_DEP} Adafruit_BMP 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "Adafruit_CCS811" ]; then
            ${INSTALL_DEP} Adafruit_CCS811 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "Adafruit_GPIO" ]; then
            ${INSTALL_DEP} Adafruit_GPIO 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "Adafruit_MCP3008" ]; then
            ${INSTALL_DEP} Adafruit_MCP3008 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "Adafruit_TMP" ]; then
            ${INSTALL_DEP} Adafruit_TMP 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "bluepy" ]; then
            ${INSTALL_DEP} bluepy 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "btlewrap" ]; then
            ${INSTALL_DEP} btlewrap 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "MCP342x" ]; then
            ${INSTALL_DEP} MCP342x 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "miflora" ]; then
            ${INSTALL_DEP} miflora 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "numpy" ]; then
            ${INSTALL_DEP} numpy 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "pigpio" ]; then
            ${INSTALL_DEP} pigpio 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "quick2wire" ]; then
            ${INSTALL_DEP} quick2wire 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "rpi_rf" ]; then
            ${INSTALL_DEP} rpi_rf 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "sht_sensor" ]; then
            ${INSTALL_DEP} sht_sensor 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "tsl2561" ]; then
            ${INSTALL_DEP} tsl2561 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "tsl2591" ]; then
            ${INSTALL_DEP} tsl2591 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "w1thermsensor" ]; then
            ${INSTALL_DEP} w1thermsensor 2>&1 | tee -a ${LOG_LOCATION}
        elif [ "$dep" == "wiringpi" ]; then
            ${INSTALL_DEP} wiringpi 2>&1 | tee -a ${LOG_LOCATION}
        fi
    done
    ${INSTALL_CMD} update-permissions 2>&1 | tee -a ${LOG_LOCATION}
elif [ "$INSTALL_TYPE" == "full" ]; then
    ${INSTALL_DEP} Adafruit_ADS1x15 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} Adafruit_BMP 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} Adafruit_CCS811 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} Adafruit_Python_BME280 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} Adafruit_GPIO 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} Adafruit_MCP3008 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} Adafruit_TMP 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} bluepy 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} btlewrap 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} MCP342x 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} miflora 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} numpy 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} pigpio 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} quick2wire 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} rpi_rf 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} sht_sensor 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} tsl2561 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} tsl2591 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} w1thermsensor 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_DEP} wiringpi 2>&1 | tee -a ${LOG_LOCATION}
    ${INSTALL_CMD} update-permissions 2>&1 | tee -a ${LOG_LOCATION}
elif [ "$INSTALL_TYPE" == "minimum" ]; then
    ${INSTALL_CMD} enable-pigpiod-uninstalled
fi

${INSTALL_CMD} update-influxdb 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} update-influxdb-db-user 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} update-logrotate 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} ssl-certs-generate 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} update-mycodo-startup-script 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} compile-translations 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} update-cron 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} initialize 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} web-server-update 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} web-server-restart 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} web-server-connect 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} update-permissions 2>&1 | tee -a ${LOG_LOCATION}
${INSTALL_CMD} restart-daemon 2>&1 | tee -a ${LOG_LOCATION}

trap : 0

IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

if [[ -z ${IP} ]]; then
  IP="your.IP.address.here"
fi

CURRENT_DATE=$(date)
printf "#### Mycodo Installer finished ${CURRENT_DATE}\n" 2>&1 | tee -a ${LOG_LOCATION}

DURATION=$SECONDS
printf "#### Total install time: $(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds\n" 2>&1 | tee -a ${LOG_LOCATION}

printf "
************************************
** Mycodo successfully installed! **
************************************

The full install log is located at:
${INSTALL_DIRECTORY}/install/setup.log

Go to https://${IP}/, or whatever your Raspberry Pi's
IP address is, to create an admin user and log in.
" 2>&1 | tee -a ${LOG_LOCATION}
