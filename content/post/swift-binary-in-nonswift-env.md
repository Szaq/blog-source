+++
date = "2016-06-15T21:54:10+02:00"
title = "Swift binary in nonswift environment"
draft = true
categories = [
  "Dev",
  "Swift",
  "Xcode"
]
+++

# How to load swift binary in nonswift environment
Ever wanted to use swift to write your custom plugin for `XXX` and got dreaded:
```
dlopen(TestFramework.framework/TestFramework, 5): Library not loaded: @rpath/libswiftAppKit.dylib
```

This error happens because loader can't find swift libraries. But why is it so? Culprit of this error is `@rpath`.

## @rpath

Swift libraries are referenced using _run-paths_. They're described in apple [documentation](https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/DynamicLibraries/100-Articles/RunpathDependentLibraries.html).

It is the way for application to load libraries from yet-to-be-defined locations. Locations to be searched are defined in Xcode using `Runpath Search Paths` settings.

![Runpath Search Paths](/static/img/swift-in-nonswift-env-rpath.png)

To make swift frameworks visible to loader make sure at least `Runpath Search Paths` is configured properly.
Unfortunately relative paths are not permitted. But one may use path variables defined in [man dyld](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/dyld.1.html):
- `@loader_path` - Path to folder containing your binary.g
- `@executable_path` - Path to folder containing process main binary.

## install_name_tool
