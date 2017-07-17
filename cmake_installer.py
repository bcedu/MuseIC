import os

print("Warning! This script will delete all the files in folder build and all *.po files in po folder")
print("It must be run as sudo.")
if input("Do you wish to continue? (y/N)\n") == "y":
    try:
        if os.path.exists("build"):
            os.system("rm -r build/*")
        else:
            os.system("mkdir build")
        if os.path.exists("po"):
            os.system("rm -r po/*.po")
        os.system("cd build && cmake -DCMAKE_INSTALL_PREFIX=/usr ../ && make && make pot && make install")
    except Exception as e:
        print(e)
