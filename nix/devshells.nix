{
  pkgs,
  sce,
  android,
  ...
}:
let

  default = pkgs.mkShell {
    name = "fitfat-dev";

    # Android tooling expects these to be set in the environment.
    ANDROID_HOME = android.androidHome;
    ANDROID_SDK_ROOT = android.androidHome;
    ANDROID_NDK_HOME = android.ndkHome;
    ANDROID_NDK_ROOT = android.ndkHome;
    NDK_HOME = android.ndkHome;
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android.androidHome}/build-tools/${android.buildToolsVersion}/aapt2";

    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";

    # Used by `flutter run -d chrome`.
    CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";

    # The Android emulator's bundled Qt has no usable Wayland plugin in
    # nixpkgs; force XWayland so the UI window opens correctly.
    QT_QPA_PLATFORM = "xcb";

    # The emulator's bundled binary isn't wrapped with system drivers; expose
    # OpenGL / Vulkan / X libs so it can dlopen them at runtime.
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (
      with pkgs;
      [
        libGL
        libglvnd
        vulkan-loader
        libdrm
        wayland
        xorg.libX11
        xorg.libxcb
        xorg.libXrandr
        xorg.libXi
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXcomposite
        xorg.libXfixes
        xorg.libXrender
        xorg.libXtst
        fontconfig
        freetype
        stdenv.cc.cc.lib
      ]
    );

    nativeBuildInputs = with pkgs; [
      pkg-config
      cmake
      ninja
      clang
    ];

    buildInputs =
      [
        sce
        android.androidSdk
      ]
      ++ (with pkgs; [
        # Host build deps
        openssl
        sqlite

        # JVM toolchain required by Gradle / Android builds
        jdk17
        gradle

        # Flutter SDK (mobile + Linux desktop + web)
        flutter

        # Linux desktop build deps for `flutter run -d linux`
        gtk3
        glib
        pcre2
        libepoxy
        libsysprof-capture
        mesa
        xorg.libX11

        # Extra graphics libs the Android emulator needs at runtime
        # (its bundled binary is not wrapped against your system drivers).
        libGL
        libglvnd
        vulkan-loader
        vulkan-tools
        libdrm
        wayland
        xorg.libxcb
        xorg.libXrandr
        xorg.libXi
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXcomposite
        xorg.libXfixes
        xorg.libXrender
        xorg.libXtst
        fontconfig
        freetype

        # Web target
        chromium

        # Device interaction / debugging
        scrcpy
        usbutils
      ]);

    shellHook = ''
      echo "🛠  Maia dev shell"
      echo "  ANDROID_HOME      = $ANDROID_HOME"
      echo "  ANDROID_NDK_HOME  = $ANDROID_NDK_HOME"
      echo "  JAVA_HOME         = $JAVA_HOME"
      echo "  CHROME_EXECUTABLE = $CHROME_EXECUTABLE"
      echo ""
      echo "      flutter doctor"
      echo "      flutter run -d linux        # desktop"
      echo "      flutter run        # to use the emulator if running"
      echo "      flutter emulators"
      echo "      flutter emulators --launch my_avd"
      echo "      flutter run -d <device-id>  # Android (see: flutter devices)"
    '';
  };
in
{
  inherit default;
}
