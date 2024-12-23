enum PolicyLanguage {
  en('en'),
  ko('ko');

  final String text;

  const PolicyLanguage(this.text);
}

enum PolicyType {
  privacy,
  terms,
  withdraw,
}

enum PortalType { vote, pic, community, novel, mypage }

enum Gender { male, female }
