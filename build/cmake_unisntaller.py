
    import subprocess
    print("Warning! This script will delete all the files listed in install_manifest.txt.")
    print("It must be run as sudo.
")
    if input("Do you wish to continue? (y/N)") == "y":
        with open("install_manifest.txt", "r") as installed_files:
            for installed_file in installed_files.readlines():
                installed_file = installed_file.strip()
                print("Deleting: {0}".format(installed_file))
                try:
                    subprocess.call(["rm", installed_file])
                except Exception as e:
                    print(e)
    