enum PreferredPlaybackQuality { sd, hd, fullHd, ultraHd4k }

extension PreferredPlaybackQualityValue on PreferredPlaybackQuality {
  String toValue() {
    switch (this) {
      case PreferredPlaybackQuality.sd:
        return 'sd';
      case PreferredPlaybackQuality.hd:
        return 'hd';
      case PreferredPlaybackQuality.fullHd:
        return 'full_hd';
      case PreferredPlaybackQuality.ultraHd4k:
        return '4k';
    }
  }

  int get minimumQualityRank {
    switch (this) {
      case PreferredPlaybackQuality.sd:
        return 1;
      case PreferredPlaybackQuality.hd:
        return 2;
      case PreferredPlaybackQuality.fullHd:
        return 3;
      case PreferredPlaybackQuality.ultraHd4k:
        return 4;
    }
  }

  static PreferredPlaybackQuality? fromValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'sd':
        return PreferredPlaybackQuality.sd;
      case 'hd':
        return PreferredPlaybackQuality.hd;
      case 'full_hd':
        return PreferredPlaybackQuality.fullHd;
      case '4k':
        return PreferredPlaybackQuality.ultraHd4k;
      default:
        return null;
    }
  }
}
