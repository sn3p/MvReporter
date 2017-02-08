//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterAdmin expands WebApplication config;

// Global variables
var MvReporter Controller;
var MvReporterConfig conf;
var string rVersion;

event Init()
{
  Super.Init();
  Log("++ [Mv]: Webadmin Initialized");
}

// Search classes (main handler / config)
function GetReporterClass()
{
  local MvReporter lTemp;
  foreach Level.AllActors(class'MvReporter', lTemp)
    {
      if (String(lTemp.Class) == "MvReporterXR3.MvReporter")
	      {
	        Controller = lTemp;
	        conf = Controller.conf;
	      }
    }
}

// Houston, we have an entry
event Query(WebRequest Request, WebResponse Response)
  {
    // Search for our reporter
    GetReporterClass();
    
    // No U!
    if (conf == none)
      {
        Response.SendText("<html><body><B>ERROR : MvReporter Class not found!</B></body></html>");
        return;
      }
      
    // Authentication  
    if (!((Request.Username ~= "mvr") && (Request.Password ~= conf.AdminPassword))) {
      Response.FailAuthentication("MvR XR3 Admin");
      return;
    }
    
    // Pages
    Response.Subst("BugAddress", "alt@rivalflame.com");
    switch (Mid(Request.URI, 1))
      {
      case "":
        QueryXR3Root(Request, Response);
        break;
      case "root.uhtm": 
        QueryXR3Root(Request, Response); 
        break;
      case "start.uhtm":
        QueryXR3Start(Request, Response);
        break;
      case "stop.uhtm":
        QueryXR3Stop(Request, Response);
        break;
      case "restart.uhtm":
        QueryXR3Reconnect(Request, Response);
        break;
      case "general.uhtm":
        QueryXR3General(Request, Response);
        break;
      case "irc.uhtm":
        QueryXR3IRC(Request, Response);
        break;
      case "teams.uhtm":
        QueryXR3Teams(Request, Response);
        break;
      case "colors.uhtm":
        QueryXR3Colors(Request, Response);
        break;
      }
  }

// Handle the physical pages
// ++ Root page
function QueryXR3Root(WebRequest Request, WebResponse Response)
  {
    // Page replys..
    if (conf.bEnabled)
      {
        Response.Subst("repStatus", "Running");
        Response.Subst("repSColor", "00B900");
      }
    else
      {
        Response.Subst("repStatus", "Stopped");
        Response.Subst("repSColor", "E32600");
      }
    if (conf.bDebug)
      {
        Response.Subst("repDebug", "On");
        Response.Subst("repDColor", "E32600");
      }
    else
      {
        Response.Subst("repDebug", "Off");
        Response.Subst("repDColor", "00B900");
      }
    // Display page
    Response.Subst("rVersion", rVersion);
    Response.IncludeUHTM("mvr/root.uhtm");
    Response.ClearSubst();
  }

// ++ Start reporter (Message)
function QueryXR3Start(WebRequest Request, WebResponse Response)
  {
    Response.Subst("rVersion", rVersion);
    if (conf.bEnabled)
      {
        Response.IncludeUHTM("mvr/start_no.uhtm");
      }
    else
      {
        Response.IncludeUHTM("mvr/start.uhtm");
        conf.bEnabled = True;
        conf.SaveConfig();
      }
    Controller.IRCLink.Connect(Controller, conf);
    if (conf.bSecondaryLink)
      Controller.IRCLink2.Connect(Controller, conf);
  }

// ++ Stop reporter (Message)
function QueryXR3Stop(WebRequest Request, WebResponse Response)
  {
    Response.Subst("rVersion", rVersion);
    if (conf.bEnabled)
      {
        Response.IncludeUHTM("mvr/stop.uhtm");
        conf.bEnabled = False;
        conf.SaveConfig();
      }
    else
        Response.IncludeUHTM("mvr/stop_no.uhtm");
    Controller.IRCLink.Disconnect();
    if (conf.bSecondaryLink)
      Controller.IRCLink2.Disconnect();
  }

// ++ Restart reporter (Message)
function QueryXR3Reconnect(WebRequest Request, WebResponse Response)
  {
    Response.Subst("rVersion", rVersion);
    if (conf.bEnabled)
        Response.IncludeUHTM("mvr/restart.uhtm");
    else
        Response.IncludeUHTM("mvr/restart_no.uhtm");
    if (conf.bEnabled)
      {
        Controller.IRCLink.RelaunchReporter("MvReporter XR3 - http://rivalflame.com");
        if (conf.bSecondaryLink)
          Controller.IRCLink2.RelaunchReporter("MvReporter XR3 - http://rivalflame.com");
      }
  }

