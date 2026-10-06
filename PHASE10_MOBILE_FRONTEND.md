# Phase 10 — Mobile war room and opening story

The title screen, loading screen and launcher art are original assets for Ogre War. The new war room keeps the play button prominent and groups the Field Guide, Battle Records and Watch Story actions within comfortable mobile touch targets. The battle HUD receives higher contrast, gilded borders, clearer faction colors and refined touch-button states; combat rules do not change.

The user's 24-second opening MP4 was converted to `assets/ui/phase10/humanitys_last_stand.ogv` with Theora video and Vorbis audio for Godot's built-in `VideoStreamPlayer`. It plays automatically once per installation and is skippable. **WATCH STORY** replays it without clearing records. The original MP4 is not required at runtime.

The loading screen has distinct battlefield art, a real threaded load meter, and Retry / War Room choices if a battle resource fails to load.

Verification: run `bash tools/codespaces_setup.sh`, `bash tools/codespaces_android_setup.sh`, `bash tools/verify_codespaces.sh` and `bash tools/build_android_debug.sh`. The release gate includes a Phase 10 asset validator and an intro/skip/replay smoke test.
