import '../models/session_summary.dart';

class SessionAggregator {
  static const int _gridCols = 4;
  static const int _gridRows = 14;

  static Future<SessionHeatmapData> aggregateSessionHistory(
    List<SessionSummary> history,
  ) async {
    if (history.isEmpty) {
      return SessionHeatmapData.empty();
    }

    final recentSessions = history.take(10).toList();

    final leftIntensities = _computeGridIntensities(
      recentSessions,
      leg: 'left',
    );
    final rightIntensities = _computeGridIntensities(
      recentSessions,
      leg: 'right',
    );

    return SessionHeatmapData(
      leftIntensities: leftIntensities,
      rightIntensities: rightIntensities,
      sessionCount: recentSessions.length,
      averageSymmetry: _computeAverageSymmetry(recentSessions),
    );
  }

  static List<List<double>> _computeGridIntensities(
    List<SessionSummary> sessions, {
    required String leg,
  }) {
    final grid = List<List<double>>.generate(
      _gridRows,
      (r) => List<double>.filled(_gridCols, 0.0),
    );

    if (sessions.isEmpty) return grid;

    for (final session in sessions) {
      final activation = leg == 'left'
          ? (session.averageLeftActivation ?? session.averageActivation)
          : (session.averageRightActivation ?? session.averageActivation);
      _addActivationToGrid(grid, activation);
    }

    final avgFactor = sessions.length > 0 ? 1.0 / sessions.length : 1.0;
    for (int r = 0; r < _gridRows; r++) {
      for (int c = 0; c < _gridCols; c++) {
        grid[r][c] *= avgFactor;
        grid[r][c] = grid[r][c].clamp(0.0, 1.0);
      }
    }

    return grid;
  }

  static void _addActivationToGrid(List<List<double>> grid, double activation) {
    activation = activation.clamp(0.0, 1.0);

    for (int r = 0; r < _gridRows; r++) {
      for (int c = 0; c < _gridCols; c++) {
        final vertical = (r / (_gridRows - 1)).clamp(0.0, 1.0);
        final horizontal = (c / (_gridCols - 1) - 0.5).abs() * 2.0;
        final intensity =
            (1.0 - (vertical * 0.6 + horizontal * 0.4)) * activation;

        grid[r][c] += intensity;
      }
    }
  }

  static double _computeAverageSymmetry(List<SessionSummary> sessions) {
    if (sessions.isEmpty) return 0.0;

    double sum = 0.0;
    int count = 0;

    for (final session in sessions) {
      if (session.averageSymmetryIndex != null) {
        sum += session.averageSymmetryIndex!;
        count++;
      }
    }

    return count > 0 ? sum / count : 0.0;
  }
}

class SessionHeatmapData {
  final List<List<double>> leftIntensities;
  final List<List<double>> rightIntensities;
  final int sessionCount;
  final double averageSymmetry;

  SessionHeatmapData({
    required this.leftIntensities,
    required this.rightIntensities,
    required this.sessionCount,
    required this.averageSymmetry,
  });

  factory SessionHeatmapData.empty() {
    const rows = 14;
    const cols = 4;
    return SessionHeatmapData(
      leftIntensities: List<List<double>>.generate(
        rows,
        (r) => List<double>.filled(cols, 0.0),
      ),
      rightIntensities: List<List<double>>.generate(
        rows,
        (r) => List<double>.filled(cols, 0.0),
      ),
      sessionCount: 0,
      averageSymmetry: 0.0,
    );
  }

  bool get hasData => sessionCount > 0;
}
