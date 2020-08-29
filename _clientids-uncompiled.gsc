#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/gametypes/_hud_util;
#include maps/mp/gametypes/_hud_message;

init(){
	PrecacheShader("white");

	level.clientid = 0;																												//Standard stuff for _clientids	

	level thread onplayerconnect();																									//If player connects..
	level.onplayerdamage = ::onplayerdamage;																						//When damage is taken, call onplayerdamage().
	PrecacheShader("em_bg_flag_netherlands");
}

onplayerconnect(){
	for(;;){
	level waittill("connected", player);																							//Wait till player is done loading in...
	player.clientid = level.clientid;																									//Standard stuff for _clientids
	level.clientid++;																													//Standard stuff for _clientids
	player thread onplayerspawned();																								//When player spawns, call onplayerspawned();
	}
}

onplayerspawned(){
	self endon("disconnect");																										//kill on disconnect.
	level endon("game_ended");																										//kill on game end.
	self waittill("spawned_player");																								//Wait till player spawns in...

	self useServerVisionSet(true);
	self SetVisionSetforPlayer("default", 0);
	self freezecontrols(false);																										//remove player freeze at start of match

	self thread monitor_class();																									//Call monitor_class();					Keeps track of selected classes
	self thread monitor_buttons();
	self thread monitor_time();																										//Call monitor_buttons();				Keeps track of which buttons are pressed
	self thread welcome_message();																									//Call welcome_message();				Displays welcome message
	self thread on_respawn();
}

welcome_message(){
	self endon("disconnect");																										//kill on disconnect.
	self endon("death");																											//kill on death.
	level endon("game_ended");  																									//kill on game end.
	self thread large_message("^5Welcome " + self.name, "^5 To the Tom-T6 Trickshotting server!", "em_bg_flag_netherlands", 10);	//Enlarged message.

	self iprintln("^1[{+actionslot 1}] or [{+actionslot 2}] while prone to go thru options.");
	
	wait 2;

	self iprintln("^1[{+activate}] while prone to select.");
}

monitor_class(){
	self endon( "disconnect" );																										//Kill on disconnect.
	for(;;){
		self waittill("changed_class");																								//Start when class has been changed.
		self thread maps/mp/gametypes/_class::giveloadout(self.team, self.class);													//Give selected loadout.
		wait 0.01;																													//Wait to prevent text overlapping.
		self iprintlnbold(" ");																				//Display text.
	}
}

monitor_time(){
self.nuke_countdown = create_text("Nuke inbound: " + time, "objective", 1.5, -40, 90, ((255/255), (150/255), (0/255)), 0, ((0), (0), (0)), 0, "none", "TOPLEFT", "TOPLEFT");
	for(;;){
		time = gettimeremaining();

		if(time < 14){
			if(time > 0 && time < 11){
				self playSound("wpn_semtex_alert");
				self.nuke_countdown.alpha = 1;
				self.nuke_countdown settext("Nuke inbound: " + (time - 1));
				self.nuke_countdown.hidewheninmenu = true;
			} else {self.nuke_countdown.alpha = 0;}

			if(time == 13){
				foreach(player in level.players){
					self thread large_message("^3Tactical nuke inbound!", "^3Time is running out!", "", 5);
				}
			}
			if(time == 3){setdvar("timescale", "0.9");}
			if(time == 2){setdvar("timescale", "0.8");}

			if(time == 1){
				setdvar("timescale", "0.6");
				self playsound("wpn_rpg_whizby");
				
				
			wait 0.5;
			self.origin = self.origin + (0, 0, 2);
			self setvelocity((self getvelocity() - self getvelocity()) + (0, 0, 50000));
			wait 0.4;
				self setempjammed(true);
				self useServerVisionSet(true);
				self SetVisionSetforPlayer("remote_mortar_enhanced", 0);
				
				Earthquake(0.4, 1, player.origin, 900000);
				self blow_up(self);
				self suicide();
			}

			if(time == -1)setdvar("timescale", "0.8");
			if(time == -2)setdvar("timescale", "0.9");
			if(time == -2)setdvar("timescale", "1");
		}
	wait 1;
	}
}

blow_up(player)
{
    self.explosion = spawn("script_model", player.origin);
    self.explosion playSound("exp_barrel");

	playfx(level.chopper_fx["explode"]["large"], player.origin);

    wait 0.1;
    self.explosion delete();
}

gettimeremaining()
{
	return floor((((level.timelimit * 60) * 1000) - gettimepassed()) / 1000);
}

gettimepassed()
{
	if ( !isDefined( level.starttime ) )
	{
		return 0;
	}
	if ( level.timerstopped )
	{
		return level.timerpausetime - level.starttime - level.discardtime;
	}
	else
	{
		return getTime() - level.starttime - level.discardtime;
	}
}

onplayerdamage(inflictor, attacker, damage, idflags, type, weapon_used, point, dir, shitloc, offsettime){
	damage = 0;

	if(type == "MOD_SUICIDE" || type == "MOD_TRIGGER_HURT" || weapon_used == "hatchet_mp" || getweaponclass(weapon_used) == "weapon_sniper"){
		damage = 999;
	}

	if ((distance(self.origin, attacker.origin) * 0.0254) < 4 && self.name != attacker.name){
		if (weapon_used == "hatchet_mp" || getweaponclass(weapon_used) == "weapon_sniper"){
		attacker iprintlnbold("^1barrel stuff!");
		}
		damage = 0;
	}

	return damage;
}

