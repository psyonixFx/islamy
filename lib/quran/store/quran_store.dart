// ignore_for_file: library_private_types_in_public_api

part of quran;

/// Storage handler for most of the requests made with [CloudQuran].
///
/// This store uses [Hive] DB to store everyting.
class QuranStore {
  const QuranStore._();

  /// static instance that provides the necessary meta about [Juz]
  /// and getters/setters for the default edition for each type.
  static const _QuranSettings settings = _QuranSettings.instance;

  static late final Box<Edition> _editionsBox;
  static late final Box<TheHolyQuran> _textQuranBox;

  /// initializer for the [QuranStore] [Box]s and register
  /// every [TypeAdapter<T>] for each type needed.
  static Future<void> init() async {
    await _QuranSettings._init();
    _registerAdapters();
    _editionsBox = await _getBox('editions');
    _textQuranBox = await _getBox('text_quran');
  }

  static void _registerAdapters() {
    // Quran adapters typeId should start from 0

    Hive
      // typeId == 0
      ..registerAdapter(EditionAdapter())

      // typeId == 1
      // TODO(psyonixFx): rearange the typeId's.
      // The type id 1 is now released.
      // typeId == 2
      ..registerAdapter(QuranContentTypeAdapter())

      // typeId == 3
      ..registerAdapter(FormatAdapter())

      // typeId == 4
      ..registerAdapter(DirectionAdapter())

      // typeId == 5
      ..registerAdapter(TheHolyQuranAdapter())

      // typeId == 6
      ..registerAdapter(SurahAdapter())

      // typeId == 7
      ..registerAdapter(AyahAdapter())

      // typeId == 8
      ..registerAdapter(SajdaAdapter())

      // typeId == 9
      ..registerAdapter(RevelationTypeAdapter());
  }

  static Future<Box<T>> _getBox<T>(String boxName) async {
    Box<T> box;
    if (Hive.isBoxOpen(boxName)) {
      box = Hive.box<T>(boxName);
    } else {
      box = await Hive.openBox<T>(boxName);
    }

    if (!box.isOpen) {
      await Hive.openBox<T>(box.name);
    }
    return box;
  }

  static List<Edition> _listEditions() => _editionsBox.values.toList();

  static List<Edition> listTextEditions() => _editionsBox.values
      .where(
        (Edition element) =>
            element.format == Format.text &&
            element.type == QuranContentType.quran,
      )
      .toList();
  static List<Edition> listAudioEditions() => _editionsBox.values
      .where(
        (Edition element) =>
            element.format == Format.audio &&
            element.type == QuranContentType.versebyverse,
      )
      .toList();
  static List<Edition> listInterpretationEditions() => _editionsBox.values
      .where(
        (Edition element) =>
            element.format == Format.text &&
            element.type == QuranContentType.tafsir,
      )
      .toList();
  static List<Edition> listTranslationEditions() => _editionsBox.values
      .where(
        (Edition element) =>
            element.format == Format.text &&
            element.type == QuranContentType.translation,
      )
      .toList();
  static List<Edition> listTransliterationEditions() => _editionsBox.values
      .where(
        (Edition element) => element.type == QuranContentType.transliteration,
      )
      .toList();
  static Future<void> _addEditions(List<Edition> editions) =>
      _addAll(values: editions, box: _editionsBox);

  static Future<bool> _isSurahDownloaded(Edition edition, Surah surah) async {
    final Directory surahDirectory =
        await _getDirectoryForSurah(edition, surah);

    return surahDirectory.listSync().length ==
        surah.ayahs.length +
            // merged surah + durations.json
            2 +
            // if the platform supports .nomedia
            (QuranManager.noMediaPlatforms.contains(Platform.operatingSystem)
                ? 1
                : 0);
  }

  static Future<Directory> _getDirectoryForSurah(
    Edition edition,
    Surah surah,
  ) async {
    final Directory docDirectory = await getApplicationDocumentsDirectory();
    final Directory quranDirectory =
        _getDescendant(docDirectory, edition.identifier);
    final Directory surahDirectory =
        _getDescendant(quranDirectory, surah.number.toString());
    return surahDirectory;
  }

  static Future<File> _fileIn(Edition edition, Surah surah, String name) async {
    final Directory directory = await _getDirectoryForSurah(edition, surah);
    File file;
    if (directory.path.endsWith(Platform.pathSeparator)) {
      file = File(directory.path + name);
    } else {
      file = File(directory.path + Platform.pathSeparator + name);
    }
    return file;
  }

