import 'package:equatable/equatable.dart';

/// One Telegram sign-in attempt: [url] opens the bot, and [sid] with
/// [secret] claims the result once the number has been shared there.
class TelegramLogin extends Equatable {
  const TelegramLogin({required this.sid, required this.secret, required this.url});

  final String sid, secret;
  final Uri url;

  @override
  List<Object?> get props => [sid, secret, url];
}
