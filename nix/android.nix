{
  pkgs,
  ...
}:
let
  # Versions track what Flutter 3.50 expects (compileSdk/targetSdk 36,
  # NDK 28.2) plus API 37, which newer plugins such as permission_handler 13
  # compile against. Only versions present in nixpkgs' androidenv repo.json
  # can be listed here.
  buildToolsVersion = "36.1.0";
  platformVersion = "36";
  ndkVersion = "28.2.13676358";
  ndkVersions = [ ndkVersion ];
  cmdLineToolsVersion = "23.0";

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = cmdLineToolsVersion;
    toolsVersion = "26.1.1";
    platformToolsVersion = "37.0.3";
    # 36.0.0 is AGP 9.3's default build-tools; Gradle cannot download it into the
    # read-only nix store, so it must be listed here.
    buildToolsVersions = [ "36.0.0" buildToolsVersion "37.0.0" ];
    includeEmulator = true;
    emulatorVersion = "37.3.9";
    # 35 and 37 are what individual plugins compile against (foreground_task,
    # flutter_timezone, jni: 35; notifications,
    # permission_handler: 37). Gradle cannot install missing ones itself.
    platformVersions = [ "35" platformVersion "37.0" ];
    includeSources = false;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [
      "x86_64"
      "arm64-v8a"
    ];
    includeNDK = true;
    ndkVersions = ndkVersions;
    useGoogleAPIs = true;
    useGoogleTVAddOns = false;
    includeExtras = [ ];
    # 3.22.1 is AGP's default CMake, used by plugins with native code (jni).
    cmakeVersions = [ "3.22.1" "3.31.6" ];
  };

  androidSdk = androidComposition.androidsdk;
  androidHome = "${androidSdk}/libexec/android-sdk";
  ndkHome = "${androidHome}/ndk/${ndkVersion}";
in
{
  inherit
    androidComposition
    androidSdk
    androidHome
    ndkHome
    buildToolsVersion
    platformVersion
    ndkVersions
    ;
}
