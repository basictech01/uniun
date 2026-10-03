/// Words that carry no answer: English function words, and the Hinglish
/// (Hindi in Latin letters) and Hindi ones people mix into a question. Left in,
/// they match almost every chunk and only add noise to keyword ranking.
const Set<String> kStopwords = {
  // English
  'a', 'an', 'and', 'are', 'as', 'at', 'be', 'been', 'but', 'by', 'can',
  'could', 'did', 'do', 'does', 'for', 'from', 'had', 'has', 'have', 'how',
  'i', 'if', 'in', 'into', 'is', 'it', 'its', 'me', 'my', 'no', 'not', 'of',
  'on', 'or', 'our', 'per', 'should', 'so', 'than', 'that', 'the', 'their',
  'then', 'there', 'this', 'to', 'was', 'we', 'were', 'what', 'when', 'where',
  'which', 'who', 'whom', 'whose', 'why', 'will', 'with', 'would', 'you',
  'your',
  // Hinglish
  'ka', 'ki', 'ke', 'ko', 'kya', 'kab', 'kitna', 'kitni', 'kitne', 'hai',
  'hain', 'tha', 'thi', 'ho', 'hua', 'hui', 'hue', 'mein', 'se', 'par',
  'ne', 'aur', 'ya', 'wali', 'wala', 'wale', 'kaun', 'kis', 'kaise', 'kahan',
  'ye', 'yeh', 'wo', 'woh', 'ek', 'liye', 'hota', 'hoti', 'hote', 'kar',
  'karna', 'kiya', 'nahi', 'bhi',
  // Hindi
  'का', 'की', 'के', 'को', 'में', 'से', 'पर', 'ने', 'और', 'या', 'है', 'हैं',
  'था', 'थी', 'थे', 'हो', 'हुआ', 'हुई', 'हुए', 'कि', 'यह', 'वह', 'क्या',
  'कब', 'कितना', 'कितनी', 'कितने', 'कौन', 'किस', 'कैसे', 'कहाँ', 'एक',
  'लिए', 'होता', 'होती', 'होते', 'भी', 'नहीं', 'तो', 'जो', 'इस', 'उस',
};
