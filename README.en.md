# libTimeStopper

[中文](README.md) | English

A Don't Starve Together library mod providing APIs for time-stopping abilities.
### Features
- Code based on server-side components
- Deployed on players, mobs, items, followers and more
- Pause the world clock and all perishment and burning; Entities won't reach its death if HP=0, until the time resumes
- Projectiles floats in the air during the stopped time
- Callbacks can be added to the begining and the end of stopped time
- Triggering time-stop via console
- Getting able to move in stopped time by use time-stop ability
- Trapping the previous time-stopper into stopped time by using the ability at the end of stopped time 
- All-player grey screen effect, can be overrided
- Global SE module
## Options
- ##### Time-stopping mode
    Performance options of time-stop
    |||
    |-|-|
    |Performance mode|Stop entities in a radius of 50, usually for low-end devices|
    |Normal mode|Stop entities in a radius of 500, for major devices[default]|
    |Powered mode|Stop entities in a radius of 2000, usually for servers and high-end devices|
    |Extreme mode|Stop entities in a radius of 9001, with many lags so use on your own risk|
- ##### Ignore shadow creatures
    Toggle how time-stop affects shadow creatures, usually depend on worldview of related mods
    |||
    |-|-|
    |Enable|Shadow creatures that affected by sanity will be ignored[default]|
    |Disable|All shadow creatures could be time-stopped|
- ##### Ignore Wortox
    Make Wortox always able to move in stopped time, because he "Can hop through time and space"
    |||
    |-|-|
    |Enable|Wortox won't be stopped|
    |Disable|Wortox could be stopped[default]|
- ##### Ignore Wanda
    Make Wanda always able to move in stopped time, because she "Has excellent time management skills"
    |||
    |-|-|
    |Enable|Wanda won't be stopped|
    |Disable|Wanda could be stopped[default]|
- ##### Ignore Charlie
    Toggle how time-stop affects Charlie, usually depend on worldview of related mods
    |||
    |-|-|
    |Enable|Charlie will not be affected by time-stop[default]|
    |Disable|Charlie won't attack in stopped time|
- ##### Invincible foe
    Toggle whether the target could be damaged in stopped time, usually depend on worldview of related mods
    |||
    |-|-|
    |Enable|Make entities invincible in stopped time|
    |Disable|Entities are not invincible in stopped time[default]|
- ##### Global grey screen effect
    Apply global grey screen effect, can be overrided
    |||
    |-|-|
    |Enable|Players' screens turn grey in stopped time[default]|
    |Disable|Make players' screens "as is"|
## Programming references
#### Components
- ##### TimeStopper
    Applicable to: normal entities (players, mobs, items, structures, etc.)
    
    Entities with this component can perform time-stop with few codes.
    |Field|Description|
    |-|-|
    |`<entity>timestopper.inst`|Entity itself|
    |`<function>timestopper.ontimestoppedfn`|Callback that is called on time-stop successfully performed by the entity, defined by method `SetOnTimeStoppedFn`, usually used on effects|
    |`<number>timestopper.onresumingtime`|Indicates how many seconds before the end of time-stop will `onresumingfn` be executed, defined by method `SetOnResumingFn`|
    |`<function>timestopper.onresumingfn`|Callback that is called a few seconds before the end of time-stop, defined by method `SetOnResumingFn`, usually used on effects|
    |`<function>timestopper.onresumedfn`|Callback that is called on the end of time-stop, defined by method `SetOnResumedFn`, usually used on effects|
    |`<listener>timestopper.resumedlistener`|Internal listener to call `onresumedfn`|
    
    |Method|Description|
    |-|-|
    |`timestopper:GetHost()`|Get the master entity of this entity|
    |`timestopper:SetHost(host)`|Define the master entity of this entity|
    |`timestopper:DoTimeStop(time, silent, nogrey)`|Perform a time-stop and make the master entity able to move in stopped time for a few seconds|
    |`timestopper_world:BreakTimeStop()`|Try resuming the stopped world immediately|
    |`timestopper:SetOnTimeStoppedFn(fn)`|Define a callback that is called on time-stop successfully performed by the entity|
    |`timestopper:SetOnResumingFn(time, fn)`|Define a callback that is called a specifit time before the end of time-stop|
    |`timestopper:SetOnResumedFn(fn)`|Define a callback that is called on the end of time-stop|
    |`timestopper:OnRemoveFromEntity()`|Internal call that removes `resumedlistener`|
    ###### timestopper:GetHost()
    Get the master entity of this entity. Return the entity itself if not defined.
    ###### timestopper:SetHost(host)
    Define the master entity of this entity.
    
        Parameter <entity>host                        The entity to be bound with. 
    ###### timestopper:DoTimeStop(time, silent, nogrey)
    Perform a time-stop for `time` seconds, tag it with `stoppingtime` to the master entity, and make it able to move in stopped time for `time` seconds. If called in stopped time, the entity will be able to move in stopped time for `time` seconds, and the stopped time will be extended if `time` is greater than remaining. The entity itsell will also able to move if the master entity is other than itself.
    
        Parameter <number>time                        The period of time (seconds) to stop, must greater than 0, otherwise nothing will be done.
        Parameter <bool>silent                        Define whether time-stop should be performed silently, may be ignored. This will be passed to callback `ontimestoppedfn` and `onresumingtime`, usually used on effects.
        Parameter <bool>nogrey                        Define whether the initial grey-screen should be disabled, may be ignored. Ignored if called in stopped time.
    ###### timestopper_world:BreakTimeStop()
    Immediately resume the stopped world if the entity is stopping the time. Fails if the remaining stopped time is longer than entity's remaining movable time. Used especially if passed a negative `time` to `DoTimeStop`.
    ###### timestopper:SetOnTimeStoppedFn(fn)
    Define a callback that is called on time-stop successfully performed by the entity. This callback is usually used on effects.
    
        Parameter <function(silent)>fn                The callback function.
            Parameter <bool>silent                        Indicates whether the time-stop is performed silently. This parameter comes from `DoTimeStop`, usually used to decide if the effect should be shown. Overrided by true if called in stopped time.
    ###### timestopper:SetOnResumingFn(time, fn)
    Define a callback that is called `time` seconds before the end of time-stop. This callback is usually used on effects.
    
        Parameter <number>time                        Define how many seconds before the end of time-stop will `onresumingfn` be executed. If ignored, the callback will be called along with `timestopper.onresumedfn`. Could be negative if a function should be called `time` seconds after time-stop.
        Parameter <function()>fn                The callback function. It will be preserved in `TimeStopper_World`, and could be overrided by another entity with `TimeStopper`.
    ###### timestopper:SetOnResumedFn(fn)
    Define a callback that is called on the end of time-stop. This callback will be call on all entities with `TimeStopper`, and is usually used on effects.
    
        Parameter <function()>fn                The callback function. 
    ###### timestopper:OnRemoveFromEntity()
    Internal call that removes `resumedlistener`. Must not be called by any 3rd-party code.
