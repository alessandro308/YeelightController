# YeelightController
Control your Xiaomi Yeelight from your OSX Device

<img src="https://github.com/alessandro308/YeelightController/blob/master/preview.png" />

## ATTENTION
This app in under refactoring. Every help is accepted. 
The main problems are in the Yeelight.swift file where two JSON sometimes arrives and cause a nil exception (in the file there are more precise comment on this issues).

The new project needs to be integrated with the previous UI.

## How to use
In order to use this app, your YeelightDevice needs to be set in Developer Mode. Use your Yeelight App on your smartphone to change this setting.

### TO DO / BUG
- Contructors on Yeelight Class need to be implemented. Now you need to know Yeelight IP in order to execute this code. Coding a constructor that finds Yeelight in the network without knowing IP.

- Toggle button's title needs to be set after every bulb.proprieties changing. 