randomgun(){
	self.weapon_list[0] = "tar21_mp";
	self.weapon_list[1] = "type95_mp";
	self.weapon_list[2] = "hk416_mp";
	
	self.all_weapons = self GetWeaponsListPrimaries();

	for(;;){
		self.random_weapon = self.weapon_list[RandomIntRange(0, self.weapon_list.size)];

		if (self.random_weapon == self.all_weapons[0] || self.random_weapon == self.all_weapons[1]){

		}
		else{
		self giveweapon(self.random_weapon, 0, 0);
		self dropitem(self.random_weapon);
		self thread maps/mp/gametypes/_class::giveloadout(self.team, self.class);

		self iprintlnbold("Dropped a weapon!");
		break;
		}
		wait 0.01;
	}
}

large_message(title, subtitle, icon, duration)
{
	self endon("disconnect");																										//kill on disconnect
	self endon("death");																											//kill on death
	
	notifydata = spawnstruct();																										//create class with stuff;
	notifydata.titletext = title;																										//text
	notifydata.notifytext = subtitle;																									//subtitle
	notifydata.iconname = icon;																											//icon
		notifydata.iconwidth = 150;
		notifydata.iconheight = 50;
		notifydata.iconalpha = 0.8;
	notifydata.duration = duration;																										//duration
	notifydata.glowcolor = (0, 0, 0);																									//glowcolor
	notifydata.font = "default";																										//font
	
	self thread notifymessage(notifydata);																							//Send the class thru notifymessage.
}

on_respawn(){
	for (;;){
	self waittill("spawned_player");
	self useServerVisionSet(true);
	self SetVisionSetforPlayer("default", 0);
	self freezecontrols(false);
	}
}

toggle_floater(){
	if (self.floaters == true){
		self.floaters = false;
		self iprintln("Floaters disabled");
		self notify("quit_floater");
	}else{
		self.floaters = true;
		self iprintln("Floaters enabled");
		self thread floaters();
	}
}

floaters(){
	self endon("disconnect");
	self endon("quit_floater");
	level waittill("game_ended");

	for (;;){
		self SetVelocity(self GetVelocity() - self GetVelocity());
		wait 0.01;
	}
}

position_loader(state, enabled, player_angles, player_origin){
	if (state == "save"){
		self iprintln("Position saved");
		return true;
	} 
	else {
		if (enabled){
			self setplayerangles(player_origin);
        	self setorigin(player_angles);
			self iprintln("Position loaded");
		} else {
			self iprintln("Save a position first");
		}
	}
}

create_square(shader, x, y, width, height, color, alpha, sort, align, relative)
{
    hud = newClientHudElem(self);
    hud.elemtype = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
	hud.children = [];
	hud setparent(level.uiParent);
    hud setshader(shader, width, height);
	hud setpoint(align,relative,x,y);
    return hud;
}

create_text(text, font, fontScale, x, y, color, alpha, glow_color, glow_alpha, sort, relative, align)
{
	hud = self createFontString(font, fontScale);
	hud.color = color;
	hud.alpha = alpha;
	hud.glowcolor = glow_color;
	hud.glowalpha = glow_alpha;
	hud.sort = sort;
	hud.alpha = alpha;
	hud settext(text);
	hud setpoint(align, relative, x, y);
	return hud;
}


monitor_buttons(){
	self endon("disconnect");

	self.position_saved = false;
	self.floaters = false;
	self.cursor_count = 0;

	self.usebutton_isstillheld = false;
	self.has_proned = false;
	
	self.menuoptions = [];
	self.menuoptions[0] = "^1can-swap";
	self.menuoptions[1] = "^1fill killstreaks";
	self.menuoptions[2] = "^1floaters";
	self.menuoptions[3] = "^1load waypoint";
	self.menuoptions[4] = "^1set waypoint";

	for(;;){
		if (self actionslotonebuttonpressed() && self getstance() == "prone") self.cursor_count++;
		if (self actionslottwobuttonpressed() && self getstance() == "prone") self.cursor_count--;
		
		if (self.cursor_count < 0) self.cursor_count = self.menuoptions.size - 1;
		if (self.cursor_count > self.menuoptions.size -1) self.cursor_count = 0;

		if (self usebuttonpressed() && !self.usebutton_isstillheld && self getstance() == "prone"){
			if (self.cursor_count == 0) self thread randomgun();
			if (self.cursor_count == 1) maps/mp/gametypes/_globallogic_score::_setplayermomentum(self, 1900);
			if (self.cursor_count == 2) self thread toggle_floater();
			if (self.cursor_count == 3){self position_loader("load", self.position_saved, self.player_origin, self.player_angles);}
			if (self.cursor_count == 4){self.player_origin = self.origin; self.player_angles = self.angles; self.position_saved = self position_loader("save", self.position_saved, self.player_origin, self.player_angles);}

			self.usebutton_isstillheld = true;
		}

		if (!self usebuttonpressed() && self.usebutton_isstillheld) self.usebutton_isstillheld = false;

		if (self getstance() == "prone"){
			self.has_proned = true;

			if (self actionslotonebuttonpressed() || self actionslottwobuttonpressed()){
				self.display_time = 60;
			}
			
			self.display_time++;
			if(self.display_time > 60){
				self.display_time = 0;
				self iprintlnbold(self.menuoptions[self.cursor_count]);
			}
		}
		
		if (self getstance() != "prone" && self.has_proned) {
			self.has_proned = false;

			self.display_time = 60;
			self iprintlnbold(" ");
		}
		wait 0.05;
	}
}
