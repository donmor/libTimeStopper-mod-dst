# libTimeStopper

[中文](Readme.md) | English

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
- ##### 目标无敌
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
    |`<number>timestopper.onresumingtime`|Define how many seconds before the end of time-stop will `onresumingfn` be executed, defined by method `SetOnResumingFn`|
    |`<function>timestopper.onresumingfn`|Callback that is called a few seconds before the end of time-stop, defined by method `SetOnResumingFn`, usually used on effects|
    |`<function>timestopper.onresumedfn`|Callback that is called on the end of time-stop, defined by method `SetOnResumedFn`, usually used on effects|
    |`<listener>timestopper.resumedlistener`|Internal listener to call `onresumedfn`|
    
    |Method|Description|
    |-|-|
    |`timestopper:DoTimeStop(time, silent, nogrey)`|Perform a time-stop and make the entity able to move in stopped time for a few seconds|
    |`timestopper:StopTimeFor(time, host, silent, nogrey)`|Perform a time-stop for a specific entity, making it able to move in stopped time for a few seconds, as well as this entity|
    |`timestopper:SetOnTimeStoppedFn(fn)`|Define the callback that is called on time-stop successfully performed by the entity|
    |`timestopper:SetOnResumingFn(time, fn)`|Define a callback that is called a specifit time before the end of time-stop|
    |`timestopper:SetOnResumedFn(fn)`|Define the callback that is called on the end of time-stop|
    |`timestopper:OnRemoveFromEntity()`|Internal call that remove the `resumedlistener`|
    ###### timestopper:DoTimeStop(time, silent, nogrey)
    Perform a time-stop, add tag `stoppingtime` to the entity，并获得相应的可活动时间。如果在已经停止的时间中调用此函数，则获得相应的可活动时间，如果剩余时长小于自身可活动时间，还将延长本次时停。当被实体储物栏中的物品调用时，时间停止将由物主发动。
    
        参数 <number>time             要停止的时间，单位为秒，必须大于0（否则报错退出）。
        参数 <bool>silent             是否静默发动时停，可以被省略。此参数将被传递到回调ontimestoppedfn及onresumingtime中，通常用于控制是否需要播放特效。当在停止的时间中调用时，此参数被true覆盖。
        参数 <bool>nogrey             是否忽略内置灰屏特效，可以被省略。当在停止的时间中调用时忽略此参数。
    ###### timestopper:StopTimeFor(time, host, silent, nogrey)
    发动一次时间停止能力，向某实体附加Tag`stoppingtime`，并获得相应的可活动时间；自身实体亦获得相等的可活动时间。此函数通常用于随从生物。如果在已经停止的时间中调用此函数，则获得相应的可活动时间，如果剩余时长小于自身可活动时间，还将延长本次时停。
    
        参数 <number>time             要停止的时间，单位为秒，必须大于0（否则没有任何效果）。
        参数 <entity>host             要停止时间的实体。如果省略，则相当于执行DoTimeStop。
        参数 <bool>silent             是否静默发动时停，可以被省略。此参数将被传递到回调ontimestoppedfn及onresumingtime中，通常用于控制是否需要播放特效。当在停止的时间中调用时，此参数被true覆盖。
        参数 <bool>nogrey             是否忽略内置灰屏特效，可以被省略。当在停止的时间中调用时忽略此参数。
    ###### timestopper:SetOnTimeStoppedFn(fn)
    定义由此实体成功发动时停时执行的回调函数。此函数通常用于播放特效。
    
        参数 <function(silent)>fn     要执行的回调函数。
            参数 <bool>silent             是否静默发动。该参数自DoTimeStop传入，通常用于判断此次是否需要播放特效。
    ###### timestopper:SetOnResumingFn(time, fn)
    定义由此实体发动的时停即将结束时执行的回调函数。此函数通常用于播放特效。
    
        参数 <number>time             定义在时停结束前多少秒执行回调。省略则和SetOnResumedFn定义的回调一同执行；为负则在时停结束数秒后执行。
        参数 <function(silent)>fn     要执行的回调函数。此函数将被TimeStopper_World暂存，并可被另一持有TimeStopper的实体覆盖。
            参数 <bool>silent             是否静默发动。该参数自DoTimeStop传入，通常用于判断此次是否需要播放特效。
    ###### timestopper:SetOnResumedFn(fn)
    定义时间停止结束后调用的回调函数。此回调函数将在所有持有`TimeStopper`的实体调用，通常用于播放特效。
    
        参数 <function(silent)>fn     要执行的回调函数。
            参数 <bool>silent             是否静默发动。该参数自DoTimeStop传入，通常用于判断此次是否需要播放特效。
    ###### timestopper:OnRemoveFromEntity()
    系统调用，清理`resumedlistener`。一般不应被任何第三方代码调用。