// ++ General
function QueryXR3General(WebRequest Request, WebResponse Response)
{
  local string bDebug, AdminPassword, AdMessage, bPublicComs, bPublicSay, bExtra1on1Stats, bMuted, bAdvertise;

  // Data
  AdminPassword = Request.GetVariable("AdminPassword", conf.AdminPassword);
  AdMessage = Request.GetVariable("AdMessage", conf.AdMessage);
  bPublicComs = Request.GetVariable("bPublicComs", string(conf.bPublicComs));
  bMuted = Request.GetVariable("bMuted", string(conf.bMuted));
  bAdvertise = Request.GetVariable("bAdvertise", string(conf.bAdvertise));
  bDebug = Request.GetVariable("bDebug", string(conf.bDebug));
  bPublicSay = Request.GetVariable("bPublicSay", string(conf.bPublicSay));
  bExtra1on1Stats = Request.GetVariable("bExtra1on1Stats", string(conf.bExtra1on1Stats));

  // Replacements
  Response.Subst("AdminPassword", AdminPassword);
  Response.Subst("AdMessage", AdMessage);
  if (bPublicComs ~= "TRUE")
    Response.Subst("bPublicComs", "checked");
  if (bMuted ~= "TRUE")
    Response.Subst("bMuted", "checked");
  if (bAdvertise ~= "TRUE")
    Response.Subst("bAdvertise", "checked");
  if (bDebug ~= "TRUE")
    Response.Subst("bDebug", "checked");
  if (bPublicSay ~= "TRUE")
    Response.Subst("bPublicSay", "checked");
  if (bExtra1on1Stats ~= "TRUE")
    Response.Subst("bExtra1on1Stats", "checked");

  // Apply ...
  if (Request.GetVariable("Apply", "") == "Apply Settings")
    {
      conf.AdminPassword = Controller.IRCLink.ParseDelimited(AdminPassword, " ", 1);
      conf.AdMessage = AdMessage;

      bPublicComs = Request.GetVariable("bPublicComs", "false");
      if (bPublicComs ~= "TRUE")
	conf.bPublicComs = True;
      else
	conf.bPublicComs = False;
      bMuted = Request.GetVariable("bMuted", "false");
      if (bMuted ~= "TRUE")
	conf.bMuted = True;
      else
	conf.bMuted = False;
      bAdvertise = Request.GetVariable("bAdvertise", "false");
      if (bAdvertise ~= "TRUE")
	conf.bAdvertise = True;
      else
	conf.bAdvertise = False;
      bDebug = Request.GetVariable("bDebug", "false");
      if (bDebug ~= "TRUE")
	conf.bDebug = True;
      else
	conf.bDebug = False;
      bPublicSay = Request.GetVariable("bPublicSay", "false");
      if (bPublicSay ~= "TRUE")
	conf.bPublicSay = True;
      else
	conf.bPublicSay = False;
      bExtra1on1Stats = Request.GetVariable("bExtra1on1Stats", "false");
      if (bExtra1on1Stats ~= "TRUE")
	conf.bExtra1on1Stats = True;
      else
	conf.bExtra1on1Stats = False;

      // Save
      conf.SaveConfig();
    }
  
  Response.Subst("rVersion", rVersion);
  Response.Subst("PostAction", "general.uhtm");
  Response.IncludeUHTM("mvr/general.uhtm");
  Response.ClearSubst();
}


