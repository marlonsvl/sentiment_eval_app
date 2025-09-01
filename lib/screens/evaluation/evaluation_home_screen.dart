import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/evaluation_session.dart';
import 'sentence_evaluation_screen.dart';

class EvaluationHomeScreen extends StatefulWidget {
  const EvaluationHomeScreen({super.key});

  @override
  State<EvaluationHomeScreen> createState() => _EvaluationHomeScreenState();
}

class _EvaluationHomeScreenState extends State<EvaluationHomeScreen> {
  List<EvaluationSession> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unevaluatedCount = 0; // Track available unevaluated sentences
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSessionsAndStats();
  }

  Future<void> _loadSessionsAndStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (!authService.isAuthenticated) {
        setState(() {
          _errorMessage = 'Please login first';
          _isLoading = false;
        });
        return;
      }

      final apiService = ApiService();

      if (authService.token != null) {
        await apiService.setToken(authService.token!);
      }
      Map<String, dynamic> stats = await apiService.getEvaluationStats();

      // Load sessions and unevaluated count in parallel
      final futures = await Future.wait([
        apiService.getSessions(evaluatorId: authService.currentUser?.id),
        _getUnevaluatedCount(apiService),
      ]);

      final sessions = futures[0] as List<EvaluationSession>;
      if (sessions.isNotEmpty) {
        _isEnabled = false;
      }
      //final unevaluatedCount = futures[1] as int;
      final unevaluatedCount = stats['unevaluated_sentences'] ?? 0;

      setState(() {
        _sessions = sessions;
        _unevaluatedCount = unevaluatedCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });

      if (e.toString().contains('UnauthorizedException')) {
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.logout();
      }
    }
  }

  Future<int> _getUnevaluatedCount(ApiService apiService) async {
    try {
      // Get first page to check total count
      final sentences = await apiService.getUnevaluatedSentences(
        //page: 1,
        //pageSize: 2000,
      );

      // If your API returns pagination info, use it
      // Otherwise, you might need to modify your backend to return count
      // For now, we'll do a simple check
      if (sentences.isEmpty) {
        return 0;
      } else {
        // Get a larger sample to estimate total
        final largeSample = await apiService.getUnevaluatedSentences(
          page: 1,
          pageSize: 100,
        );
        return largeSample.length;
      }
    } catch (e) {
      print('Error getting unevaluated count: $e');
      return 0;
    }
  }

  Future<void> _startNewEvaluation() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = ApiService();

      if (authService.token != null) {
        await apiService.setToken(authService.token!);
      }

      final session = await apiService.startSession();

      if (mounted) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) =>
                    SentenceEvaluationScreen(sessionId: session.id),
              ),
            )
            .then((_) => _loadSessionsAndStats());
      }
      setState(() {
        _isEnabled = false; // Disable the button after the first click
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start evaluation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluation Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessionsAndStats,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authService.logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      /*floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Quick evaluate unevaluated sentences
          if (_unevaluatedCount > 0) ...[
            FloatingActionButton.extended(
              heroTag: "unevaluated",
              onPressed: _startUnevaluatedEvaluation,
              label: Text('Evaluate ($_unevaluatedCount)'),
              icon: const Icon(Icons.flash_on),
              backgroundColor: Colors.green,
            ),
            const SizedBox(height: 16),
          ],
          // Start new session
          FloatingActionButton(
            heroTag: "session",
            onPressed: _startNewEvaluation,
            child: const Icon(Icons.add),
            tooltip: 'Start New Session',
          ),
        ],
      ),*/
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSessionsAndStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessionsAndStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evaluation Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          'Unevaluated Sentences',
                          _unevaluatedCount.toString(),
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                        _buildStatItem(
                          'Active Sessions',
                          _sessions.where((s) => s.isActive).length.toString(),
                          Icons.play_arrow,
                          Colors.green,
                        ),
                        _buildStatItem(
                          'Total Sessions',
                          _sessions.length.toString(),
                          Icons.assignment,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions
            /*if (_unevaluatedCount > 0) ...[
              Card(
                color: Colors.green[50],
                child: ListTile(
                  leading: const Icon(Icons.flash_on, color: Colors.green),
                  title: const Text('Quick Evaluation'),
                  subtitle: Text(
                    '$_unevaluatedCount sentences ready for evaluation',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _startUnevaluatedEvaluation,
                ),
              ),
              const SizedBox(height: 16),
            ],*/

            // Sessions section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evaluation Sessions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _isEnabled ? _startNewEvaluation : null,
                  icon: const Icon(Icons.add),
                  label: const Text('New Session'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_sessions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No evaluation sessions found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a session to organize your evaluations',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(session.sessionName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${session.completedSentences}/${session.totalSentences} completed',
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: session.progress,
                            backgroundColor: Colors.grey[300],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (session.isActive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) => SentenceEvaluationScreen(
                                  sessionId: session.id,
                                ),
                              ),
                            )
                            .then((_) => _loadSessionsAndStats());
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
