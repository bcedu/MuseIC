# MuseIC


MuseIC is a fast and simple music player with remote control from any device through internet browser.

- Play music files and add them to music library
- Connect to the address given by MuseIC and control the media from any device (mobile phone, tablet, etc.) with a web browser
- Sort by name, artis and album (it handles ID3 metadata tags)

![MuseIC Screenshoot](/data/museic_screenshoot.png)

Any resemblance between the name and some awesome music band is pure coincidence.

## Installation

### Elementary App Store

Download MuseIC through the elementary app store. It's always updated to lastest version.
Easy and fast.

### Manual Instalation

Download last release (zip file), extract files and enter to the folder where they where extracted.

Install your application with the following commands:
- mkdir build
- cd build
- cmake -DCMAKE_INSTALL_PREFIX=/usr ../
- make
- sudo make install

Or you can just use the python script I made (must be run as sudo):
- sudo python3.5 cmake_installer.py

DO NOT DELETE FILES AFTER MANUAL INSTALLATION, THEY ARE NEEDED DURING UNINSTALL PROCESS

## Uninstall

### Elementary App Store

Just go to store and click on uninstall :)

### Manual Uninstall

To uninstall your application, run the script "cmake_uninstaller.py" (in the folder where files where originally extracted for manual installation).

It must be run as sudo:
- sudo python3.5 cmake_uninstaller.py
