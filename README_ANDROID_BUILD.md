# Ogre War Android debug build

The project targets Godot 4.7.2 and the Mobile renderer. The checked-in Android preset exports an ARM64 debug APK with package ID `com.cladamswv.ogrewar`.

Recommended CI/Codespaces sequence:

```bash
bash tools/codespaces_setup.sh
bash tools/codespaces_android_setup.sh
bash tools/verify_codespaces.sh
bash tools/build_android_debug.sh
```

The build helper verifies Godot 4.7.2, Android SDK/JDK availability, installs
matching official Android export templates when missing, writes `4.7.2.stable`
to the template `version.txt`, and checks the exported APK's ZIP structure and
ARM64 Godot library. It removes any previous APK before export, so a failed
build cannot appear to succeed by finding a stale package.

The debug keystore is stored outside the project at
`~/.local/share/ogre-war/debug.keystore`. Keep it to install updated debug
builds over an earlier version; changing or deleting it requires uninstalling
the previously installed debug build before installing a newly signed one.

Output:

```text
build/Ogre-War-debug.apk
```

For a Play Store release, configure a real release keystore and an AAB/Gradle
release workflow separately. Do not use the generated debug keystore for
production distribution.
