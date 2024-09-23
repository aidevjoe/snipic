// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// ` Compression Quality`
  String get compressionQuality {
    return Intl.message(
      ' Compression Quality',
      name: 'compressionQuality',
      desc: '',
      args: [],
    );
  }

  /// `Resize`
  String get resize {
    return Intl.message(
      'Resize',
      name: 'resize',
      desc: '',
      args: [],
    );
  }

  /// `Width`
  String get width {
    return Intl.message(
      'Width',
      name: 'width',
      desc: '',
      args: [],
    );
  }

  /// `Height`
  String get height {
    return Intl.message(
      'Height',
      name: 'height',
      desc: '',
      args: [],
    );
  }

  /// `Maintain Aspect Ratio`
  String get keepAspectRatio {
    return Intl.message(
      'Maintain Aspect Ratio',
      name: 'keepAspectRatio',
      desc: '',
      args: [],
    );
  }

  /// `Font Size`
  String get fontSize {
    return Intl.message(
      'Font Size',
      name: 'fontSize',
      desc: '',
      args: [],
    );
  }

  /// `Watermark`
  String get watermark {
    return Intl.message(
      'Watermark',
      name: 'watermark',
      desc: '',
      args: [],
    );
  }

  /// `Watermark Text`
  String get watermarkText {
    return Intl.message(
      'Watermark Text',
      name: 'watermarkText',
      desc: '',
      args: [],
    );
  }

  /// `Position`
  String get position {
    return Intl.message(
      'Position',
      name: 'position',
      desc: '',
      args: [],
    );
  }

  /// `Opacity`
  String get opacity {
    return Intl.message(
      'Opacity',
      name: 'opacity',
      desc: '',
      args: [],
    );
  }

  /// `Compress`
  String get compress {
    return Intl.message(
      'Compress',
      name: 'compress',
      desc: '',
      args: [],
    );
  }

  /// `Top left`
  String get topLeft {
    return Intl.message(
      'Top left',
      name: 'topLeft',
      desc: '',
      args: [],
    );
  }

  /// `Top right`
  String get topRight {
    return Intl.message(
      'Top right',
      name: 'topRight',
      desc: '',
      args: [],
    );
  }

  /// `Center`
  String get center {
    return Intl.message(
      'Center',
      name: 'center',
      desc: '',
      args: [],
    );
  }

  /// `Bottom left`
  String get bottomLeft {
    return Intl.message(
      'Bottom left',
      name: 'bottomLeft',
      desc: '',
      args: [],
    );
  }

  /// `Bottom right`
  String get bottomRight {
    return Intl.message(
      'Bottom right',
      name: 'bottomRight',
      desc: '',
      args: [],
    );
  }

  /// `Select Configuration`
  String get selectConfiguration {
    return Intl.message(
      'Select Configuration',
      name: 'selectConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `Image Processing Options`
  String get imageProcessingOptions {
    return Intl.message(
      'Image Processing Options',
      name: 'imageProcessingOptions',
      desc: '',
      args: [],
    );
  }

  /// `Add Processing Option`
  String get addProcessingOption {
    return Intl.message(
      'Add Processing Option',
      name: 'addProcessingOption',
      desc: '',
      args: [],
    );
  }

  /// `Option Type`
  String get optionType {
    return Intl.message(
      'Option Type',
      name: 'optionType',
      desc: '',
      args: [],
    );
  }

  /// `Configuration`
  String get configuration {
    return Intl.message(
      'Configuration',
      name: 'configuration',
      desc: '',
      args: [],
    );
  }

  /// `Add New Configuration`
  String get addNewConfiguration {
    return Intl.message(
      'Add New Configuration',
      name: 'addNewConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `Configuration Name`
  String get configurationName {
    return Intl.message(
      'Configuration Name',
      name: 'configurationName',
      desc: '',
      args: [],
    );
  }

  /// `Service Provider`
  String get engineType {
    return Intl.message(
      'Service Provider',
      name: 'engineType',
      desc: '',
      args: [],
    );
  }

  /// `Configuration already exists`
  String get configurationAlreadyExists {
    return Intl.message(
      'Configuration already exists',
      name: 'configurationAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Configuration saved`
  String get configurationSaved {
    return Intl.message(
      'Configuration saved',
      name: 'configurationSaved',
      desc: '',
      args: [],
    );
  }

  /// `Uploaded images may be publicly accessible. Do not upload sensitive or private content.`
  String get uploadedImagesMayBePublic {
    return Intl.message(
      'Uploaded images may be publicly accessible. Do not upload sensitive or private content.',
      name: 'uploadedImagesMayBePublic',
      desc: '',
      args: [],
    );
  }

  /// `Incomplete configuration. Please check your settings.`
  String get incompleteConfigurationMsg {
    return Intl.message(
      'Incomplete configuration. Please check your settings.',
      name: 'incompleteConfigurationMsg',
      desc: '',
      args: [],
    );
  }

  /// `This image hosting service does not support gallery functionality.`
  String get galleryNotSupported {
    return Intl.message(
      'This image hosting service does not support gallery functionality.',
      name: 'galleryNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `No images found. Try uploading some images first.`
  String get noImagesFoundUploadFirst {
    return Intl.message(
      'No images found. Try uploading some images first.',
      name: 'noImagesFoundUploadFirst',
      desc: '',
      args: [],
    );
  }

  /// `Deleted {count} out of {total} images`
  String deletedImagesMessage(Object count, Object total) {
    return Intl.message(
      'Deleted $count out of $total images',
      name: 'deletedImagesMessage',
      desc: '',
      args: [count, total],
    );
  }

  /// `Operation failed, please try again.`
  String get operationFailedError {
    return Intl.message(
      'Operation failed, please try again.',
      name: 'operationFailedError',
      desc: '',
      args: [],
    );
  }

  /// `Configuration name and engine type are required`
  String get configNameAndEngineRequired {
    return Intl.message(
      'Configuration name and engine type are required',
      name: 'configNameAndEngineRequired',
      desc: '',
      args: [],
    );
  }

  /// `Unknown Error`
  String get unknownError {
    return Intl.message(
      'Unknown Error',
      name: 'unknownError',
      desc: '',
      args: [],
    );
  }

  /// `Upload Failed`
  String get uploadFailed {
    return Intl.message(
      'Upload Failed',
      name: 'uploadFailed',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message(
      'Add',
      name: 'add',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retry {
    return Intl.message(
      'Retry',
      name: 'retry',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get defaultText {
    return Intl.message(
      'Default',
      name: 'defaultText',
      desc: '',
      args: [],
    );
  }

  /// `Copy Link`
  String get copyLink {
    return Intl.message(
      'Copy Link',
      name: 'copyLink',
      desc: '',
      args: [],
    );
  }

  /// `Filename`
  String get filename {
    return Intl.message(
      'Filename',
      name: 'filename',
      desc: '',
      args: [],
    );
  }

  /// `File Size`
  String get fileSize {
    return Intl.message(
      'File Size',
      name: 'fileSize',
      desc: '',
      args: [],
    );
  }

  /// `Dimensions`
  String get dimensions {
    return Intl.message(
      'Dimensions',
      name: 'dimensions',
      desc: '',
      args: [],
    );
  }

  /// `Upload Time`
  String get uploadTime {
    return Intl.message(
      'Upload Time',
      name: 'uploadTime',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Gallery`
  String get gallery {
    return Intl.message(
      'Gallery',
      name: 'gallery',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Copy`
  String get copy {
    return Intl.message(
      'Copy',
      name: 'copy',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Upload`
  String get upload {
    return Intl.message(
      'Upload',
      name: 'upload',
      desc: '',
      args: [],
    );
  }

  /// `Uploading...`
  String get uploading {
    return Intl.message(
      'Uploading...',
      name: 'uploading',
      desc: '',
      args: [],
    );
  }

  /// `images uploaded successfully`
  String get imagesUploadedSuccessfully {
    return Intl.message(
      'images uploaded successfully',
      name: 'imagesUploadedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Copied to clipboard`
  String get copiedToClipboard {
    return Intl.message(
      'Copied to clipboard',
      name: 'copiedToClipboard',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
