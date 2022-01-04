## Updater

Updater is originally made by GOD-Tony, as a tool to make the plugins easier than ever to update.

The original AlliedModders thread: https://forums.alliedmods.net/showthread.php?p=1570806

## Requirements
```
cURL (Dropped support on 1.3.0)
Socket
SteamTools (Dropped support 1.3.0)
SteamWorks (Recommended.)
```

## Cvars
```
sm_updater <1|2|3> - Determines update functionality.
   1 = Only notify in the log file when an update is available.
   2 = Automatically download and install available updates. *Default
   3 = Include the source code with updates.
```

## Commands
```
sm_updater_check - Forces Updater to check all plugins for updates. Can only be run once per hour.
sm_updater_forcecheck - Forces Updater to check all plugins for updates. This has no limits (Be aware of errors.)
sm_updater_status - View the status of Updater.

```


## About this Fork

This fork is made to 'continue' the support for the plugin, keeping it up-to-date since the author hasn't been active much and plugin hasn't been updated in a long while.

All credits goes to GOD-Tony for originally creating Updater.
