class UserProfile {
  final String uid;
  final String alias;
  final String name;
  final String country;

  UserProfile({
    required this.uid,
    required this.alias,
    this.name = '',
    this.country = '',
  });

  Map<String, dynamic> toMap() => {
        'alias': alias,
        'name': name,
        'country': country,
      };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) =>
      UserProfile(
        uid: uid,
        alias: map['alias'] as String? ?? 'Player',
        name: map['name'] as String? ?? '',
        country: map['country'] as String? ?? '',
      );

  UserProfile copyWith({String? alias, String? name, String? country}) =>
      UserProfile(
        uid: uid,
        alias: alias ?? this.alias,
        name: name ?? this.name,
        country: country ?? this.country,
      );
}
