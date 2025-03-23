class SMTPSettings {
  final String? host;
  final int? port;
  final String? sender;
  final String? username;
  final String? password;
  final bool? ssl;

  SMTPSettings({
    this.host,
    this.port,
    this.sender,
    this.username,
    this.password,
    this.ssl,
  });

  factory SMTPSettings.fromJson(Map<String, dynamic> json) {
    return SMTPSettings(
      host: json['host'] as String?,
      port: json['port'] as int?,
      sender: json['sender'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      ssl: json['enableSsl'] as bool?,
    );
  }

  static Map<String, dynamic> toJson(SMTPSettings smtpSettings) {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['host'] = smtpSettings.host;
    data['port'] = smtpSettings.port.toString();
    data['sender'] = smtpSettings.sender;
    data['username'] = smtpSettings.username;
    data['password'] = smtpSettings.password;
    data['enableSsl'] = smtpSettings.ssl;
    return data;
  }
}
