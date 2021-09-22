# libTimeStopper

中文 | [English](README.en.md)

libTimeStopper是一个向饥荒联机版添加了时间停止系能力相关代码的支持库类MOD。
### 主要特性
- 基于服务器端Component的代码
- 支持在玩家、生物、物品、随从中部署
- 发动期间时钟停止、腐烂及燃烧暂停，生物血量归零后在时停结束瞬间才死亡
- 投射物时停期间浮空效果
- 时停发动、结束支持加入回调
- 支持通过控制台触发时停
- 在停止的时间内发动时停可以获得能够活动的时间
- 自身可支配时间长于上一个发动者时，可以使其陷入自身的时停
- 自带全玩家灰屏特效，可在代码中覆盖
- 全局音效模块
### 选项设置
- ##### 时间停止模式
    有关时间停止的性能选项
    |||
    |-|-|
    |性能模式|停止半径50范围内的实体，一般用于入门机型|
    |普通模式|停止半径500范围内的实体，可用于大部分机型[默认]|
    |强力模式|停止半径2000范围内的实体，适用于服务器及高端机型|
    |极限模式|停止半径9001范围内的实体，可能卡顿严重，需谨慎考虑|
- ##### 排除影怪
    时间停止对暗影生物的影响，通常取决于相关MOD世界观设定等
    |||
    |-|-|
    |开启|理智相关类影怪（如低理智时出现的）不受时间停止影响[默认]|
    |关闭|所有类型影怪均可被时停|
- ##### 排除沃拓克斯
    使沃拓克斯在任何时候不受时停影响，此选项基于沃拓克斯的官方描述
    |||
    |-|-|
    |开启|沃拓克斯不受时间停止影响|
    |关闭|沃拓克斯可被时停[默认]|
- ##### 排除旺达
    使旺达在任何时候不受时停影响，此选项基于旺达的官方描述
    |||
    |-|-|
    |开启|旺达不受时间停止影响|
    |关闭|旺达可被时停[默认]|
- ##### 排除查理
    时间停止对查理的影响，通常取决于相关MOD世界观设定等
    |||
    |-|-|
    |开启|查理不受时间停止影响[默认]|
    |关闭|查理在时停中无法攻击|
- ##### 目标无敌
    时间停止时是否可以直接攻击目标，通常取决于相关MOD世界观设定等
    |||
    |-|-|
    |开启|时停状态对目标无法直接造成伤害|
    |关闭|可以在时停状态对目标造成伤害[默认]|
- ##### 全局灰屏特效
    时停时应用全局灰屏特效，可在代码中覆盖
    |||
    |-|-|
    |开启|时停状态玩家显示变灰[默认]|
    |关闭|不对玩家显示进行处理|