- ##### TimeStopper_World
    Applicable to : Worlds (server side)
    
    This component is only used with world entities. It is the actual performer of time-stop.
    |Field|Description|
    |-|-|
    |`<entity>timestopper_world.inst`|Entity itself (i.e. `TheWorld`)|
    |`<table>timestopper_world.twents`|All entities affected in current time-stop|
    |`<function>timestopper_world.releasingfn`|Callback that is called a few seconds before the end of time-stop, preserved in method `DoTimeStop`, usually used on effects|

    |Method|Description|
    |-|-|
    |`timestopper_world:OnPeriod()`|Periodically called during the stopped time, find and stop entities and add them to `twents`|
    |`timestopper_world:OnResume()`|Called on the end of stopped time, release all entities in `twents`|
    |`timestopper_world:DoTimeStop(time, host, silent, nogrey)`|Stop the time for a period, and make the entity able to move in stopped time|
    |`timestopper_world:ResumeEntity(ent, time)`|Release a specific entity immediately, and make it able to move in stopped time|
    |`timestopper_world:BreakTimeStop()`|Immediately resume the stopped world|
    |`timestopper_world:BreakMovability(ent)`|Make an entity no longer able to move|
    |`timestopper_world:OnRemoveFromEntity()`|Internal call that removes tags on world entities|
    ###### timestopper_world:OnPeriod()
    Periodically called during the stopped time, take each player as the center to find entities ready to be stopped, pause its critical functions, tag it with `time_stopped` and append it to `twents`. Usually not called outside this component.

    The entity will not be stopped if:
    - Having a tag `wall`
    - Having a tag `time_stopped` and has been stopped
    - Having a tag `canmoveintime` (Usually in a limited period)
    - Having a tag `INLIMBO`
    - Is Abigail along with a movable Wendy player
    - Shadow creatures appeared under a low sanity (can be disabled in options)
    ###### timestopper_world:OnResume()
    Called on the end of stopped time, release all entities in `twents`, remove their tag `time_stopped`. Usually not called outside this component.
    ###### timestopper_world:DoTimeStop(time, host, silent, nogrey)
    Stop the time for `time` seconds, tag it with `stoppingtime` and `canmoveintime` to `host`, making it able to move in stopped time. During the stopped time, the world entities will have a tag `the_world`, the world clock will be paused. If called in stopped time, the remaining time will be extended to `time` if latter is longer, and `host` will be released. If a master entity other than itself was defined, it'll also be made able to move, as well as the tags.

        Parameter <number>time                        The period of time (seconds) to stop, must non-zero, otherwise nothing will be done. Pass a negative value to stop the world for unlimited time.
        Parameter <entity>host                        The entity to be tagged and made able to move. If ignored, no entity will be made movable
        Parameter <bool>silent                        Define whether time-stop should be performed silently, may be ignored. This will be passed to callbacks, usually used on effects. Overrided by true if called in stopped time.
        Parameter <bool>nogrey                        Define whether the initial grey-screen should be disabled, may be ignored. Ignored if called in stopped time.
    ###### timestopper_world:ResumeEntity(ent, time)
    Release `ent` immediately, tag it with `canmoveintime`, and make it able to move in stopped time for `time` seconds. Abigail will be also released if along with `ent` that is a Wendy player. Note that this will not tag `ent` with `stoppingtime`.

        Parameter <entity>ent                         Entity to be made able to move in stopped time. Must not be `nil` and is valid or nothing will happen.
        Parameter <number>time                        The period of time (seconds) during which `ent` is movable. Must non-zero or nothing will happen. Pass anegative value to give it unlimited movable time.
    ###### timestopper_world:BreakTimeStop()
    Immediately resume the stopped world. Used especially if passed a negative `time` to `DoTimeStop`.
    ###### timestopper_world:BreakMovability(ent)
    Make an entity no longer able to move in stopped time. Used especially if passed a negative `time` to `DoTimeStop` or `ResumeEntity`.

        Parameter <entity>ent                         Entity to be made no longer able to move in stopped time. Must not be `nil` and is valid or nothing will happen.
    ###### timestopper_world:OnRemoveFromEntity()
    Internal call that removes tags on world entities. Must not be called by any 3rd-party code.
