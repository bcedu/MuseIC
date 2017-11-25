
import subprocess
import os
print("Warning! This script will delete all the files listed in install_manifest.txt.")
print("It must be run as sudo.")
if input("Do you wish to continue? (y/N)\n") == "y":
    with open("build/install_manifest.txt", "r") as installed_files:
        for installed_file in installed_files.readlines():
            installed_file = installed_file.strip()
            print("Deleting: {0}".format(installed_file))
            try:
                subprocess.call(["rm", installed_file])
            except Exception as e:
                print(e)
    if os.path.exists("build"):
        os.system("rm -r build/*")
    else:
        os.system("mkdir build")
    if os.path.exists("po"):
        os.system("rm -r po/*.po")
