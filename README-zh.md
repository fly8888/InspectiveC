# InspectiveC

*基于 MobileSubstrate 和 Fishhook 的 objc_msgSend 钩子工具,用于调试和检查目的。*

本项目基于 [itrace by emeau](https://github.com/emeau/itrace)、[AspectiveC by saurik](http://svn.saurik.com/repos/menes/trunk/aspectivec/AspectiveC.mm) 和 [Subjective-C by kennytm](http://networkpx.blogspot.com/2009/09/introducing-subjective-c.html)。

日志输出位置:
- 非沙盒环境: **/var/mobile/Documents/InspectiveC**
- 沙盒环境: **/var/mobile/Containers/Data/Application/\<App-Hex\>/Documents/InspectiveC**

在 InspectiveC 文件夹内,你可以找到 **\<exe\>/\<pid\>_\<tid\>.log** 格式的日志文件。

**你可以从 stable_debs 文件夹或我的 [软件源](http://apt.golddavid.com/) 下载 deb 包。**

**描述:**

这是一个用于记录 Objective-C 消息层次结构的检查工具。它目前可以:
- 监视特定对象
- 监视指定类的所有对象
- 监视特定的选择器(selector)

该工具完全兼容 arm64 架构 - 实际上,在 arm64 上功能更加完整,因为 arm32 上的 obj_msgSend[st|fp]ret 目前尚未被钩住。

注意:由于 iOS 10 和 11 上 MobileSubstrate 的限制,你必须使用 Fishhook 来替代 objc_msgSend。要启用这个功能,请使用 `USE_FISHHOOK=1` 进行编译,例如:
`make package USE_FISHHOOK=1 FOR_RELEASE=1 install`。

**功能特性:**
* 支持 arm64 架构(同时支持 arm32)
* 可监视特定对象
* 可监视特定类的实例
* 可监视特定选择器
* 可打印参数

**计划功能(无特定顺序):**
* 支持记录 blocks/替换的 C 函数
* 打印返回值
* 性能优化
  * 提升多线程性能

**示例输出:**

```
***-|SpringBoard@<0x15455d320> _run|***
  +|NSAutoreleasePool alloc|
    +|NSAutoreleasePool allocWithZone:| NULL
  -|NSAutoreleasePool@<0x170442a00> init|
  -|SpringBoard@<0x15455d320> _accessibilityInit|
    [更多输出...]
```

**使用方法:**

首先正确[安装 theos](http://iphonedevwiki.net/index.php/Theos/Setup) 并获取 iOS SDK。你可能需要修改 Makefile(比如 ARCHS 或 TARGET)和/或 InspectiveC.mm。我在 Mac 上使用 Clang 编译 - 如果你使用其他编译器,可能会遇到汇编代码相关的问题。

安装 deb 包后,你可以在 /usr/lib 中找到 **libinspectivec.dylib**。将这个 dylib 复制到 $THEOS/lib 目录,然后将 **InspectiveC.h** 复制到 $THEOS/include 目录。

**使用方式 0: 通过 Cycript 使用 InspectiveC(推荐)**

使用 Cycript 注入进程,然后粘贴一行命令来加载 InspectiveC。这个命令是 InspectiveC.cy 文件的编译版本 - 可以在 cycript/InspectiveC.compiled.cy 中找到。

确保从 Cydia 安装了 **Cycript**,并在第一个命令中将"SpringBoard"替换为你想要注入的进程名称。另外,当你不再需要 InspectiveC 时,别忘了 **重启 SpringBoard/结束应用**。

```c
// 将 SpringBoard 替换为你想要的进程名
root# cycript -p SpringBoard

// 粘贴初始化命令
cy# intFunc=new Type("v").functionWith(int);objFunc=new Type("v").functionWith(id);classFunc=new Type("v").functionWith(Class);selFunc=new Type("v").functionWith(SEL);voidFunc=new Type("v").functionWith(new Type("v"));objSelFunc=new Type("v").functionWith(id,SEL);classSelFunc=new Type("v").functionWith(Class,SEL);handle=dlopen("/usr/lib/libinspectivec.dylib",RTLD_NOW);setMaximumRelativeLoggingDepth=intFunc(dlsym(handle,"InspectiveC_setMaximumRelativeLoggingDepth"));watchObject=objFunc(dlsym(handle,"InspectiveC_watchObject"));unwatchObject=objFunc(dlsym(handle,"InspectiveC_unwatchObject"));watchSelectorOnObject=objSelFunc(dlsym(handle,"InspectiveC_watchSelectorOnObject"));unwatchSelectorOnObject=objSelFunc(dlsym(handle,"InspectiveC_unwatchSelectorOnObject"));watchClass=classFunc(dlsym(handle,"InspectiveC_watchInstancesOfClass"));unwatchClass=classFunc(dlsym(handle,"InspectiveC_unwatchInstancesOfClass"));watchSelectorOnClass=classSelFunc(dlsym(handle,"InspectiveC_watchSelectorOnInstancesOfClass"));unwatchSelectorOnClass=classSelFunc(dlsym(handle,"InspectiveC_unwatchSelectorOnInstancesOfClass"));watchSelector=selFunc(dlsym(handle,"InspectiveC_watchSelector"));unwatchSelector=selFunc(dlsym(handle,"InspectiveC_unwatchSelector"));enableLogging=voidFunc(dlsym(handle,"InspectiveC_enableLogging"));disableLogging=voidFunc(dlsym(handle,"InspectiveC_disableLogging"));enableCompleteLogging=voidFunc(dlsym(handle,"InspectiveC_enableCompleteLogging"));disableCompleteLogging=voidFunc(dlsym(handle,"InspectiveC_disableCompleteLogging"))

// 使用以下命令限制记录时的递归深度
cy# setMaximumRelativeLoggingDepth(5)

// 监视对象示例
cy# watchObject(choose(SBUIController)[0])

// 取消监视对象
cy# unwatchObject(choose(SBUIController)[0])

// 监视选择器
cy# watchSelector(@selector(任意选择器))

// 监视类
cy# watchClass([任意类 class])
```

**使用方式 1: 使用 InspectiveC 包装器**

在你的 Tweak 文件中包含 **InspCWrapper.m**。建议使用 DEBUG 宏保护。

```c
#if INSPECTIVEC_DEBUG
#include "InspCWrapper.m"
#endif
```

然后使用以下 API:

```c
// 设置命中后的最大日志记录深度
void setMaximumRelativeLoggingDepth(int depth);

// 监视/取消监视指定对象(所有选择器)
// 当对象收到 -|dealloc| 消息时会自动取消监视
void watchObject(id obj);
void unwatchObject(id obj);

// 监视/取消监视指定对象的特定选择器
// 当对象收到 -|dealloc| 消息时会自动取消监视
void watchSelectorOnObject(id obj, SEL _cmd);
void unwatchSelectorOnObject(id obj, SEL _cmd);

// 监视/取消监视指定类的实例 - 仅监视该类的实例,不包括子类
void watchClass(Class clazz);
void unwatchClass(Class clazz);

// 监视/取消监视指定类实例的特定选择器 - 仅监视该类的实例,不包括子类
void watchSelectorOnClass(Class clazz, SEL _cmd);
void unwatchSelectorOnClass(Class clazz, SEL _cmd);

// 监视/取消监视特定选择器
void watchSelector(SEL _cmd);
void unwatchSelector(SEL _cmd);

// 启用/禁用当前线程的日志记录
void enableLogging();
void disableLogging();

// 启用/禁用当前线程的完整消息日志记录
void enableCompleteLogging();
void disableCompleteLogging();
```

**使用方式 2: 直接链接 InspectiveC**

在 Makefile 中添加:

```
<你的_TWEAK_名称>_LIBRARIES = inspectivec
```

这将自动在你的 tweak 中加载 InspectiveC。然后在 tweak 中包含 InspectiveC.h 并使用其函数。

InspectiveC.h 提供以下 API:
```c
// 设置命中后的最大日志记录深度
void InspectiveC_setMaximumRelativeLoggingDepth(int depth);

// 监视/取消监视指定对象(所有选择器)
// 当对象收到 -|dealloc| 消息时会自动取消监视
void InspectiveC_watchObject(id obj);
void InspectiveC_unwatchObject(id obj);

// 监视/取消监视指定对象的特定选择器
// 当对象收到 -|dealloc| 消息时会自动取消监视
void InspectiveC_watchSelectorOnObject(id obj, SEL _cmd);
void InspectiveC_unwatchSelectorOnObject(id obj, SEL _cmd);

// 监视/取消监视指定类的实例 - 仅监视该类的实例,不包括子类
void InspectiveC_watchInstancesOfClass(Class clazz);
void InspectiveC_unwatchInstancesOfClass(Class clazz);

// 监视/取消监视指定类实例的特定选择器 - 仅监视该类的实例,不包括子类
void InspectiveC_watchSelectorOnInstancesOfClass(Class clazz, SEL _cmd);
void InspectiveC_unwatchSelectorOnInstancesOfClass(Class clazz, SEL _cmd);

// 监视/取消监视特定选择器
void InspectiveC_watchSelector(SEL _cmd);
void InspectiveC_unwatchSelector(SEL _cmd);

// 启用/禁用当前线程的日志记录
void InspectiveC_enableLogging();
void InspectiveC_disableLogging();

// 启用/禁用当前线程的完整消息日志记录
void InspectiveC_enableCompleteLogging();
void InspectiveC_disableCompleteLogging();
```