#### Netvars
- ###### <net_float>instoppedtime
    Host: All player entities

    Event: `instoppedtime`

    Used to push data to all players on enter or leave the stopped time.
- ###### <net_string>globalsound
    Host: All player entities

    Event: `globalsound`

    Used to push sound effects to all player. The SE will be player by the world entity (client side)
#### Events
- ###### instoppedtime
    Triggered on enter or leave the stopped time, initially used to control grey-screen and weather effects. May also be listened manually.

        Pusher   TimeStopper_World                    Triggered by setting the value of netvar with the same name for each player on enter or leave the stopped time.
        Pusher   All player entities (client side)    Triggered on all weather entities by player if an event with the same name is triggered on the player.
        Listener All player entities (client side)    If triggered, the netvar with the same name will be fetched. if it is positive, the color of the display will be reversed and then greyed out in 0.25s, or just greyed out if less than a second; the display will be set to normal if the value is 0. An event with the same name will be pushed to all weather entities.
        Listener All weather entities (client side)   If triggered, the netvar with the same name will be fetched. if it is a non-zero value, the weather particles will be freezed, otherwise they'll be released.
- ###### globalsound
    Manually triggered by setting the value of netvar with the same name, and push sound effects to the player. Note that the value must be different than before in order to trigger the event. A solution is to call `globalsound:set_local("")` 0.1s later on the server side.

        Listener All player entities (client side)    If triggered, the netvar with the same name will be fetched. The name of the SE will be passed to the sound emitter of the world entity (client side) and be played.
- ###### time_stopped
    Triggered on an entity being stopped, initially used to control the status of burnable entities. May also be listened manually.

        Pusher   TimeStopper_World                    Triggered on an entity being found and stopped.
        Listener All burning entities                 If triggered, the burn out countdown will be stopped and preserved .
- ###### time_resumed
    Triggered on an entity being released, initially used to control the status of burnable entities. May also be listened manually.

        Pusher   TimeStopper_World                    Triggered on an entity in `twents` being released.
        Listener All burning entities                 If triggered, A burn out countdown will be set up using preserved data.
- ##### the_world
    Triggered if the world enter the stopped state. May be listened manually.
        Pusher   TimeStopper_World                    Triggered on the world entities (server side) if `timestopper_world:DoTimeStop` is called.
- ##### the_world_end
    Triggered if the world leave the stopped state. May be listened manually.

        Pusher   TimeStopper_World                    Triggered on th world entities (server side) if the stopped time is released.
        Listener All entities with TimeStopper        Call `onresumedfn` if triggered。
#### Tags
- ###### time_stopped
    Tagged to a stopped entity by `TimeStopper_World`, indicating that the entity has been stopped. Removed if the entity is released.
- ###### the_world
    Tagged to the world entities (server side) by `TimeStopper_World`, indicating that the world has been stopped. Removed if the stopped time is over.
- ###### canmoveintime
    Tagged to a specific entity on calling `timestopper_world:ResumeEntity`, indicating that the entity won't be affected by time-stop. Removed if the entity ran out of its movable time, and it will be stopped on the next `OnPeriod` call, if still in the stopped time.
- ###### timemaster
    Entities with this will never be attached or removed with the `canmoveintime` tag. Usually used along with `canmoveintime` in prefabs, in order to create entities that can never be stopped, such as characters or items with special power, or effects used in stopped time.
- ###### stoppingtime
    Tagged to a specific entity on calling `timestopper_world:DoTimeStop`, indicating that the entity acquired a time-stop. Removed if ran out the required time. Note that `timestopper_world:DoTimeStop` calls `timestopper_world:ResumeEntity` for one time, so it tags the entity with all the two tags, but `stoppingtime` won't be tagged on the entity on calling `timestopper_world:ResumeEntity`. This is used to separate these situations: Stopping time use itself's ability, or be protected from being stopped. Chech both the two tags on removing the protection.
