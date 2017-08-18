# project name
project (com.github.bcedu.MuseIC)

# the oldest stable cmake version we support
cmake_minimum_required (VERSION 2.6)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/src)

# where we install data directory (if we have any)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
# what to call that directory where we install data too
set (PKGDATADIR "${DATADIR}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}")
add_definitions (-DGETTEXT_PACKAGE="${GETTEXT_PACKAGE}")

set (EXEC_NAME "com.github.bcedu.MuseIC")
set (RELEASE_NAME "MuseIC")
set (VERSION "0.5.1")
set (VERSION_INFO "MuseIC first version")

configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED gtk+-3.0 gio-2.0 gmodule-2.0 gstreamer-1.0)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.16" MINIMUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/museic.vala
    src/museic_gui.vala
    src/museic_streamplayer.vala
    src/museic_filelist.vala
    src/museic_file.vala
    src/museic_library.vala
    src/museic_dbus.vala
    src/config.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    gio-2.0
    gmodule-2.0
    gstreamer-1.0
    dbus-glib-1
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# install our .desktop file so the Applications menu will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.bcedu.MuseIC.desktop DESTINATION ${DATADIR}/applications/)

# install our .appdata.xml file so AppCenter will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.bcedu.MuseIC.appdata.xml DESTINATION ${DATADIR}/metainfo/)

# Translation files
add_subdirectory (po)

# Install data
INSTALL(FILES data/museic_window.glade DESTINATION ${PKGDATADIR}/data)
INSTALL(FILES data/icons/museic-icon.svg DESTINATION ${PKGDATADIR}/data/icons)
# Install icons
install(FILES data/icons/museic-icon.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/)
install(FILES data/icons/museic-icon.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/32x32/apps/)
install(FILES data/icons/museic-icon.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/48x48/apps/)
install(FILES data/icons/museic-icon.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/64x64/apps/)
install(FILES data/icons/museic-icon.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/128x128/apps/)
install(FILES data/icons/museic-icon.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/256x256/apps/)
