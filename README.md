# MuseIC
Simple audio player made with Vala to learn Vala and how elementary OS (and other linux distros) apps are made. 

Any resemblance between the name and some awesome music band is pure coincidence.


## Installation

Install your application with the following commands:
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr ../
    make
    sudo make install

And to enable translations:
    cmake -DCMAKE_INSTALL_PREFIX=/usr ../
    make pot

Or you can just use the python script I made (must be run as sudo):
    sudo python3.5 cmake_installer.py


## Uninstall

To uninstall your application, run the script "cmake_uninstaller.py".
It must be run as sudo:
    sudo python cmake_uninstaller.py
