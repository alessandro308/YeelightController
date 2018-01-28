# YeelightController
Control your Xiaomi Yeelight from your OSX Device

<img src="https://image.ibb.co/haW1ww/preview.png" />

## ATTENTION
This app in under refactoring. Every help is accepted. 
The main problems are in the Yeelight.swift file where two JSON sometimes arrives and cause a nil exception (in the file there are more precise comment on this issues).

The new project needs to be integrated with the previous UI.

## How to use
In order to use this app, your YeelightDevice needs to be set in Developer Mode. Use your Yeelight App on your smartphone to change this setting.

### What's new
The new version use another TCP library, the IBM BlueSocket library, imported using Carthage. This improvement helps to implement the discovery mode to find Yeelight in the network (to be done).

