#!/bin/bash
if [ -e museic ]
then
  echo "Removing old 'museic'"
  rm museic
fi
valac src/*.vala --pkg=gtk+-3.0 --pkg=gio-2.0 --pkg=gmodule-2.0 --pkg=gstreamer-1.0 --pkg=dbus-glib-1 --pkg=granite -o museic
if [ -e museic ]
then
  echo "####################################"
  echo "      Successfully complied!!      "
  echo "####################################"
  ./museic
else
  echo "------------------------------------"
  echo "       Compilation failed...        "
  echo "------------------------------------"
fi
