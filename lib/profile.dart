class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'],
      email: data['email'],
      displayName: data['displayName'],
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }
}
