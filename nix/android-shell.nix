with (import ./default.nix {});

let

   ndk = androidenv.androidndk_17c.override { fullNDK = true; };
   ndk_root = "${ndk}/libexec/${ndk.name}";
   sdk_path = if stdenv.isDarwin
     then "/Library/Android/sdk"
     else "/Android/Sdk"; # intentional Capital S

in

mkShell rec {

  LANG="en_US.UTF-8";
  JAVA_HOME=openjdk8;

  ANDROID_SDK_ROOT=builtins.getEnv("HOME") + sdk_path;
  ANDROID_NDK_ROOT="${ANDROID_SDK_ROOT}/ndk-bundle";
  ANDROID_HOME=ANDROID_SDK_ROOT;
  ANDROID_NDK=ANDROID_NDK_ROOT;

  nativeBuildInputs = [
    awscli
    curl
    git
    nodejs-8_x
    openjdk8
    yarn
  ];

  passthru = { inherit ndk; };

  shellHook = ''
    ${./install-ndk-17c.sh} ${ndk} ${ndk_root}
    yes | ${androidenv.androidsdk_9_0}/bin/sdkmanager --licenses --sdk_root="$ANDROID_SDK_ROOT"
    yes | ${androidenv.androidsdk_9_0}/bin/sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "platforms;android-28" | grep -v =
    yes | ${androidenv.androidsdk_9_0}/bin/sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "build-tools;28.0.3" | grep -v =
    ${lib.optionalString stdenv.isLinux ''
      for dep in lib lib64; do
        if [ -L /$dep ] || [ ! -e /$dep ]; then
          echo "Creating /$dep"
          ln -s ${stdenv.cc.libc}/$dep /$dep
        else
          echo "Using existing /$dep"
        fi
      done
    ''}
  '';
}