### 参考文档
#### Components
- ##### TimeStopper
    适用对象：普通实体（玩家、生物、物品、建筑等）
    
    持有此Component的实体可以通过少量代码实现时间停止功能。
    |成员变量|描述|
    |-|-|
    |`<entity>timestopper.inst`|持有此Component的实体自身|
    |`<entity>timestopper.host`|此实体的主实体|
    |`<function>timestopper.ontimestoppedfn`|时间停止成功由此实体发动后调用的回调函数，由成员函数`SetOnTimeStoppedFn`定义，通常用于播放特效|
    |`<number>timestopper.onresumingtime`|时间停止结束前要执行回调的提前秒数，由成员函数`SetOnResumingFn`定义|
    |`<function>timestopper.onresumingfn`|时间停止即将结束时调用的回调函数，由成员函数`SetOnResumingFn`定义，通常用于播放特效|
    |`<function>timestopper.onresumedfn`|时间停止结束后调用的回调函数，由成员函数`SetOnResumedFn`定义，通常用于播放特效|
    |`<listener>timestopper.resumedlistener`|初始化Component时内部定义的监听，用于调用`onresumedfn`|
    
    |成员函数|描述|
    |-|-|
    |`timestopper:GetHost()`|获取此实体的主实体|
    |`timestopper:SetHost(host)`|定义此实体的主实体|
    |`timestopper:DoTimeStop(time, silent, nogrey)`|发动一次时间停止能力，并使此实体及主实体获得相应的可活动时间|
    |`timestopper:BreakTimeStop()`|尝试立即使时间停止结束|
    |`timestopper:SetOnTimeStoppedFn(fn)`|定义由此实体成功发动时停时执行的回调函数|
    |`timestopper:SetOnResumingFn(time, fn)`|定义由此实体发动的时停即将结束时执行的回调函数|
    |`timestopper:SetOnResumedFn(fn)`|定义由此实体成功发动时停时执行的回调函数|
    |`timestopper:OnRemoveFromEntity()`|系统调用，清理`resumedlistener`|
    ###### timestopper:GetHost()
    获取此实体的主实体。若未通过`SetHost`定义则返回实体本身。
    ###### timestopper:SetHost(host)
    定义此实体的主实体。
    
        参数 <entity>host             要与之绑定的实体。
    ###### timestopper:DoTimeStop(time, silent, nogrey)
    发动一次时长`time`的时间停止，向此实体附加Tag`stoppingtime`和`canmoveintime`，并获得`time`秒可活动时间。如果在已经停止的时间中调用此函数，则获得`time`秒可活动时间，如果剩余时长小于自身可活动时间，还将延长本次时停。当额外定义了主实体时，也向主实体附加Tag并使其在时停中活动。
    
        参数 <number>time             要停止的时间，单位为秒，必须非0（否则没有任何效果）。负值表示一直停止时间。
        参数 <bool>silent             是否静默发动时停，可以被省略。此参数将被传递到回调ontimestoppedfn及onresumingtime中，通常用于控制是否需要播放特效。
        参数 <bool>nogrey             是否忽略内置灰屏特效，可以被省略。当在停止的时间中调用时忽略此参数。
    ###### timestopper:BreakTimeStop()
    发动时停期间可用，立即使时间停止结束，除非自身可活动时间短于总剩余时间。尤其适用将负值传入了`DoTimeStop`的情况。
    ###### timestopper:SetOnTimeStoppedFn(fn)
    定义由此实体成功发动时停时执行的回调函数。此函数通常用于播放特效。
    
        参数 <function(silent)>fn     要执行的回调函数。
            参数 <bool>silent             是否静默发动。该参数自DoTimeStop传入，通常用于判断此次是否需要播放特效。当在停止的时间中调用DoTimeStop时，此参数被true覆盖。
    ###### timestopper:SetOnResumingFn(time, fn)
    定义由此实体发动的时停即将结束时执行的回调函数。此函数通常用于播放特效。
    
        参数 <number>time             定义在时停结束前多少秒执行回调。省略则和SetOnResumedFn定义的回调一同执行；为负则在时停结束time后执行。
        参数 <function()>fn     要执行的回调函数。此函数将被TimeStopper_World暂存，并可被另一持有TimeStopper的实体覆盖。
    ###### timestopper:SetOnResumedFn(fn)
    定义时间停止结束后调用的回调函数。此回调函数将在所有持有`TimeStopper`的实体调用，通常用于播放特效。
    
        参数 <function()>fn     要执行的回调函数。
    ###### timestopper:OnRemoveFromEntity()
    系统调用，清理`resumedlistener`。一般不应被任何第三方代码调用。
- ##### TimeStopper_World
    适用对象：世界（服务端）
    
    此Component仅由世界实体持有，是时间停止的实际执行模块。
    |成员变量|描述|
    |-|-|
    |`<entity>timestopper_world.inst`|持有此Component的实体自身（`TheWorld`）|
    |`<table>timestopper_world.twents`|时间停止过程中受影响的所有实体|
    |`<function>timestopper_world.releasingfn`|时间停止即将结束时调用的回调函数，由成员函数`DoTimeStop`传入并暂存，通常用于播放特效|

    |成员函数|描述|
    |-|-|
    |`timestopper_world:OnPeriod()`|时间停止过程中被定期调用，停止可以被停止的实体并加入`twents`表中|
    |`timestopper_world:OnResume()`|时间停止结束时被调用，释放`twents`表中的实体|
    |`timestopper_world:DoTimeStop(time, host, silent, nogrey)`|将世界的时间停止一段时间，并使指定实体获得相应的可活动时间|
    |`timestopper_world:ResumeEntity(ent, time)`|立即释放指定实体并使其获得相应的可活动时间|
    |`timestopper_world:BreakTimeStop()`|立即使时间停止结束|
    |`timestopper_world:BreakMovability(ent)`|使某个实体不再能在时停中活动|
    |`timestopper_world:OnRemoveFromEntity()`|系统调用，清理世界实体的Tag|
    ###### timestopper_world:OnPeriod()
    时间停止过程中被定期调用，以每个玩家为中心，发现世界中满足条件的实体，停止其关键功能，附加Tag`time_stopped`并加入`twents`表中。一般不应被此Component以外的代码调用。

    以下实体不会被停止：
    - 带有Tag`wall`的实体
    - 已经被停止并附加Tag`time_stopped`的实体
    - 被附加Tag`canmoveintime`的实体（通常被赋予有限的行动时间）
    - 带有Tag`INLIMBO`的实体
    - 可以行动的温蒂对应的阿比盖尔
    - 受理智影响的暗影生物（可在配置中关闭此项）
    ###### timestopper_world:OnResume()
    时间停止结束时被调用，释放`twents`表中的所有实体，移除Tag`time_stopped`。一般不应被此Component以外的代码调用。
    ###### timestopper_world:DoTimeStop(time, host, silent, nogrey)
    将世界的时间停止`time`秒，向`host`附加Tag`stoppingtime`和`canmoveintime`，使其获得`time`秒可活动时间。在此期间，世界实体将被附加Tag`the_world`，时钟停止运行。如果在静止的时间内调用，则将剩余时长延长到指定时间（如果更长），并释放`host`。

        参数 <number>time             要停止的时间，单位为秒，必须非0（否则没有任何效果）。负值表示一直停止时间。
        参数 <entity>host             要赋予可活动时间的实体。如果省略则不赋予任何实体可活动时间。
        参数 <bool>silent             是否静默发动时停，可以被省略。此参数将被传递到回调中，通常用于控制是否需要播放特效。
        参数 <bool>nogrey             是否忽略内置灰屏特效，可以被省略。当在停止的时间中调用时忽略此参数。
    ###### timestopper_world:ResumeEntity(ent, time)
    立即释放指定实体，附加Tag`canmoveintime`并使其获得`time`秒可活动时间，温蒂玩家的阿比盖尔也会被一同释放。注意此函数不会向实体附加Tag`stoppingtime`。

        参数 <entity>ent              要赋予可活动时间的实体，必须不为nil并可用（否则没有任何效果）。
        参数 <number>time             要赋予的可活动时间，单位为秒，必须非0（否则没有任何效果）。负值表示一直可活动。
    ###### timestopper_world:BreakTimeStop()
    立即使时间停止结束。尤其适用将负值传入了`DoTimeStop`的情况。
    ###### timestopper_world:BreakMovability(ent)
    使某个实体不再能在时停中活动。尤其适用将负值传入了`DoTimeStop`或`ResumeEntity`的情况。

        参数 <entity>ent              要撤销可活动时间的实体，必须不为nil并可用（否则没有任何效果）。
    ###### timestopper_world:OnRemoveFromEntity()
    系统调用，清理世界实体的Tag。一般不应被任何第三方代码调用。
