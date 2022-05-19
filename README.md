# SDK Container

Use SDK container features.

## Use SDK container and create intermedidate SDK lib container

Start by creating SDK container in Studio.

Setup docker on local machine and login to the Studio device registry.

The example scripts require *studio-cli* to be installed on local machine when uploading new containers.

Clone your favorite project based on cmake.
```bash
git clone git@github.com:ondsaft/factory.git
```

Build the library called *machines* and create a new SDK container with the library. Set the *1.1* tag on the new container and upload it to Studio device registry.
```bash
./sdk_container.sh -p /home/tholmber/factory/machines -t machines -n th-sdk2:1.1 -s th-sdk2:latest
```

Use the SDK container with the *machines* library and buld the complete factory application which depends on the library. The factory application is built in local directory (outside container). In this example */home/tholmber/mybuild*.
```bash
mkdir /home/tholmber/mybuild
./sdk_container.sh -p /home/tholmber/factory -t factory -b /home/tholmber/mybuild -s th-sdk2:1.1
```

Run the example binary to see if it worked.
```bash
/home/tholmber/mybuild/apps/factory 
Hello factory!
Factory version 1.0
```