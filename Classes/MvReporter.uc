//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporter expands Actor;

// Declare some Variable stuff
var bool bInitialized;
var string sVersion, sBuild;
var MvReporterConfig conf;
var MvReporterIRCLink IRCLink;
var MvReporterIRCLink2 IRCLink2;
var MvReporterSpectator Spectator;
var MvReporterMutator Mut;
var GameReplicationInfo GRI;

// Event: PreBeginPlay
event PreBeginPlay()
{
  // Check if we're already initialized
  if (bInitialized)
    return;
  bInitialized = TRUE;

  // Load...
  conf = Spawn(class'MvReporterXR3.MvReporterConfig');
  LoadTeamNames();
  CheckIRCColors();

  // Start Reporter Engine
  conf.SaveConfig();
  Log("+---------------------------+");
  Log("| [Mv] Reporter 3.0.0 (XR3) |");
  Log("+---------------------------+");
  InitReporter();
}


// FUNCTION: Enabled / Enable/Disable Reporter
function InitReporter()
{
  local Mutator M;
  
  // Start IRC Link
  if (IRCLink == none)
    IRCLink = Spawn(class'MvReporterXR3.MvReporterIRCLink');
  if (IRCLink2 == none && conf.bSecondaryLink)
    IRCLink2 = Spawn(class'MvReporterXR3.MvReporterIRCLink2');
  if (IRCLink == none || (IRCLink2 == none && conf.bSecondaryLink))
  {
    Log("++ [Mv]: Error Spawning IRC Link Class!");
    return;
  }

  if (conf.bEnabled)
    {
      Log("++ [Mv]: Starting Connection Process...");
      IRCLink.Connect(self, conf);
      if (conf.bSecondaryLink)
	IRCLink2.Connect(self, conf);
    }

  if (Spectator == None)
    Spectator = Level.Spawn(class'MvReporterXR3.MvReporterSpectator');

  Level.Game.BaseMutator.AddMutator(Level.Game.Spawn(class'MvReporterMutator'));
  M = Level.Game.BaseMutator;

  While (M.NextMutator != None)
  {
        if (InStr(string(M.Class),"MvReporterMutator") != -1)
       		break;
       	else
       		M = M.NextMutator;
  }
  Mut = MvReporterMutator(M);
  Mut.Controller = self;
  Mut.conf = conf;
  Mut.Link = IRCLink;
  Mut.Link2 = IRCLink2;
  Spectator.Engage(Self, IRCLink, IRCLink2);
}


// FUNCTION: Load the Team Names
function LoadTeamNames()
{
  if (Level.Game.GetPropertyText("RedTeamName") != "")
    conf.sTeams[0] = Level.Game.GetPropertyText("RedTeamName");
  else
    conf.sTeams[0] = conf.teamRed;
  if (Level.Game.GetPropertyText("BlueTeamName") != "")
    conf.sTeams[1] = Level.Game.GetPropertyText("BlueTeamName");
  else
    conf.sTeams[1] = conf.teamBlue;
  conf.sTeams[2] = conf.teamGreen;
  conf.sTeams[3] = conf.teamGold;
}

function CheckIRCColors()
{
  if (Asc(conf.colGen) != 3) conf.colGen = "."$conf.colGen;
  if (Asc(conf.colHead) != 3) conf.colHead = "."$conf.colHead;
  if (Asc(conf.colBody) != 3) conf.colBody = "."$conf.colBody;
  if (Asc(conf.colTime) != 3) conf.colTime = "."$conf.colTime;
  if (Asc(conf.colHigh) != 3) conf.colHigh = "."$conf.colHigh;

  if (Asc(conf.colRed) != 3) conf.colRed = "."$conf.colRed;
  if (Asc(conf.colBlue) != 3) conf.colBlue = "."$conf.colBlue;
  if (Asc(conf.colGreen) != 3) conf.colGreen = "."$conf.colGreen;
  if (Asc(conf.colGold) != 3) conf.colGold = "."$conf.colGold;
  conf.SaveConfig();
}

defaultproperties
{
     sVersion="3.0 (XR3)"
     sBuild="06/22/2006"
}
