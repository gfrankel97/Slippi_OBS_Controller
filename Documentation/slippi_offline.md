# Using Slippi without Internet Access

## The Need
My Melee scene holds its locals at a college, which has strict network security, meaning we could not use the college network to hook up Slippi. Unacceptable! Slippi is the future and by god, we are going to use it.

## Background
A limitation of the Wii is that it is unable to connect to a network if that network is not connected to the internet. The Wii forces you to run a connection test after selecting a network, and if that connection test fails, the Wii does not let you select that network. This guide provides a workaround.

## Prerequisites
* [Slippi Nintendont Installation in Homebrew](https://slippi.gg/downloads)
* [Slippi Desktop App](https://slippi.gg/downloads)
* [Slippi Dolphin Build](https://slippi.gg/downloads)
  * Version r18 at time of writing
* [Wii Offline Network Enabler in Homebrew](https://wiibrew.org/wiki/Offline_Network_Enabler)
* Router and admin router login
* Wii Sensor Bar and WiiMote :(

## Steps
#### Wii
1) Connect Wii to 2.4GHz network wifi on router using the Wii system settings. Remember the network connection you used (1-3), this will be important later!
     * Many modern routers default to `802.11n` or `802.11n/g/b` wireless mode on the 2.4GHz channel, but the Wii is only capable of using `802.11b` and `802.11g` wireless modes. Most routers will allow you to switch this to a `802.11b/g`, `802.11b`, or `802.11g` only wireless mode, but requires poking around in the router's settings.
     * Example: 
     ![](https://github.com/gfrankel97/Slippi_OBS_Controller/blob/bash/Documentation/images/slippi_network_band.png)
2) Run connection test, which will fail, as expected, since it is not connected to the internet.
3) Exit Settings and load into Homebrew
4) Load Offline Network Enabler
     * ![](https://github.com/gfrankel97/Slippi_OBS_Controller/blob/bash/Documentation/images/offline_enabler_1.JPG)
5) Select `IOS36` by d-pad right or left in the Offline Network Enabler
     * ![](https://github.com/gfrankel97/Slippi_OBS_Controller/blob/bash/Documentation/images/offline_enabler_2.JPG)
6) Hit `A` to reload IOS
     * On white Wiis (from what I've seen) shows an error: `Informing Wii that I am God... Error! Identify as SU failed, press any button to continue`
     * This is fine and does NOT affect the Offline Network Enabler.
7) Recall the network connection number you attempted to connect to earlier and hit `A`, `B`, or `1/Y` accordingly
     * ![](https://github.com/gfrankel97/Slippi_OBS_Controller/blob/bash/Documentation/images/offline_enabler_3.JPG)
8) Upon exiting to Homebrew, the wifi symbol in the bottom-right of Homebrew should blink and then and stay active.
     * Sometimes, this requires a restart of the Wii.
9) Boot Slippi-Nintendont as usual.

#### Slippi Desktop App
10) Connect your computer to the same 2.4GHz network as the Wiis.
    * Most computers will support connecting to multiple networks, so you can still stream and have internet connectivity from one computer.
11)   Connections to the Wii will NOT be discovered by the Slippi Desktop App automatically. For the Wiis you wish to connect to, the local IPs must be manually entered in Slippi Desktop App > Stream From Console > Add Connection
    ![](https://github.com/gfrankel97/Slippi_OBS_Controller/blob/bash/Documentation/images/add_wii_connection_to_slippi_desktop_app.png)
    * Gathering the IPs of the Wiis you wish to connect to can be done in a variety of ways. I prefer `nmap -sn 192.168.1.0/24` for Unix/macOS users, but you can always go back to the router admin page and look for current users/devices.



## Notes
* This workaround works with PriiLoader after the attempt to connect to a network via the System Settings Menu.
