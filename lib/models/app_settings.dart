enum BackupProvider {
  local,
  cloud,
}

class AppSettings {
  const AppSettings({
    required this.currencySymbol,
    required this.localeTag,
    required this.backupProvider,
  });

  final String currencySymbol;
  final String localeTag;
  final BackupProvider backupProvider;

  factory AppSettings.defaults({String? localeTag}) {
    return AppSettings(
      currencySymbol: '\$',
      localeTag: localeTag ?? '',
      backupProvider: BackupProvider.local,
    );
  }

  AppSettings copyWith({
    String? currencySymbol,
    String? localeTag,
    BackupProvider? backupProvider,
  }) {
    return AppSettings(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      localeTag: localeTag ?? this.localeTag,
      backupProvider: backupProvider ?? this.backupProvider,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currencySymbol': currencySymbol,
      'localeTag': localeTag,
      'backupProvider': backupProvider.name,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      currencySymbol: (json['currencySymbol'] as String?) ?? '\$',
      localeTag: (json['localeTag'] as String?) ?? '',
      backupProvider: _backupProviderFromJson(json['backupProvider'] as String?),
    );
  }

  static BackupProvider _backupProviderFromJson(String? value) {
    switch (value) {
      case 'cloud':
        return BackupProvider.cloud;
      case 'local':
      default:
        return BackupProvider.local;
    }
  }
}
