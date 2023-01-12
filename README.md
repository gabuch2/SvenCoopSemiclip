# Sven Co-op Semiclip

Sven Co-op Semiclip is an AMXX plugin [that provides exactly what it says](https://tvtropes.org/pmwiki/pmwiki.php/Main/ExactlyWhatItSaysOnTheTin). This new version of Semiclip plugin works after all updates broke the previous methods.

### Current Problems

* Due to the great amount of engine changes Svengine suffered over the time, the older Metamod implementation broke and apparently there wasn't a way to fix it.
* anggaranothing released a [new version of Semiclip using Sven Co-op's own scripting language, AngelScript](https://gitlab.com/an-sc-projects/svencoop-as-semiclip). However, there are several problems that affect the functionality and make playing with this plugin more a hassle than an improvement:
  * This implementation uses groupinfo, making the players invisible when nearby.
  * This may also break custom maps that make use of this.
  * AngelScript doesn't have AddToFullPack, so it's actually impossible to render players using AS alone, [you could in theory "fix" this by using AMXX](https://github.com/gabuch2/Sven_Semiclip_Utils). 
  * Sven Co-op made a small change that automatically unstuck colliding players, so if you try to boost someone there are high chances that you will be sent flying away.


### Solution (This plugin)

* This plugin uses Orpheu and hooks directly in the function responsible for allowing collision between entities.
AddToFullPack is also implemented, so players will not rubberband when going through each other.
* Boosting between players feels extremely smooth, almost native. Although it still a little trickier to reach higher places, because you need to jump before the player below stands up or else you'll fall through.
* It gives us more liberty on a easy to read code, it will allow us to implement more features like PVP support on maps that support it. (Which is currently a to-do!)


### Requirements

* [Orpheu](https://github.com/Arkshine/Orpheu/releases)
* [Updated Orpheu signatures for Svengine](https://github.com/gabuch2/OrpheuSignatures/archive/refs/heads/Svengine.zip) (click to get the latest version of the signatures I made)


### Cvars

* **amx_semiclip_enabled**
  * Enables the plugin. Takes effect on map start. Default 1.


### Changelog

* 1.2
  * Fixes more cases where players can get stuck inside pushables
  * Players will no longer crush each other while trying to use the same door or going through each other in a lift
    * Note that there are still cases where players might smash themselves when jumping on each other in elevators, although thanks to the plugin this happens rarely. It's a quirk on the engine that probably will never be able to be fixed
* 1.1
  * Fixed the plugin not calling the proper AddToFullPack function (Fixes jittery movement)
  * Fixed a bug where players can get stuck inside pushables
* 1.0.1
  * Removed unneeded include
* 1.0
  * Initial Release


### Credits

* [Th3-822](https://github.com/Th3-822)
   * Helped me a lot with Orpheu and explaining me how the game works internally, and pretty much this plugin wouldn't be possible if it wasn't for him.
