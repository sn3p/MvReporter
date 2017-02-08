//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterSpectator expands MessagingSpectator;

// Our master controller
var MvReporter Controller;
var MvReporterIRCLink Link;
var MvReporterIRCLink2 Link2;
var MvReporterStats Stats;
var string LastMessage;

// Init Function
function Engage(MvReporter InController, MvReporterIRCLink InLink, MvReporterIRCLink2 InLink2)
{
  local Class<MvReporterStats> StatsClass;
  local MvReporterMutator_1on1 Mut1on1;
  local Actor OutActor;
  local Mutator M;
  local string GameClass;
  local bool bOneOnOne;

  Controller = InController;
  Link = InLink;
  Link2 = InLink2;
  
  // 1 on 1 is only applied for DM
  GameClass = caps(GetItemName(string(Level.Game.Class)));
  if (GameClass == "DEATHMATCHPLUS" || GameClass == "EUTDEATHMATCHPLUS")
    {
      if (Level.Game.MaxPlayers == 2)
        {
          StatsClass = class'MvReporterStats_1on1';
          bOneOnOne = True;
        }
      else
          StatsClass = class'MvReporterStats_DM';
    }
  else if (GameClass == "TEAMGAMEPLUS" || GameClass == "EUTTEAMGAMEPLUS")
    {
      StatsClass = class'MvReporterStats_TDM';
    } 
  else if (GameClass == "CTFGAME")
    {
      StatsClass = class'MvReporterStats_CTF';
    }
  else if (GameClass == "SMARTCTFGAME")
    {
      StatsClass = class'MvReporterStats_EUT';
    }
  else if (GameClass == "DOMINATION")
    {
      StatsClass = class'MvReporterStats_DOM';
    } 
  else if (GameClass == "LASTMANSTANDING")
    {
      StatsClass = class'MvReporterStats_LMS';
    }
  else if (Left(string(Level), 3)=="BT-" || Left(string(Level), 5)=="CTF-BT-")
    {
      StatsClass = class'MvReporterStats_BT';
    } 
  else
      StatsClass = class'MvReporterStats_DM';

  // Is 1v1?
  if (Controller.conf.bExtra1on1Stats && (bOneOnOne))
    {
      Level.Game.BaseMutator.AddMutator(Level.Game.Spawn(class'MvReporterMutator_1on1'));
      M = Level.Game.BaseMutator;
      while (M.NextMutator != None)
        {
          if (InStr(string(M.Class),"MvReporterMutator_1on1") != -1)
            break;
          else
            M = M.NextMutator;
        }
      Mut1on1 = MvReporterMutator_1on1(M);
      Mut1on1.Link = Link;
      Mut1on1.conf = Controller.conf;
    }

  // Spawn Actor
  Stats = Spawn(StatsClass);
  
  // Check if spawn was success
  if (Stats == none)
    {
      Log("++ [Mv]: Unable to spawn Stats Class!");
    }
  else
    {
      Stats.Link = Link;
      Stats.Link2 = Link2;
      Link.Link2 = Link2;
      Link.Spec = self;
      if ( Mut1on1 != None )
      	Mut1on1.Stats = MvReporterStats_1on1(Stats);
      if (Controller.conf.bSecondaryLink)
	Link.xAFloodDelay = Controller.conf.xAFloodDelay/2;
      else
	Link.xAFloodDelay = Controller.conf.xAFloodDelay;
      Stats.Spec = self;
      Stats.conf = Controller.conf;
      Stats.Level = Level;
      Stats.GRI = Level.Game.GameReplicationInfo;
      Stats.Initialize();
    }
}

function ClientMessage(coerce string S, optional name Type, optional bool bBeep )
{
  if (Type=='None')
    LastMessage=S;
  if (Stats!=None)
    Stats.InClientMessage(S, Type, bBeep);
}

function TeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep )
{
  Stats.InTeamMessage(PRI, S, Type, bBeep);
}

function ReceiveLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  Stats.InLocalizedMessage(Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

function ClientVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
  Stats.InVoiceMessage(Sender, Recipient, messagetype, messageID);
}

function string ServerMutate(string MutateString)
{
  local String Str;
  local Mutator Mut;
  Mut = Level.Game.BaseMutator;
  Mut.Mutate(MutateString, Self);
  return LastMessage;
}

defaultproperties
{
}
