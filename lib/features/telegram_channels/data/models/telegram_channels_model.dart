// لما أستخدم المودل دا ببيظهرلي List<dynamic> is not subtype of Map<String,dynamic> لذلك إستغنيت عنه
// class TelegramChannelsModel {
//   TelegramChannels telegramChannels;
//   IslamHousePhotos islamHousePhotos;
 
//   TelegramChannelsModel(
//       {required this.telegramChannels, required this.islamHousePhotos});

//   factory TelegramChannelsModel.fromJson(Map<String, dynamic> json) {
//     return TelegramChannelsModel(
//       telegramChannels: TelegramChannels.fromJson(json['telegram-channels']),
//       islamHousePhotos: IslamHousePhotos.fromJson(json['sp-islamhouse-photos']),
//     );
//   }
// }

class TelegramChannels {
  Map<String, TelegramChannel> telegramChannels;
  TelegramChannels({required this.telegramChannels});
  factory TelegramChannels.fromJson(Map<String, dynamic> json) {
    Map<String, TelegramChannel> channels = {};

    json.forEach((key, value) {
      channels[key] = TelegramChannel.fromJson(key, value);
    });

    return TelegramChannels(telegramChannels: channels);
  }
}
class TelegramChannel {
  final String name;
  final String link;
  final Map<String, String> messages;

  TelegramChannel({
    required this.name,
    required this.link,
    required this.messages,
  });

  factory TelegramChannel.fromJson(String name, Map<String, dynamic> json) {
      final String link = json['link'] ?? '';
    return TelegramChannel(
      name: name,
      link: link,
      messages: Map<String, String>.from(json),
    );
  }
}
class IslamHousePhotos {
  Map<String, String> photos;
  IslamHousePhotos({required this.photos});
  factory IslamHousePhotos.fromJson(Map<String, dynamic> json) {
    return IslamHousePhotos(photos: json.cast<String, String>());
  }
}
