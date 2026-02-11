
class GamificationService {
  static final GamificationService instance = GamificationService._();
  GamificationService._();


  // Points Mapping
  static const int pointsPerCorrect = 10;
  static const int pointsPerCombo = 5;

  /// Calculates points based on correctness and combo
  int calculatePoints(int currentCombo) {
    int base = pointsPerCorrect;
    return base + currentCombo;
  }

  /// Checks if any badge should be awarded
  Future<List<String>> checkAchievements(int childId, {
    int? sessionCorrect,
    int? sessionStreak,
    int? totalScore,
  }) async {
    // This would ideally interact with the Achievement repository
    // For now, let's simulate logic
    List<String> newBadges = [];
    
    // Example logic
    if (sessionStreak != null && sessionStreak >= 10) {
      newBadges.add('SERİ KATİL: 10 doğru cevap arka arkaya!');
    }
    
    if (totalScore != null && totalScore >= 100) {
      newBadges.add('MATEMATİK ÇIRAĞI: 100 puana ulaştın!');
    }

    return newBadges;
  }

  /// Returns a fun message based on performance
  String getFeedbackMessage(bool isCorrect, int combo) {
    if (isCorrect) {
      if (combo > 5) return 'İNANILMAZ! $combo Kombo! 🔥';
      if (combo > 3) return 'HARİKA GİDİYORSUN! 🚀';
      return 'Doğru! 🌟';
    } else {
      return 'Hadi bir daha dene! 💪';
    }
  }
}
