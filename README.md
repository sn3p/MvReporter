# Mavericks IRC Reporter for UT99

- [Introduction](#introduction)
- [Changelog](#changelog)
- [Installation](#installation)
- [Configuration](#configuration)
- [Config Explanation](#config-explanation)
- [UTGL](#utgl-ut-global-login-system)
- [Webadmin](#webadmin)
- [Commands](#commands)
- [Notes](#notes)


## Introduction

Mavericks IRC Reporter is an Unreal Tournament 99 Server Actor, which connects to an IRC Server defined by an admin and posts messages from the game into the channel. This lets people follow any game without being on the server themselves.

Note that many IRC networks only allow a certain number of connections from a single host. (Which are called "Clones".) Average networks only allow up to 5 of these "Clones" before applying what is called a G-Line. Some networks do not allow bots, so be sure to check the IRC Network's AUP, TOS, or MOTD first.

Side note: 3.0.1 changes only the webadmin, the images folder is now mvrimg. You'll need to add an additional 2 lines to your servers ini.


## Changelog

### 3.0.1:

- Attempted fix of webadmin.

### 3.0 final:

- Added Idents.
- Added an inviteme option. (Untested)
- Added Quakenet info.
- Added censor. (irc only)
- Added enhanced sprees.
- Added show begin/end sprees.
- Added option to not show EUT's MMI's.
- Added shout blocking. (all lowercase text)
- Added default kills. (hotfix for eut)
- Added Srvx Chanserv info.
- Added 3 new performs.
- Added message delays to ini.
- Changed perform. (1-3 before join, 4-6 after join)
- Removed Quakenet auth.
- Updated readme.

### 3.0 rev2 (nrc):

- Fixed server ad message to not show ip address.
- Fixed irc setting bug (public say/extra 1on1 info unset).
- Added EUT gametypes (EUT_1G).
- Added +x on connect option.
- Added editable ad message.
- Added bot pm commands for ad message / +x.
- Added Webadmin options for ad message / +x.
- Moved perform before channel join.
- Updated default server.
- Updated readme.

### 3.0 rev1 (nrc):

- Fixed 2 webadmin bugs. (options wouldn't set.)
- Fixed a typo.. :x
- Added srvx auth configuration.
- Added bindable triggers.
- Added new bot pm commands for binds/srvx.
- Added +h support. (half-op)
- Added readme.

### 2.0 beta2:

- Fixed few bugs.
- Added PublicSay feature.

### 2.0 beta1:

- First release.


## Installation

Mavericks IRC Reporter comes with the following files:

**`README.md`** - Readme, this file.  
**`System/MvReporterXR3_Gambino.u`** - The main actor package.  
**`System/MvReporterXR3_Gambino.int`** - Data file.  
**`Web/mvr/*.uhtm`** - Webadmin files.  
**`Web/mvrimg/*.jpg|*.gif`** - Webadmin images.  

### Installation for the most part, is easy..

1. Add the mutator's class to the ServerActors (not ServerPackages!) list in the `[Engine.GameEngine]` section in UnrealTournament.ini (or whatever ini file you/your host has).  
This should go after or at the end of the list of serveractors.
```ini
ServerActors=MvReporterXR3_Gambino.MvReporter
```

2. Add the following 4 lines in the `[UWeb.WebServer]` section in UnrealTournament.ini
```ini
Applications[3]=MvReporterXR3_Gambino.MvReporterAdmin
ApplicationPaths[3]=/mvr
Applications[4]=MvReporterXR3_Gambino.MvReporterImage
ApplicationPaths[4]=/mvrimg
```

**Note:** The numbers within the brackets may vary due to the number of webapplications already installed. Adjust it as needed.

3. Copy the contents of the "System" directory to the "System" directory on your UT Server.  
(Do not upload the system folder INTO the system folder, only the contents!) (`*.u|*.int`).  

4. Copy the contents of the "Web" directory to the "Web" directory on your UT Server.  
(Do not upload the web folder INTO the web folder, only the contents!) (`*.uhtm|*.jpg|*.gif`)  
After, double check that the files and folders exist are are in the correct locations.

This bot doesn't have to be added to the ServerPackages list. In fact, I recommend not adding it in case a client for some reason has a different version. (Even though my releases have different names, other versions of MvR may not) Also note, that it may appear in mutators listing. It is not recommended to try and disable or remove it from that list.


## Configuration

This bot is almost fully configurable from it's custom webadmin interface.
The entire configuration is stored in your UnrealTournament.ini file. Most of the options can be found in the section `[MvReporterXR3.MvReporter]`.

Place this at the **END** of your UnrealTournament.ini:

```ini
[MvReporterXR3.MvReporterConfig]
bEnabled=True
bDebug=False
bMuted=False
bPublicComs=True
bPublicSay=True
bAdvertise=True
bSecondaryLink=False
bExtra1on1Stats=False
bUseLogin=False
bUseSrvx=False
bUseTBind=False
bModeX=False
jUseIdent=False
nInviteMe=False
nQuakenet=False
xModeM=False
xCensorText=False
xEnhancedSprees=False
xReportSprees=False
xReportBSprees=False
xReportESprees=False
xReportMMI=False
xAllowShouting=False
xDefaultKills=False
AdMessage=This match is being broadcasted live to #RF on irc.GameRadius.org
AdminPassword=admin
ServerAddr=irc.GameRadius.org
ServerPort=6667
Channel=#Rival
NickName=Reporter1
Username=
Password=
jIdent=
NickName2=Reporter2
UserName2=
Password2=
jIdent2=
SrvxChan=
SrvxName=
SrvxAccount=
SrvxPassword=
TBindMap=@map
TBindGameInfo=@gameinfo
TBindSpecs=@specs
TBindSpectators=@spectators
TBindPlayers=@players
TBindSay=@say
Perform1=
Perform2=
Perform3=
Perform4=
Perform5=
Perform6=
teamRed=Red Team
teamBlue=Blue Team
teamGreen=Green Team
teamGold=Gold Team
xGInfoDelay=300.000000
xGDetailsDelay=240.000000
xSDetailsDelay=120.000000
xAFloodDelay=1.600000
HopeIsEmo=1
colGen=10
colTime=10
colHead=15
colBody=14
colRed=04
colBlue=12
colGreen=09
colGold=08
colHigh=11
```

After doing so, I recommend to edit the `ServerAddr`, `ServerPort`, `Channel` and `NickName`.
If you plan to run the bot on a non-bot server, you may want to set `bSecondaryLink` to `True`, and then edit `NickName2` also.


## Config Explanation

What everything does.

**`bEnabled=True`**
Turns the reporter on or off. (true/false)

**`bDebug=False`**
Enables server log debugging. Should only be on if you're having problems. (true/false)

**`bMuted=False`**
Mutes the reporters output. (true/false)

**`bPublicComs=True`**
Lets people use !map, !players, etc.. (true/false)

**`bPublicSay=True`**
Allow users to use !say. (true/false)

**`bAdvertise=True`**
Makes the reporter show in game where It's reporting to. (true/false)

**`bSecondaryLink=False`**
Enables a secondary connection to aid in lag/excess flooding. (true/false)

**`bExtra1on1Stats=False`**
Enables some extra 1on1 stats. (true/false)

**`bUseLogin=False`**
Use IRC Server Auth. (Aka BNC) (true/false)

**`bUseSrvx=False`**
Enable SrvX network authentication. (true/false)

**`bUseTBind=False`**
Use trigger binds. (Custom binds) (true/false)

**`bModeX=False`**
Hide the bots host with +x before joining a channel? (true/false)

**`jUseIdent=False`**
Use custom ident? (Nulled if using bnc) (true/false)

**`nInviteMe=False`**
Have the reporters invite themselves before joining a channel. (true/false)

**`nQuakenet=False`**
Enable quakenet options. (Used for auth and invite only) (true/false)

**`xModeM=False`**
Unavailable at this time.

**`xCensorText=False`**
Censor text? (To irc and from irc only, disables allowshouting) (true/false)

**`xEnhancedSprees=False`**
Enable enhanced sprees? (true/false)

**`xReportSprees=False`**
Enable sprees? (true/false)

**`xReportBSprees=False`**
Show start of sprees? (true/false)

**`xReportESprees=False`**
Show end of sprees? (Disable if using EUT) (true/false)

**`xReportMMI=False`**
Show EUT MMI's? (true/false)

**`xAllowShouting=False`**
Allow shouting? (Capitals?) (true/false)

**`xDefaultKills=False`**
Show kills? (Should only be used if using EUT) (true/false)

**`AdMessage=*`**
Message to show when game has begun.

**`AdminPassword=admin`**
Admin password. Change this!

**`ServerAddr=irc.GameRadius.org`**
IRC Server Address.

**`ServerPort=6667`**
IRC Server Port.

**`Channel=#Rival`**
IRC Channel. (Specify key after if applicable)

**`NickName=Reporter1`**
The reporters nick.

**`Username=`**
Username for BNC. (Used as ident if using BNC!)

**`Password=`**
Password for BNC.

**`jIdent=`**
Ident to use for the reporter.

**`NickName2=Reporter2`**
The secondary reporters nick.

**`Username2=`**
Username for BNC. (Used as ident if using BNC!)

**`Password2=`**
Password for BNC.

**`jIdent2=`**
Ident to use for the secondary reporter.

**`SrvxChan=`**
Chanserv full name. (eg: ChanServ@services.gameradius.org)

**`SrvxName=`**
Nickserv full name. (eg: NickServ@services.gameradius.org)

**`SrvxAccount=`**
Account name to auth to.

**`SrvxPassword=`**
Account password.

**`TBindMap=!map`**
Trigger to use for !map.

**`TBindGameInfo=!gameinfo`**
Trigger to use for !gameinfo.

**`TBindSpecs=!specs`**
Trigger to use for !specs.

**`TBindSpectators=!spectators`**
Trigger to use for !spectators.

**`TBindPlayers=!players`**
Trigger to use for !players.

**`TBindSay=!say`**
Trigger to use for !say.

**`Perform1=`**
Perform line for the irc server. Must be in raw commands. Done before join.

**`Perform2=`**
Perform line for the irc server. Must be in raw commands. Done before join.

**`Perform3=`**
Perform line for the irc server. Must be in raw commands. Done before join.

**`Perform4=`**
Perform line for the irc server. Must be in raw commands. Done after join.

**`Perform5=`**
Perform line for the irc server. Must be in raw commands. Done after join.

**`Perform3=`**
Perform line for the irc server. Must be in raw commands. Done after join.

**`teamRed=Red Team`**
The name of Red Team.

**`teamBlue=Blue Team`**
The name of Blue Team.

**`teamGreen=Green Team`**
The name of Green Team.

**`teamGold=Gold Team`**
The name of Gold Team.

**`xGInfoDelay=300.000000`**
Delay for game info. (Aka it will send them every 300s (5 minutes))

**`xGDetailsDelay=240.000000`**
Delay for game details. (Aka it will send them every 240s (4 minutes))

**`xSDetailsDelay=120.000000`**
Delay the reporter waits to send score details. (Aka it will send them every 120s (2 minutes))

**`xAFloodDelay=1.500000`**
The flood delay each link waits to send a message. (1.500000 and higher is recommended unless you're on a bot server.)

**`HopeIsEmo=1`**
Hope is emo?

**`colGen=10`**
This color is used for general UT messages such as joins/parts and flagpickups/drops in CTF.

**`colTime=10`**
This color is used for the time shown in front of each message.

**`colHead=15`**
Messages like Timelimit: 20mins consinst of a head and a value part, where head would refer to "Timelimit".

**`colBody=14`**
Like described above, this color would refer to "20 mins".

**`colRed=04`**
Color used to for the red team in teamgames.

**`colBlue=12`**
Color used to for the blue team in teamgames.

**`colGreen=09`**
Color used to for the green team in teamgames.

**`colGold=08`**
Color used to for the gold team in teamgames.

**`colHigh=11`**
Important messages like killingsprees or first blood events are shown in this color.


## UTGL (UT Global Login System)

If you don't know what is it just visit http://unrealadmin.org > Forums > UTGL and download the latest version.
If UTGL is on, MvReporter will show player logins in player lists.

As of 3.0 Final, XR3: This is unsupported and untested. Use at your own risk.


## Webadmin

1. You can call it in the `/mvr` directory on your server ip and the webadmin port in your web browser (e.g. http://1.2.3.4:80/mvr)

2. Please use the following login data for the mvr webadmin

Username: mvr
Password: The adminpassword from the config. (default: admin)

**Warning:** This version of MvR should not be used from the SuperWebAdmin areas that control MvR. Doing so may and probably will corrupt the MvR settings.
At no time is it recommended to use or attempt anything via SWA for MvR. In the future this will be renamed to prevent conflicts with SWA and so that SWA will simply not show it.


## Commands


### Channel Commands: (<x> means required, [x] means optional.)

**`!map`**
Displays the current map being played.

**`!gameinfo`**  
Displays the gameinfo.

**`!specs`**  
Displays the spectators in the game.

**`!spectators`**  
Same as !specs

**`!players`**  
Displays the current players in the game.

**`!say <message>`**  
Sends a message from IRC to the Gameserver as.. Name (IRC): [message]

----

### PM Commands: (<x> means required, [x] means optional.)

**`/msg BotName channel <adminpassword> <#newchannel> [key]`**  
Changes the reporters channel. (if the channel needs a key, specify it after.)

**`/msg BotName kick <adminpassword> <player>`**  
Kicks the player off the server.

**`/msg BotName kickban <adminpassword> <player>`**  
Kicks and Bans the player off the server.

**`/msg BotName mute <adminpassword>`**  
Mutes the reporter.

**`/msg BotName nick <adminpassword> <nickname>`**  
Changes the bots name to nickname.

**`/msg BotName op <adminpassword>`**  
Gives you op through the bot.

**`/msg BotName hop <adminpassword>`**  
Gives you half-op through the bot. (server must support +h)

**`/msg BotName voice <adminpassword>`**  
Gives you voice through the bot.

**`/msg BotName pubcoms <adminpassword>`**  
With this you can toggle the usage of public commands. (!gameinfo, !map, etc)

**`/msg BotName pwd <adminpassword> <newpassword>`**  
Changes the admin password to newpassword.

**`/msg BotName say <adminpassword> <message>`**  
Posts the message in the gameserver.

**`/msg BotName server <adminpassword> <server>`**  
Changes the IRC Server the bot is on. (eg: irc.GameRadius.org)

**`/msg BotName servertravel <adminpassword> <map>`**  
Changes the map on the server to map. (eg: CTF-Face)

**`/msg BotName teamblue <adminpassword> <teamname>`**  
Changes the name of the Blue Team to teamname.

**`/msg BotName teamgold <adminpassword> <teamname>`**  
Changes the name of the Gold Team to teamname.

**`/msg BotName teamgreen <adminpassword> <teamname>`**  
Changes the name of the Green Team to teamname.

**`/msg BotName teamred <adminpassword> <teamname>`**  
Changes the name of the Red Team to teamname.

**`/msg BotName teamsreset <adminpassword>`**  
Resets all of the team names to default.

**`/msg BotName mutate <adminpassword> <string>`**  
Runs a mutate command on the gameserver.

**`/msg BotName srvxchan <adminpassword> <name>`**  
Changes the SrvX chan to name. (eg: ChanServ@services.gameradius.org)

**`/msg BotName srvxname <adminpassword> <name>`**  
Changes the SrvX name to name. (eg: NickServ@services.gameradius.org)

**`/msg BotName srvxaccount <adminpassword> <account>`**  
Changes the SrvX account to account. (eg: Iama)

**`/msg BotName srvxpassword <adminpassword> <password>`**  
Changes the SrvX password to password. (eg: N00bie)

**`/msg BotName admessage <adminpassword> <var>`**  
Changes the ad message. (eg: Reporting live on irc.GameRadius.org to #RF)

**`/msg BotName bindmap <adminpassword> <var>`**  
Changes the !map bind to var. (eg: @map)

**`/msg BotName bindgameinfo <adminpassword> <var>`**  
Changes the !gameinfo bind to var. (eg: @gameinfo)

**`/msg BotName bindspecs <adminpassword> <var>`**  
Changes the !specs bind to var. (eg: @specs)

**`/msg BotName bindspectators <adminpassword> <var>`**  
Changes the !spectators bind to var. (eg: @spectators)

**`/msg BotName bindplayers <adminpassword> <var>`**  
Changes the !players bind to var. (eg: @players)

**`/msg BotName bindsay <adminpassword> <var>`**  
Changes the !say bind to var. (eg: @say)


## Known Bugs (maybe?)

1. SWA Reports 1-3 accessednone errors in log on startup. - Not sure if caused by MvR or something else.

2. Sometimes irc times will be off or not in order. - Has to do with buffer, unsure how to fix right now.

3. Bots don't understand this well - use `StandOpenTimed` instead!.. - appears in log file.. unsure of the cause/fix or if it's even related to mvr.

4. InLocalizedMessage error (accessednone) appears in log, unsure how to fix right now.

5. Excess floods easily when using one or two links. - Answer: Set `xAFloodDelay` to `1.500000` or higher.

6. Incompatible with SWA's own webadmin. - Work around, is to simply not use the swa admin for mvr.

7. DM etc doesn't report kills if using EUT or other. - Will be fixed in future.


## Notes

1. This is a modified version of Mavericks IRC Reporter v2.0 beta2 originally by [Mv]DarkViper,
which was edited by Rush. Altgamer released an updated version (3.0 XR3).

2. This is **!EXPERIMENTAL!** and not finished. Or maybe it is. Who knows.

3. I know this is borrowed from Wormbot's readme/manual.. so... yeah.. :)

If either debug, or text censoring is on the server may lag slightly.

Stupid little thing for anybody that asks, the X in XR3 doesn't really mean anything. It's just there incase a R3 version (Release 3) is actually made by another author. Unless that author names one XR3 also, in that case I suppose naming this one that is kind of pointless then.

I provide NO guarantees this actor will not malfunction, mess up, crash, burn, fondle, attempt to take over the world, or otherwise fault. By using this you agree I cannot and WILL NOT be held responsible for ANYTHING that happens from this, either direct or associated.
Only thing I ask that by using this, you will not remove the ad in place if you set Advertising to True in webadmin or ini by modifying this script.

Also note, the Webadmin design, style and graphics are Copyright © 2002 - 2006 Rivalflame.com, All rights reserved.
Rivalflame.com is also run and operated by NeuroAdvanced, LLC and is copyrighted as well.

Should you get the Source Edition (Marked with "SE" at the top of the file), which includes a Source folder in addition to System and Web, you agree NOT to remove the ad from any of the included source files and ANY other decompiled source files you get by other methods.

Also, I (Altgamer) am not a perfect programmer by far for UnrealScript. I do not know whether or not the modifications contained in this will impact, effect, or otherwise alter performance of servers.

Should you choose to distribute this, you may NOT resell, sell or other means collect ANY money from this in ANY way. Whether it be affiliated by including this actor with something else, or by itself. You may distribute this for FREE so long as this README and all source/compiled files remain UNCHANGED, intact and included in the distribution file.

**By using this, you agree to this whether or not you have read this.**  
(And if it does try to take over the world, It's your problem.)