- ##### TimeStopper_World
    适用对象：世界（服务端）
    
    此Component仅由世界实体持有，是时间停止的实际执行模块。
    |Field|Description|
    |-|-|
    |`<entity>timestopper_world.inst`|Entity itself (i.e. `TheWorld`)|
    |`<table>timestopper_world.twents`|时间停止过程中受影响的所有实体|
    |`<function>timestopper_world.releasingfn`|时间停止即将结束时调用的回调函数，由成员函数`DoTimeStop`传入并暂存，通常用于播放特效|

    |Method|Description|
    |-|-|
    |`timestopper:OnPeriod()`|时间停止过程中被定期调用，停止可以被停止的实体并加入`twents`表中|
    |`timestopper:OnResume()`|时间停止结束时被调用，解放`twents`表中的实体|
    |`timestopper:DoTimeStop(time, host, silent, nogrey)`|将世界的时间停止一段时间，并使指定实体获得相应的可活动时间|
    |`timestopper:ResumeEntity(ent, time)`|立即释放指定实体并使其获得相应的可活动时间|
    |`timestopper:OnRemoveFromEntity()`|系统调用，清理世界实体的Tag|
    ###### timestopper:OnPeriod()
    时间停止过程中被定期调用，以每个玩家为中心，发现世界中满足条件的实体，停止其关键功能，附加Tag`time_stopped`并加入`twents`表中。一般不应被此Component以外的代码调用。

    以下实体不会被停止：
    - 带有Tag`wall`的实体
    - 已经被停止并附加Tag`time_stopped`的实体
    - 被附加Tag`canmoveintime`的实体（通常被赋予有限的行动时间）
    - 带有Tag`INLIMBO`的实体
    - 可以行动的温蒂对应的阿比盖尔
    - 受理智影响的暗影生物（可在配置中关闭此项）
    ###### timestopper:OnResume()
    时间停止结束时被调用，以每个玩家为中心，解放`twents`表中的所有实体，移除Tag`time_stopped`。一般不应被此Component以外的代码调用。
    ###### timestopper:DoTimeStop(time, host, silent, nogrey)
    将世界的时间停止一段时间，向指定实体附加Tag`stoppingtime`和`canmoveintime`，使其获得相应的可活动时间。在此期间，世界实体将被附加Tag`the_world`，时钟停止运行。如果在静止的时间内调用，则将剩余时长延长到指定时间（如果更长），并释放指定实体。

        参数 <number>time             要停止的时间，单位为秒，必须大于0（否则没有任何效果）。
        参数 <entity>host             要赋予可活动时间的实体。如果省略则不赋予任何实体可活动时间。
        参数 <bool>silent             是否静默发动时停，可以被省略。此参数将被传递到回调中，通常用于控制是否需要播放特效。当在停止的时间中调用时，此参数被true覆盖。
        参数 <bool>nogrey             是否忽略内置灰屏特效，可以被省略。当在停止的时间中调用时忽略此参数。
    ###### timestopper:ResumeEntity(ent, time)
    立即释放指定实体，附加Tag`canmoveintime`并使其获得相应的可活动时间，温蒂玩家的阿比盖尔也会被一同释放。注意此函数不会向实体附加Tag`stoppingtime`。

        参数 <entity>ent              要赋予可活动时间的实体，必须不为nil并可用（否则没有任何效果）。
        参数 <number>time             要赋予的可活动时间，单位为秒，必须大于0（否则没有任何效果）。
    ###### timestopper:OnRemoveFromEntity()
    系统调用，清理世界实体的Tag。一般不应被任何第三方代码调用。
