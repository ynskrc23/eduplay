import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/models/game_session.dart';
import '../../../data/repositories/game_session_repository.dart';

class ParentPanelScreen extends StatefulWidget {
  final ChildProfile childProfile;

  const ParentPanelScreen({super.key, required this.childProfile});

  @override
  State<ParentPanelScreen> createState() => _ParentPanelScreenState();
}

class _ParentPanelScreenState extends State<ParentPanelScreen> {
  final GameSessionRepository _sessionRepo = GameSessionRepository();
  List<GameSession> _lastSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await _sessionRepo.getLastSessions(widget.childProfile.id!, 7);
    // Reverse to show oldest to newest (left to right) if needed, but lastSessions gives desc.
    // We want to show time progression left-to-right, so we should reverse the DESC list.
    if (mounted) {
      setState(() {
        _lastSessions = sessions.reversed.toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ebeveyn Paneli'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'Son Performanslar (Doğru Sayısı)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildChart(),
                  const SizedBox(height: 24),
                  _buildStatsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade100,
            shape: BoxShape.circle,
          ),
          child: Text(
            widget.childProfile.avatarId,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          widget.childProfile.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text('Toplam Puan: ${widget.childProfile.totalScore}'),
      ),
    );
  }

  Widget _buildChart() {
    if (_lastSessions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Henüz veri yok.')),
      );
    }

    return SizedBox(
      height: 250,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 10, // Assuming max 10 for better viz, or dynamic
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                 getTooltipColor: (_) => Colors.blueGrey,
                 getTooltipItem: (group, groupIndex, rod, rodIndex) {
                   return BarTooltipItem(
                     '${rod.toY.round()} Doğru',
                     const TextStyle(color: Colors.white),
                   );
                 }
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < _lastSessions.length) {
                        final date = _lastSessions[value.toInt()].startedAt;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('d/M').format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barGroups: _lastSessions.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.correctCount.toDouble(),
                      color: Colors.green,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsList() {
    if (_lastSessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Oyun Geçmişi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _lastSessions.length, // Already reversed in loadData to be Old->New, here maybe want New->Old?
          // Actually list usually shows newest first.
          itemBuilder: (context, index) {
            // Re-reverse for list view (Newest first)
            final session = _lastSessions[_lastSessions.length - 1 - index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  session.correctCount >= 5 ? Icons.star : Icons.gamepad,
                  color: session.correctCount >= 5 ? Colors.amber : Colors.grey,
                ),
                title: Text(DateFormat('d MMMM y, HH:mm', 'tr_TR').format(session.startedAt)),
                subtitle: Text(session.endedAt != null 
                  ? 'Süre: ${session.endedAt!.difference(session.startedAt).inMinutes} dk ${session.endedAt!.difference(session.startedAt).inSeconds % 60} sn'
                  : 'Süre: -'),
                trailing: Text(
                  '${session.correctCount} Doğru / ${session.wrongCount} Yanlış',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: session.correctCount >= 5 ? Colors.green : Colors.black87,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
