//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//  Gambino Edition by sn3p (snap@gambino.nl)                        /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterConfig expands Actor;
var string sTeams[4];

var globalconfig bool   bEnabled;
var globalconfig bool   bDebug;
var globalconfig bool   bMuted;
var globalconfig bool   bSilent;
var globalconfig bool   bModeX;
var globalconfig bool   bPublicComs;
var globalconfig bool   bAdvertise;
var globalconfig bool   xModeM;
var globalconfig bool   xEnhancedSprees;
var globalconfig bool   xReportSprees;
var globalconfig bool   xReportBSprees;
var globalconfig bool   xReportESprees;
var globalconfig bool   xReportMMI;
var globalconfig bool   xDefaultKills;
var globalconfig bool   xCensorText;
var globalconfig bool   xAllowShouting;
var globalconfig bool   nInviteMe;
var globalconfig bool   nQuakenet;
var globalconfig bool   jUseIdent;
var globalconfig string HopeIsEmo;
var globalconfig string jIdent;
var globalconfig string jIdent2;
var globalconfig string ServerAddr;
var globalconfig int    ServerPort;
var globalconfig string Channel;
var globalconfig string NickName;
var globalconfig string AdMessage;
var globalconfig bool   bUseLogin;
var globalconfig string UserName;
var globalconfig string Password;
var globalconfig bool   bUseSrvx;
var globalconfig string SrvxChan;
var globalconfig string SrvxName;
var globalconfig string SrvxAccount;
var globalconfig string SrvxPassword;
var globalconfig bool   bUsetBind;
var globalconfig string tBindMap;
var globalconfig string tBindGameInfo;
var globalconfig string tBindSpecs;
var globalconfig string tBindSpectators;
var globalconfig string tBindPlayers;
var globalconfig string tBindSay;
var globalconfig string Perform1;
var globalconfig string Perform2;
var globalconfig string Perform3;
var globalconfig string Perform4;
var globalconfig string Perform5;
var globalconfig string Perform6;
var globalconfig string AdminPassword;
var globalconfig float  xAFloodDelay;
var globalconfig float  xGInfoDelay;
var globalconfig float  xGDetailsDelay;
var globalconfig float  xSDetailsDelay;
var globalconfig bool   bSecondaryLink;
var globalconfig string NickName2;
var globalconfig string UserName2;
var globalconfig string Password2;
var globalconfig bool   bExtra1on1Stats;
var globalconfig bool   bPublicSay;
var globalconfig string teamRed;
var globalconfig string teamBlue;
var globalconfig string teamGreen;
var globalconfig string teamGold;
var globalconfig string colGen;
var globalconfig string colTime;
var globalconfig string colHead;
var globalconfig string colBody;
var globalconfig string colRed;
var globalconfig string colBlue;
var globalconfig string colGreen;
var globalconfig string colGold;
var globalconfig string colHigh;

defaultproperties
{
     bEnabled=True
     bAdvertise=True
     xAllowShouting=True
     nInviteMe=True
     HopeIsEmo="True"
     ServerAddr="irc.quakenet.org"
     ServerPort=6667
     Channel="#gambino.live"
     NickName="Reporter1"
     AdMessage="This match is being broadcasted live to #gambino.live on irc.quakenet.org"
     tBindMap="!map"
     tBindGameInfo="!gameinfo"
     tBindSpecs="!specs"
     tBindSpectators="!spectators"
     tBindPlayers="!players"
     tBindSay="!say"
     AdminPassword="admin"
     xAFloodDelay=2.000000
     xGInfoDelay=300.000000
     xGDetailsDelay=240.000000
     xSDetailsDelay=120.000000
     NickName2="Reporter2"
     teamRed="Red Team"
     teamBlue="Blue Team"
     teamGreen="Green Team"
     teamGold="Gold Team"
     colGen="03"
     colTime="02"
     colHead="02"
     colBody="14"
     colRed="04"
     colBlue="12"
     colGreen="03"
     colGold="07"
     colHigh="04"
}