#### Netvars
- ##### <net_float>instoppedtime
    宿主：全体玩家实体

    事件：`instoppedtime`

    用于在时停发动及结束时向所有玩家推送相关数据。发动时被赋予一个非0的值，其绝对值等于时停发动时指定的长度，若指定了nogrey，则符号为负；结束时被赋0。默认用于实现灰屏特效。
- ##### <net_string>globalsound
    宿主：全体玩家实体

    事件：`globalsound`

    用于向全体玩家推送一段音效。此音效将以世界（客户端）为宿主播放。
#### Events
- ##### instoppedtime
    当进入或退出静滞时间时触发，默认用于灰屏特效及天气粒子控制。

        触发 TimeStopper_World        当进入或退出静滞时间时，在每个玩家实体通过为Netvar赋值触发此事件。
        监听 全体玩家实体(客户端)      被触发时将读取同名Netvar的值，若为正值并使显示反色，0.5秒后视野变灰；不足0.5则只使视野变灰；若为0则使视野恢复原状。此外还将向天气实体（客户端）推送同名事件。
        监听 所有天气实体(客户端)      被触发时将读取同名Netvar的值，若为非0值则使天气粒子呈现静滞状态，否则将其恢复正常。
- ##### globalsound
    通过为Netvar赋值手动触发，向玩家推送一段音效。

        监听 全体玩家实体(客户端)      被触发时将读取同名Netvar的值，并以世界（客户端）为宿主播放。
- ##### time_stopped
    当实体被停止时触发，用于控制可燃物燃烧状态，也可手动监听。

        触发 TimeStopper_World        当燃烧中的实体被找到并停止时对其触发此事件。
        监听 正在燃烧的实体            被触发时停止并锁存燃尽倒计时器。
- ##### time_resumed
    当实体被释放时触发，用于控制可燃物燃烧状态，也可手动监听。

        触发 TimeStopper_World        当twents表中的实体被释放时对其触发此事件。
        监听 正在燃烧的实体            被触发时使用锁存的回调和剩余时间启动燃尽倒计时器。
- ##### the_world
    当世界进入静滞时间时触发，可手动监听。

        触发 TimeStopper_World        当执行timestopper_world:DoTimeStop时在世界实体（服务端）触发此事件。
- ##### the_world
    当世界进入静滞时间时触发，可手动监听。

        触发 TimeStopper_World        当时间停止结束时在世界实体（服务端）触发此事件。
        监听 所有持有TimeStopper的实体 被触发时调用回调函数onresumedfn。
#### Tags
- ###### time_stopped
    由`TimeStopper_World`附加在停止的实体上，标示实体处于被时停的状态。当释放实体时被移除。
- ###### the_world
    由`TimeStopper_World`附加在世界实体（服务端）上，标示世界处于被时停的状态。当时间停止结束时被移除。
- ###### canmoveintime
    执行`timestopper_world:ResumeEntity`时附加在指定实体上，标示此实体当前不受时停影响。当其可活动时间用尽时被移除，若此时仍处于静滞时间中，实体将在下一次执行`OnPeriod`时被停止。
- ###### timemaster
    对持有此Tag的实体，`TimeStopper_World`将不会对其附加或移除`canmoveintime`。此Tag通常与`canmoveintime`一起加入Prefab中，以创建永远不受影响的实体，如具有特殊设定的生物、道具，或者用于时间停止的特效等。
- ###### stoppingtime
    执行`timestopper_world:DoTimeStop`时附加在指定实体上，标示此实体请求了一次时间停止。当其请求的时间用尽时被移除。注意`timestopper_world:DoTimeStop`中会执行一次`timestopper_world:ResumeEntity`，所以会同时附加两个Tag，而只执行`timestopper_world:ResumeEntity`不会附加`stoppingtime`。这是为了区分主动停止时间和被施加时停无效保护的情况，当撤除保护时应同时检查这两个Tag。