// ++ IRC
function QueryXR3IRC(WebRequest Request, WebResponse Response)
{
  //local string xAFloodDelay;
  local string ServerAddr, ServerPort, Channel;
  local string bUseLogin, bSecondaryLink, bUseSrvx, bModeX, xModeM, bUseTBind;
  local string xReportSprees, xReportBSprees, xReportESprees, xEnhancedSprees, xCensorText, xAllowShouting, xReportMMI, xDefaultKills;
  local string NickName, UserName, Password, NickName2, UserName2, Password2;
  local string SrvxName, SrvxAccount, SrvxPassword, TBindMap, TBindGameInfo, TBindSpecs, TBindSpectators, TBindPlayers, TBindSay;
  local string Perform1, Perform2, Perform3, Perform4, Perform5, Perform6;
  local string nInviteMe, nQuakenet, jUseIdent, jIdent, jIdent2, SrvxChan;
  
  // Data
  ServerAddr = Request.GetVariable("ServerAddr", conf.ServerAddr);
  ServerPort = Request.GetVariable("ServerPort", string(conf.ServerPort));
  Channel = Request.GetVariable("Channel", conf.Channel);

  bUseLogin = Request.GetVariable("bUseLogin", string(conf.bUseLogin));
  bSecondaryLink = Request.GetVariable("bSecondaryLink", string(conf.bSecondaryLink));
  bUseSrvx = Request.GetVariable("bUseSrvx", string(conf.bUseSrvx));
  bModeX = Request.GetVariable("bModeX", string(conf.bModeX));
  xModeM = Request.GetVariable("xModeM", string(conf.xModeM));
  bUseTBind = Request.GetVariable("bUseTBind", string(conf.bUseTBind));
  xReportSprees = Request.GetVariable("xReportSprees", string(conf.xReportSprees));
  xReportBSprees = Request.GetVariable("xReportBSprees", string(conf.xReportBSprees));
  xReportESprees = Request.GetVariable("xReportESprees", string(conf.xReportESprees));
  xEnhancedSprees = Request.GetVariable("xEnhancedSprees", string(conf.xEnhancedSprees));
  xCensorText = Request.GetVariable("xCensorText", string(conf.xCensorText));
  xAllowShouting = Request.GetVariable("xAllowShouting", string(conf.xAllowShouting));
  xReportMMI = Request.GetVariable("xReportMMI", string(conf.xReportMMI));
  xDefaultKills = Request.GetVariable("xDefaultKills", string(conf.xDefaultKills));
  nInviteMe = Request.GetVariable("nInviteMe", string(conf.nInviteMe));
  nQuakenet = Request.GetVariable("nQuakenet", string(conf.nQuakenet));
  jUseIdent = Request.GetVariable("jUseIdent", string(conf.jUseIdent));

  NickName = Request.GetVariable("NickName", conf.NickName);
  UserName = Request.GetVariable("UserName", conf.UserName);
  Password = Request.GetVariable("Password", conf.Password);
  jIdent = Request.GetVariable("jIdent", conf.jIdent);

  NickName2 = Request.GetVariable("NickName2", conf.NickName2);
  UserName2 = Request.GetVariable("UserName2", conf.UserName2);
  Password2 = Request.GetVariable("Password2", conf.Password2);
  jIdent2 = Request.GetVariable("jIdent2", conf.jIdent2);
  
  SrvxChan = Request.GetVariable("SrvxChan", conf.SrvxChan);
  SrvxName = Request.GetVariable("SrvxName", conf.SrvxName);
  SrvxAccount = Request.GetVariable("SrvxAccount", conf.SrvxAccount);
  SrvxPassword = Request.GetVariable("SrvxPassword", conf.SrvxPassword);

  // Fuck you epic games, FUCK YOU. compile error my ass.
  // xGInfoDelay = Request.GetVariable("xGInfoDelay", conf.xGInfoDelay);
  // xGDetailsDelay = Request.GetVariable("xGDetailsDelay", string(conf.xGDetailsDelay));
  // xSDetailsDelay = Request.GetVariable("xSDetailsDelay", string(conf.xSDetailsDelay));
  // xAFloodDelay = Request.GetVariable("xAFloodDelay", string(conf.xAFloodDelay));

  TBindMap = Request.GetVariable("TBindMap", conf.TBindMap);
  TBindGameInfo = Request.GetVariable("TBindGameInfo", conf.TBindGameInfo);
  TBindSpecs = Request.GetVariable("TBindSpecs", conf.TBindSpecs);
  TBindSpectators = Request.GetVariable("TBindSpectators", conf.TBindSpectators);
  TBindPlayers = Request.GetVariable("TBindPlayers", conf.TBindPlayers);
  TBindSay = Request.GetVariable("TBindSay", conf.TBindSay);

  Perform1 = Request.GetVariable("Perform1", conf.Perform1);
  Perform2 = Request.GetVariable("Perform2", conf.Perform2);
  Perform3 = Request.GetVariable("Perform3", conf.Perform3);
  Perform4 = Request.GetVariable("Perform4", conf.Perform4);
  Perform5 = Request.GetVariable("Perform5", conf.Perform5);
  Perform6 = Request.GetVariable("Perform6", conf.Perform6);

  // Replacements
  Response.Subst("ServerAddr", ServerAddr);
  Response.Subst("ServerPort", ServerPort);
  Response.Subst("Channel", Channel);

  // Fuck you epic games, FUCK YOU. compile error my ass.
  // Response.Subst("xGInfoDelay", xGInfoDelay);
  // Response.Subst("xGDetailsDelay", xGDetailsDelay);
  // Response.Subst("xSDetailsDelay", xSDetailsDelay);
  // Response.Subst("xAFloodDelay", xAFloodDelay);

  Response.Subst("NickName", NickName);
  Response.Subst("UserName", UserName);
  Response.Subst("Password", Password);
  Response.Subst("jIdent", jIdent);

  Response.Subst("NickName2", NickName2);
  Response.Subst("UserName2", UserName2);
  Response.Subst("Password2", Password2);
  Response.Subst("jIdent2", jIdent2);

  Response.Subst("SrvxChan", SrvxChan);
  Response.Subst("SrvxName", SrvxName);
  Response.Subst("SrvxAccount", SrvxAccount);
  Response.Subst("SrvxPassword", SrvxPassword);

  Response.Subst("TBindMap", TBindMap);
  Response.Subst("TBindGameInfo", TBindGameInfo);
  Response.Subst("TBindSpecs", TBindSpecs);
  Response.Subst("TBindSpectators", TBindSpectators);
  Response.Subst("TBindPlayers", TBindPlayers);
  Response.Subst("TBindSay", TBindSay);

  Response.Subst("Perform1", Perform1);
  Response.Subst("Perform2", Perform2);
  Response.Subst("Perform3", Perform3);
  Response.Subst("Perform4", Perform4);
  Response.Subst("Perform5", Perform5);
  Response.Subst("Perform6", Perform6);

  if (bUseLogin ~= "TRUE")
    Response.Subst("bUseLogin", "checked");
  if (bSecondaryLink ~= "TRUE")
    Response.Subst("bSecondaryLink", "checked");
  if (bUseSrvx ~= "TRUE")
    Response.Subst("bUseSrvx", "checked");
  if (bModeX ~= "TRUE")
    Response.Subst("bModeX", "checked");
  if (xModeM ~= "TRUE")
    Response.Subst("xModeM", "checked");
  if (bUseTBind ~= "TRUE")
    Response.Subst("bUseTBind", "checked");
  if (xReportSprees ~= "TRUE")
    Response.Subst("xReportSprees", "checked");
  if (xReportBSprees ~= "TRUE")
    Response.Subst("xReportBSprees", "checked");
  if (xReportESprees ~= "TRUE")
    Response.Subst("xReportESprees", "checked");
  if (xEnhancedSprees ~= "TRUE")
    Response.Subst("xEnhancedSprees", "checked");
  if (xCensorText ~= "TRUE")
    Response.Subst("xCensorText", "checked");
  if (xAllowShouting ~= "TRUE")
    Response.Subst("xAllowShouting", "checked");
  if (xReportMMI ~= "TRUE")
    Response.Subst("xReportMMI", "checked");
  if (xDefaultKills ~= "TRUE")
    Response.Subst("xDefaultKills", "checked");
  if (nInviteMe ~= "TRUE")
    Response.Subst("nInviteMe", "checked");
  if (nQuakenet ~= "TRUE")
    Response.Subst("nQuakenet", "checked");
  if (jUseIdent ~= "TRUE")
    Response.Subst("jUseIdent", "checked");
  // Save button.... whew...
  if (Request.GetVariable("Apply", "") == "Apply Settings")
    {
      conf.ServerAddr = Controller.IRCLink.ParseDelimited(ServerAddr, " ", 1);
      conf.ServerPort = int(Controller.IRCLink.ParseDelimited(ServerPort, " ", 1));
      conf.Channel = Controller.IRCLink.ParseDelimited(Channel, " ", 1);
      
      // Fuck you epic games, FUCK YOU. compile error my ass.
      // conf.xGInfoDelay = Controller.IRCLink.ParseDelimited(xGInfoDelay, " ", 1)
      // conf.xGDetailsDelay = Controller.IRCLink.ParseDelimited(xGDetailsDelay, " ", 1);
      // conf.xSDetailsDelay = Controller.IRCLink.ParseDelimited(xSDetailsDelay, " ", 1);
      // conf.xAFloodDelay = Controller.IRCLink.ParseDelimited(xAFloodDelay, " ", 1);

      conf.NickName = Controller.IRCLink.ParseDelimited(NickName, " ", 1);
      conf.UserName = Controller.IRCLink.ParseDelimited(UserName, " ", 1);
      conf.Password = Controller.IRCLink.ParseDelimited(Password, " ", 1);
      conf.jIdent = Controller.IRCLink.ParseDelimited(jIdent, " ", 1);

      conf.NickName2 = Controller.IRCLink.ParseDelimited(NickName2, " ", 1);
      conf.UserName2 = Controller.IRCLink.ParseDelimited(UserName2, " ", 1);
      conf.Password2 = Controller.IRCLink.ParseDelimited(Password2, " ", 1);
      conf.jIdent2 = Controller.IRCLink.ParseDelimited(jIdent2, " ", 1);

      conf.SrvxChan = Controller.IRCLink.ParseDelimited(SrvxChan, " ", 1);
      conf.SrvxName = Controller.IRCLink.ParseDelimited(SrvxName, " ", 1);
      conf.SrvxAccount = Controller.IRCLink.ParseDelimited(SrvxAccount, " ", 1);
      conf.SrvxPassword = Controller.IRCLink.ParseDelimited(SrvxPassword, " ", 1);

      conf.TBindMap = Controller.IRCLink.ParseDelimited(TBindMap, " ", 1);
      conf.TBindGameInfo = Controller.IRCLink.ParseDelimited(TBindGameInfo, " ", 1);
      conf.TBindSpecs = Controller.IRCLink.ParseDelimited(TBindSpecs, " ", 1);
      conf.TBindSpectators = Controller.IRCLink.ParseDelimited(TBindSpectators, " ", 1);
      conf.TBindPlayers = Controller.IRCLink.ParseDelimited(TBindPlayers, " ", 1);
      conf.TBindSay = Controller.IRCLink.ParseDelimited(TBindSay, " ", 1);

      conf.Perform1 = Perform1;
      conf.Perform2 = Perform2;
      conf.Perform3 = Perform3;
      conf.Perform4 = Perform4;
      conf.Perform5 = Perform5;
      conf.Perform6 = Perform6;

      if (bUseLogin ~= "TRUE")
		conf.bUseLogin = True;
      else
		conf.bUseLogin = False;
      if (bSecondaryLink ~= "TRUE")
		conf.bSecondaryLink = True;
      else
		conf.bSecondaryLink = False;
      if (bUseSrvx ~= "TRUE")
		conf.bUseSrvx = True;
      else
		conf.bUseSrvx = False;
      if (bModeX ~= "TRUE")
		conf.bModeX = True;
      else
		conf.bModeX = False;
      if (xModeM ~= "TRUE")
		conf.xModeM = True;
      else
		conf.xModeM = False;
      if (bUseTBind ~= "TRUE")
		conf.bUseTBind = True;
      else
		conf.bUseTBind = False;
      if (xReportSprees ~= "TRUE")
		conf.xReportSprees = True;
      else
		conf.xReportSprees = False;
      if (xReportBSprees ~= "TRUE")
		conf.xReportBSprees = True;
      else
		conf.xReportBSprees = False;
      if (xReportESprees ~= "TRUE")
		conf.xReportESprees = True;
      else
		conf.xReportESprees = False;
      if (xEnhancedSprees ~= "TRUE")
		conf.xEnhancedSprees = True;
      else
		conf.xEnhancedSprees = False;
      if (xCensorText ~= "TRUE")
		conf.xCensorText = True;
      else
		conf.xCensorText = False;
      if (xAllowShouting ~= "TRUE")
		conf.xAllowShouting = True;
      else
		conf.xAllowShouting = False;
      if (xReportMMI ~= "TRUE")
		conf.xReportMMI = True;
      else
		conf.xReportMMI = False;
      if (xDefaultKills ~= "TRUE")
		conf.xDefaultKills = True;
      else
		conf.xDefaultKills = False;
      if (bUseLogin ~= "TRUE")
		conf.bUseLogin = True;
      else
		conf.bUseLogin = False;
      if (nInviteMe ~= "TRUE")
		conf.nInviteMe = True;
      else
		conf.nInviteMe = False;
      if (nQuakenet ~= "TRUE")
		conf.nQuakenet = True;
      else
		conf.nQuakenet = False;
      if (jUseIdent ~= "TRUE")
		conf.jUseIdent = True;
      else
		conf.jUseIdent = False;
		
      // Save!
      conf.SaveConfig();
    }
    
  Response.Subst("rVersion", rVersion);
  Response.Subst("PostAction", "irc.uhtm");
  Response.IncludeUHTM("mvr/irc.uhtm");
  Response.ClearSubst();
}


