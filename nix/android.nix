{
  pkgs,
  ...
}:
let
  buildToolsVersion = "36.0.0";
  platformVersion = "36";
  ndkVersions = [
    "26.1.10909125"
    "28.2.13676358"
  ];
  cmdLineToolsVersion = "11.0";

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = cmdLineToolsVersion;
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.2";
    buildToolsVersions = [ "34.0.0" "35.0.0" buildToolsVersion ];
    includeEmulator = true;
    emulatorVersion = "35.1.4";
    platformVersions = [ "34" "35" platformVersion ];
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
    cmakeVersions = [ "3.22.1" ];
  };

  androidSdk = androidComposition.androidsdk;
  androidHome = "${androidSdk}/libexec/android-sdk";
  ndkHome = "${androidHome}/ndk/26.1.10909125";
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