  /// Convinient method to get the merged [Surah] [File].
  static Future<File> mergedSurahFile(Edition edition, Surah surah) =>
      _fileIn(edition, surah, QuranManager.mergedSurahFileName);

  /// Convinient method to get the durations json  [File] of the [Surah].
  static Future<File> surahDurationsFile(Edition edition, Surah surah) =>
      _fileIn(edition, surah, QuranManager.durationJsonFileName);

  static Future<File> _basmalaFileFor(TheHolyQuran quran) =>
      _fileIn(quran.edition, quran.surahs.first, '1.mp3');

  static Directory _getDescendant(Directory directory, String child) {
    if (!directory.existsSync()) directory.createSync();
    String path = directory.path;
    if (!path.endsWith(Platform.pathSeparator)) path += Platform.pathSeparator;
    final Directory descendant = Directory(path + child);
    if (!descendant.existsSync()) descendant.createSync();
    return descendant;
  }

  static TheHolyQuran? _getQuran(Edition edition) {
    return _readValue(name: edition.identifier, box: _textQuranBox);
  }

  static Future<void> _addQuran(Edition edition, TheHolyQuran quran) async {
    await _saveValue(
      name: edition.identifier,
      value: quran,
      box: _textQuranBox,
    );
  }

  static Future<void> _saveValue<T>({
    required String name,
    required T? value,
    required Box<T?> box,
  }) async {
    await box.delete(name);
    await box.put(name, value);
  }

  static Future<void> _addAll<T>({
    required List<T> values,
    required Box<T> box,
  }) async {
    await box.addAll(values);
  }

  static T? _readValue<T>({
    required String name,
    required Box<T> box,
  }) {
    final T? results = box.get(name);
    return results;
  }
}

class _QuranSettings {
  const _QuranSettings._();
  static const _QuranSettings instance = _QuranSettings._();
  static late final Box<String> _settingsBox;
  static late final List<Juz> _juzData;
  static Future<void> _init() async {
    _settingsBox = await QuranStore._getBox<String>('quran_settings');
    final String data =
        await rootBundle.loadString('assets/config/juz_data.json');
    _juzData = Juz.listFromRawJson(data);
  }

  List<Juz> get juzData => _juzData;

  QuranMeta get meta => QuranMeta.fromRawJson(_settingsBox.get('quran_meta')!);

  set meta(QuranMeta meta) => _settingsBox.put('quran_meta', meta.toRawJson());

  ////// Editions Selections
  Edition get defaultTextEdition {
    return QuranStore.listTextEditions().singleWhere(
      (Edition element) =>
          element.identifier ==
          (_settingsBox.get('default_text_edition') ?? 'quran-uthmani'),
    );
  }

  set defaultTextEdition(Edition edition) {
    QuranStore._saveValue(
      name: 'default_text_edition',
      value: edition.identifier,
      box: _settingsBox,
    );
  }

  Edition get defaultAudioEdition {
    final List<Edition> editions = QuranStore.listAudioEditions().toList();

    return editions.singleWhere(
      (Edition element) =>
          element.identifier ==
          (_settingsBox.get('default_audio_edition') ??
              editions.first.identifier),
    );
  }

  set defaultAudioEdition(Edition edition) {
    QuranStore._saveValue(
      name: 'default_audio_edition',
      value: edition.identifier,
      box: _settingsBox,
    );
  }

  Edition get defaultInterpretationEdition {
    final List<Edition> editions =
        QuranStore.listInterpretationEditions().toList();

    return editions.singleWhere(
      (Edition element) =>
          element.identifier ==
          (_settingsBox.get('default_interpretation_edition') ??
              editions.first.identifier),
    );
  }

  set defaultInterpretationEdition(Edition edition) {
    QuranStore._saveValue(
      name: 'default_interpretation_edition',
      value: edition.identifier,
      box: _settingsBox,
    );
  }

  Edition get defaultTranslationEdition {
    final List<Edition> editions =
        QuranStore.listTranslationEditions().toList();

    return editions.singleWhere(
      (Edition element) =>
          element.identifier ==
          (_settingsBox.get('default_translation_edition') ??
              editions.first.identifier),
    );
  }

  set defaultTranslationEdition(Edition edition) {
    QuranStore._saveValue(
      name: 'default_translation_edition',
      value: edition.identifier,
      box: _settingsBox,
    );
  }
}