// ++ Teams
function QueryXR3Teams(WebRequest Request, WebResponse Response)
{
  local string teamRed, teamBlue, teamGreen, teamGold;
  Response.Subst("rVersion", rVersion);
  
  // Data
  teamRed = Request.GetVariable("teamRed", conf.teamRed);
  teamBlue = Request.GetVariable("teamBlue", conf.teamBlue);
  teamGreen = Request.GetVariable("teamGreen", conf.teamGreen);
  teamGold = Request.GetVariable("teamGold", conf.teamGold);
  
  // Replacements
  Response.Subst("teamRed", teamRed);
  Response.Subst("teamBlue", teamBlue);
  Response.Subst("teamGreen", teamGreen);
  Response.Subst("teamGold", teamGold);

  // Apply Button?...
  if (Request.GetVariable("Apply", "") == "Apply Settings")
    {
      conf.teamRed = teamRed;
      conf.teamBlue = teamBlue;
      conf.teamGreen = teamGreen;
      conf.teamGold = teamGold;
      
      // Save!
      conf.SaveConfig();
      Controller.LoadTeamNames();
    }

  // Reset Button?...
  if (Request.GetVariable("Apply", "") == "Reset All Teams")
    {
      conf.teamRed = "Red Team";
      conf.teamBlue = "Blue Team";
      conf.teamGreen = "Green Team";
      conf.teamGold = "Gold Team";
      conf.SaveConfig();
      Controller.LoadTeamNames();
      Response.IncludeUHTM("mvr/teams_reset.uhtm");
      Response.ClearSubst();
      return;
    }
  
  Response.Subst("PostAction", "teams.uhtm");
  Response.IncludeUHTM("mvr/teams.uhtm");
  Response.ClearSubst();
}


