+++
date = "2016-06-15T21:54:10+02:00"
title = "Swift binary in nonswift environment"
categories = [
  "Dev",
  "Swift",
  "Xcode"
]

tags = ["swift", "xcode", "rpath", "project", "otool"]
+++

Ever wanted to use swift to write your custom plugin for `XXX` and got dreaded:

```
dlopen(TestFramework.framework/TestFramework, 5): Library not loaded: @rpath/libswiftAppKit.dylib
```
<!--more-->

This error happens because loader can't find swift libraries. But why is it so? Culprit of this error is `@rpath`.

## @rpath

Swift libraries are referenced using _run-paths_. They're described in apple [documentation](https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/DynamicLibraries/100-Articles/RunpathDependentLibraries.html).

You can use `otool -L <Path_To_Binary>` to see that.
You may get something similar to:
```
/System/Library/Frameworks/AudioToolbox.framework/Versions/A/AudioToolbox (compatibility version 1.0.0, current version 492.0.0)
	/System/Library/Frameworks/AudioUnit.framework/Versions/A/AudioUnit (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/Frameworks/Foundation.framework/Versions/C/Foundation (compatibility version 300.0.0, current version 1258.0.0)
	/usr/lib/libobjc.A.dylib (compatibility version 1.0.0, current version 228.0.0)
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1226.10.1)
	@rpath/libswiftAppKit.dylib (compatibility version 1.0.0, current version 703.0.18)
	@rpath/libswiftCore.dylib (compatibility version 1.0.0, current version 703.0.18)
	@rpath/libswiftCoreAudio.dylib (compatibility version 1.0.0, current version 703.0.18)
	@rpath/libswiftCoreData.dylib (compatibility version 1.0.0, current version 703.0.18)
	@rpath/libswiftCoreGraphics.dylib (compatibility version 1.0.0, current version 703.0.18)
	@rpath/libswiftCoreImage.dylib (compatibility version 1.0.0, current version 703.0.18)
	@rpath/libswiftDarwin.dylib (compatibility version 1.0.0, current version 703.0.18)
	@rpath/libswiftDispatch.dylib (compatibility version 1.0.0, current version 703.0.18)
	@rpath/libswiftFoundation.dylib (compatibility version 1.0.0, current version 703.0.18)
	@rpath/libswiftObjectiveC.dylib (compatibility version 1.0.0, current version 703.0.18)
```

It is the way for application to load libraries from runtime-defined locations. Locations to be searched are defined in Xcode using `Runpath Search Paths` settings.

![Runpath Search Paths](/img/swift-in-nonswift-env-rpath.png)

`Run paths` defined in binary can also be inspected using `otool`.
Call `otool -l <Path_To_Binary>` and look for `LC_RPATH`.
For example:
```
Load command 24
          cmd LC_RPATH
      cmdsize 40
         path @loader_path/../Frameworks (offset 12)
```

## Solution 1 - Xcode setting
To make swift frameworks visible to loader make sure the `Runpath Search Paths` setting is configured properly.
Unfortunately relative paths are not permitted. But one may use path variables defined in [man dyld](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/dyld.1.html):

 - `@loader_path` - Path to folder containing your binary. For plugin this is plugin binary's folder.
 - `@executable_path` - Path to folder containing process main binary. For plugin this is host application binary's folder.

Depending on the structure of your plugin you may use `@loader_path/Frameworks`. This will work if your plugin structure is as follows:
```
 - Plugin
  - PluginBinary
  - Frameworks
    - swiftXXX...
```
or you may use `@loader_path/../Frameworks` if the your plugin structure have AppBundle-like structure:
```
- Plugin
 - Contents
    - MacOS
      - PluginBinary
    - Frameworks
      - swiftXXX...
```

## Solution 2 - install_name_tool

If for some reason you're unable to update `Runpath Search Paths` setting then you may also use tool [install_name_tool](http://www.manpagez.com/man/1/install_name_tool/). This tool can be used to replace `@rpath/swift...` references with `@loader_path/YYY/swift...`.

You may use this script to update all swift references at once:
```
echo otool -L "$FULL_EXECUTABLE_PATH" | grep @rpath | sed 's/@rpath\///g' | sed 's/ (.*//g' | xargs -t -I{} install_name_tool -change @rpath/{} @loader_path/../Frameworks/{} "$FULL_EXECUTABLE_PATH"
```
where $FULL_EXECUTABLE_PATH must point to the binary.

You may do that automatically after each build by adding this script as a `Build Phase`. One thing to keep in mind though is that this script will launch before installation phase. I had problems when I tried to mix this `Build Phase` with `Installation Directory` build setting and I've decided to install my plugin manually inside this script instead of using `Installation Directory` build setting.
