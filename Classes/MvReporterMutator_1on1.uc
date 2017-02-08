//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterMutator_1on1 expands Mutator;

var MvReporterIRCLink Link;
var MvReporterStats_1on1 Stats;
var MvReporterConfig conf;

function bool HandlePickupQuery(Pawn Other, Inventory item, out byte bAllowPickup)
{
	local PlayerReplicationInfo PRI;
	
	PRI = Other.PlayerReplicationInfo;

	if (Item.IsA('ThighPads'))
		Stats.SendIRCMessage(Stats.GetTeamColor(PRI.Team)$PRI.PlayerName$Stats.ircClear@"has picked up"@conf.colBody$"ThighPads.");
	else if (Item.IsA('Armor2'))
		Stats.SendIRCMessage(Stats.GetTeamColor(PRI.Team)$PRI.PlayerName$Stats.ircClear@"has picked up an"@conf.colGreen$"Armor.");
	else if (Item.IsA('UT_Jumpboots'))
		Stats.SendIRCMessage(Stats.GetTeamColor(PRI.Team)$PRI.PlayerName$Stats.ircClear@"has picked up"@conf.colGen$"Jumpboots.");
	else if (Item.IsA('UT_Shieldbelt'))
		Stats.SendIRCMessage(Stats.GetTeamColor(PRI.Team)$PRI.PlayerName$Stats.ircClear@"has picked up a"@conf.colGold$"Shieldbelt.");
	else if (Item.IsA('HealthPack'))
		Stats.SendIRCMessage(Stats.GetTeamColor(PRI.Team)$PRI.PlayerName$Stats.ircClear@"has picked up a"@conf.colGold$"HealthPack.");

	if ( NextMutator != None )
		return NextMutator.HandlePickupQuery(Other, item, bAllowPickup);
}

		

defaultproperties
{
}