#### Netvars
- ###### <net_float>instoppedtime
    宿主：全体玩家实体

    事件：`instoppedtime`

    用于在时停发动及结束时向所有玩家推送相关数据。
- ###### <net_string>globalsound
    宿主：全体玩家实体

    事件：`globalsound`

    用于向全体玩家推送一段音效。此音效将以世界（客户端）为宿主播放。
#### Events
- ###### instoppedtime
    当进入或退出静滞时间时触发，默认用于灰屏特效及天气粒子控制，也可手动监听。

        触发 TimeStopper_World        当进入或退出静滞时间时，在每个玩家实体通过为Netvar赋值触发此事件。
        触发 全体玩家实体(客户端)      此事件在玩家实体被触发时，在所有天气实体触发同名事件。
        监听 全体玩家实体(客户端)      被触发时将读取同名Netvar的值，若为正值则使显示反色，0.25秒后视野变灰；不足1秒则只使视野变灰；若为0则使视野恢复原状。此外还将向天气实体（客户端）推送同名事件。
        监听 所有天气实体(客户端)      被触发时将读取同名Netvar的值，若为非0值则使天气粒子呈现静滞状态，否则将其恢复正常。
- ###### globalsound
    通过为Netvar赋值手动触发，向玩家推送一段音效。每次赋值必须不同于上一次才能触发事件，可以通过在服务端隔0.1秒执行`globalsound:set_local("")`解决。

        监听 全体玩家实体(客户端)      被触发时将读取同名Netvar的值，并以世界（客户端）为宿主播放。
- ###### time_stopped
    当实体被停止时触发，用于控制可燃物燃烧状态，也可手动监听。

        触发 TimeStopper_World        当实体被找到并停止时对其触发此事件。
        监听 正在燃烧的实体            被触发时停止并锁存燃尽倒计时器。
- ###### time_resumed
    当实体被释放时触发，用于控制可燃物燃烧状态，也可手动监听。

        触发 TimeStopper_World        当twents表中的实体被释放时对其触发此事件。
        监听 正在燃烧的实体            被触发时使用锁存的回调和剩余时间启动燃尽倒计时器。
- ###### the_world
    当世界进入静滞时间时触发，可手动监听。

        触发 TimeStopper_World        当执行timestopper_world:DoTimeStop时在世界实体（服务端）触发此事件。
- ###### the_world_end
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
    持有此Tag的实体将不会被附加或移除`canmoveintime`。此Tag通常与`canmoveintime`一起加入Prefab中，以创建永远不受影响的实体，如具有特殊设定的生物、道具，或者用于时间停止的特效等。
- ###### stoppingtime
    执行`timestopper_world:DoTimeStop`时附加在指定实体上，标示此实体请求了一次时间停止。当其请求的时间用尽时被移除。注意`timestopper_world:DoTimeStop`中会执行一次`timestopper_world:ResumeEntity`，所以会同时附加两个Tag，而只执行`timestopper_world:ResumeEntity`不会附加`stoppingtime`。这是为了区分主动停止时间和被施加时停无效保护的情况，当撤除保护时应同时检查这两个Tag。
