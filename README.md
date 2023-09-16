# TMoteSampleServer
A sample server illustrating how one would add support for the TMote remote control application (available on the iOS App Store here: https://apps.apple.com/us/app/tmote/id1606989131) to a MacOS application. 

TMote protocol makes use of NDI (https://ndi.video/) to deliver video to the TMote app and TUIO (https://www.tuio.org/) to send touches back to the server application. The TMoteSampleServer provided here is not a useful application in itself, it's provided to illustrate how one might implement TMote support in a native MacOS application. A more useful implementation of TMote support has been implemented in Touchdesigner and is available here: https://forum.derivative.ca/t/remote-controlling-touchdesigner-from-ios-devices/239406

To compile, you'll need to download and install the NDI SDK (https://ndi.video/download-ndi-sdk/) and link the project to the NDI library for MacOS.

This sample server displays a window with some sample GUI elements. It publishes an NDI stream of the GUI and can be accessed with any NDI application as long as the "tmote" group is specified. However, to send touch control back, you'll need to download TMote to your iOS device. TMote is currently awaiting app store review as of 8/13/23. Download information will be updated when it's published.