// ++ Colors
function QueryXR3Colors(WebRequest Request, WebResponse Response)
{
  local string colGen, colTime, colHead, colBody, colHigh;
  local string colRed, colBlue, colGreen, colGold;
  
  // Data
  colGen = Request.GetVariable("colGen", conf.colGen);
  colTime = Request.GetVariable("colTime", conf.colTime);
  colHead = Request.GetVariable("colHead", conf.colHead);
  colBody = Request.GetVariable("colBody", conf.colBody);
  colHigh = Request.GetVariable("colHigh", conf.colHigh);
  colRed = Request.GetVariable("colRed", conf.colRed);
  colBlue = Request.GetVariable("colBlue", conf.colBlue);
  colGreen = Request.GetVariable("colGreen", conf.colGreen);
  colGold = Request.GetVariable("colGold", conf.colGold);
  
  // Replacements
  Response.Subst("colGen", colGen);
  Response.Subst("colTime", colTime);
  Response.Subst("colHead", colHead);
  Response.Subst("colBody", colBody);
  Response.Subst("colHigh", colHigh);
  Response.Subst("colRed", colRed);
  Response.Subst("colBlue", colBlue);
  Response.Subst("colGreen", colGreen);
  Response.Subst("colGold", colGold);
  
  // Apply Button?...
  if (Request.GetVariable("Apply", "") == "Apply Settings")
    {
      conf.colGen = Controller.IRCLink.ParseDelimited(colGen, " ", 1);
      conf.colTime = Controller.IRCLink.ParseDelimited(colTime, " ", 1);
      conf.colHead = Controller.IRCLink.ParseDelimited(colHead, " ", 1);
      conf.colBody = Controller.IRCLink.ParseDelimited(colBody, " ", 1);
      conf.colHigh = Controller.IRCLink.ParseDelimited(colHigh, " ", 1);
      conf.colRed = Controller.IRCLink.ParseDelimited(colRed, " ", 1);
      conf.colBlue = Controller.IRCLink.ParseDelimited(colBlue, " ", 1);
      conf.colGreen = Controller.IRCLink.ParseDelimited(colGreen, " ", 1);
      conf.colGold = Controller.IRCLink.ParseDelimited(colGold, " ", 1);
      
      // Save!
      Controller.CheckIRCColors();
    }
  Response.Subst("rVersion", rVersion);
  Response.Subst("PostAction", "colors.uhtm");
  Response.IncludeUHTM("mvr/colors.uhtm");
  Response.ClearSubst();
}


// DP

defaultproperties
{
     rVersion="3.0.1 PR1.1 B6246"
}
