import 'package:flutter/material.dart';
import '../domain/artifact_domain.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/localization.dart';

class AnalysisEditorDialog extends StatefulWidget {
  final Analysis? analysis;

  const AnalysisEditorDialog({super.key, this.analysis});

  @override
  State<AnalysisEditorDialog> createState() => _AnalysisEditorDialogState();
}

class _AnalysisEditorDialogState extends State<AnalysisEditorDialog> {
  late List<Evidence> _evidence;
  final Color _bgColor = const Color(0xFF0F0F0F);
  late Color _accentColor;

  @override
  void initState() {
    super.initState();
    _accentColor = AppTheme.kAccent;
    _evidence = widget.analysis?.evidence != null
        ? List.from(widget.analysis!.evidence)
        : [];
  }

  void _addEvidence() async {
    final result = await Navigator.push<Evidence>(
      context,
      MaterialPageRoute(builder: (context) => const EvidenceEditorScreen()),
    );
    if (result != null) setState(() => _evidence.add(result));
  }

  void _editEvidence(int index) async {
    final result = await Navigator.push<Evidence>(
      context,
      MaterialPageRoute(builder: (context) => EvidenceEditorScreen(initialEvidence: _evidence[index])),
    );
    if (result != null) setState(() => _evidence[index] = result);
  }

  void _saveAnalysis() {
    if (_evidence.isEmpty) {
      Navigator.pop(context, null);
    } else {
      Navigator.pop(context, Analysis(
        id: widget.analysis?.id ?? 'analysis_${DateTime.now().millisecondsSinceEpoch}',
        evidence: _evidence,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const TranslatedText('Analysis Builder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          const LanguageSwitcher(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton(
              onPressed: _saveAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const TranslatedText('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgColor, _bgColor.withOpacity(0)],
              ),
            ),
            child: Row(children: [
              _StatChip(value: '${_evidence.length}', label: 'Evidence Pieces', color: _accentColor),
              const Spacer(),
              if (_evidence.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: const Text('REORDERABLE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white24, fontSize: 8, letterSpacing: 1)),
                ),
            ]),
          ),
          const Divider(height: 1, color: Color(0x0DFFFFFF)),
          Expanded(
            child: _evidence.isEmpty
                ? _buildEmpty()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _evidence.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx--;
                        final e = _evidence.removeAt(oldIdx);
                        _evidence.insert(newIdx, e);
                      });
                    },
                    itemBuilder: (context, index) {
                      final e = _evidence[index];
                      return _EvidenceCard(
                        key: ValueKey('e_${e.questionText}_$index'),
                        evidence: e,
                        index: index,
                        onTap: () => _editEvidence(index),
                        onDelete: () => setState(() => _evidence.removeAt(index)),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _bgColor,
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: ElevatedButton.icon(
              onPressed: _addEvidence,
              icon: const Icon(Icons.add_task_rounded),
              label: const TranslatedText('Add Evidence Piece', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.psychology_rounded, size: 60, color: Colors.white.withOpacity(0.05)),
        const SizedBox(height: 16),
        const TranslatedText('No evidence items yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white24)),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final Evidence evidence;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EvidenceCard({super.key, required this.evidence, required this.index, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: AppTheme.kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('${index + 1}', style: const TextStyle(color: AppTheme.kAccent, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(evidence.questionText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1.4)),
                      const SizedBox(height: 12),
                      Text(
                        evidence.isShortAnswer
                            ? 'Open Observation • Answer: "${evidence.correctShortAnswer}"'
                            : '${evidence.options.length} Choices • Correct at index ${evidence.correctAnswerIndex + 1}',
                        style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
                      ),
                    ]),
                  ),
                  IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.white10, size: 20)),
                ]),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.black.withOpacity(0.2),
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 14, color: Colors.white24),
                  const SizedBox(width: 8),
                  const Text('EDIT EVIDENCE', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const Spacer(),
                  const Icon(Icons.drag_indicator, size: 16, color: Colors.white10),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class EvidenceEditorScreen extends StatefulWidget {
  final Evidence? initialEvidence;

  const EvidenceEditorScreen({super.key, this.initialEvidence});

  @override
  State<EvidenceEditorScreen> createState() => _EvidenceEditorScreenState();
}

class _EvidenceEditorScreenState extends State<EvidenceEditorScreen> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  final _shortAnswerController = TextEditingController();
  int _correctIndex = 0;
  bool _isShortAnswer = false;
  late Color _accentColor;

  @override
  void initState() {
    super.initState();
    _accentColor = AppTheme.kAccent;
    if (widget.initialEvidence != null) {
      _questionController.text = widget.initialEvidence!.questionText;
      _isShortAnswer = widget.initialEvidence!.isShortAnswer;
      if (_isShortAnswer) {
        _shortAnswerController.text = widget.initialEvidence!.correctShortAnswer ?? '';
        _optionControllers.add(TextEditingController());
        _optionControllers.add(TextEditingController());
      } else {
        for (var opt in widget.initialEvidence!.options) {
          _optionControllers.add(TextEditingController(text: opt));
        }
        _correctIndex = widget.initialEvidence!.correctAnswerIndex;
      }
    } else {
      _optionControllers.add(TextEditingController());
      _optionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _shortAnswerController.dispose();
    for (var c in _optionControllers) c.dispose();
    super.dispose();
  }

  void _save() {
    if (_questionController.text.isEmpty) return;
    if (_isShortAnswer) {
      if (_shortAnswerController.text.isEmpty) return;
      Navigator.pop(context, Evidence(
        questionText: _questionController.text,
        options: const [],
        correctAnswerIndex: 0,
        isShortAnswer: true,
        correctShortAnswer: _shortAnswerController.text,
      ));
    } else {
      if (_optionControllers.any((c) => c.text.isEmpty)) return;
      Navigator.pop(context, Evidence(
        questionText: _questionController.text,
        options: _optionControllers.map((c) => c.text).toList(),
        correctAnswerIndex: _correctIndex,
        isShortAnswer: false,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: TranslatedText(widget.initialEvidence != null ? 'Edit Evidence' : 'New Evidence Piece', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const TranslatedText('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('EVIDENCE TYPE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white24, fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(children: [
            _TypeChip(label: 'Multiple Choice', isSelected: !_isShortAnswer, onTap: () => setState(() => _isShortAnswer = false), accentColor: _accentColor),
            const SizedBox(width: 12),
            _TypeChip(label: 'Open Observation', isSelected: _isShortAnswer, onTap: () => setState(() => _isShortAnswer = true), accentColor: _accentColor),
          ]),
          const SizedBox(height: 32),
          const Text('EVIDENCE DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white24, fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          TextField(
            controller: _questionController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
            decoration: _inputDecoration('Describe the heritage evidence or observation...'),
          ),
          const SizedBox(height: 32),
          if (_isShortAnswer) ...[
            const Text('EXPECTED FINDING (TEXT)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white24, fontSize: 10, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            TextField(
              controller: _shortAnswerController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _inputDecoration('Enter the expected observation...'),
            ),
          ] else ...[
            Row(children: [
              const Text('VERIFICATION OPTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white24, fontSize: 10, letterSpacing: 1.2)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _optionControllers.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Option', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: _accentColor),
              ),
            ]),
            const SizedBox(height: 12),
            ..._optionControllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final isCorrect = idx == _correctIndex;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isCorrect ? _accentColor.withOpacity(0.08) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isCorrect ? _accentColor.withOpacity(0.4) : Colors.white.withOpacity(0.05)),
                ),
                child: Row(children: [
                  Radio<int>(
                    value: idx,
                    groupValue: _correctIndex,
                    onChanged: (v) => setState(() => _correctIndex = v!),
                    activeColor: _accentColor,
                    fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _accentColor : Colors.white24),
                  ),
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      style: TextStyle(color: isCorrect ? Colors.white : Colors.white70, fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter verification choice...',
                        hintStyle: TextStyle(color: Colors.white12),
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      onPressed: () => setState(() => _optionControllers.removeAt(idx)),
                      icon: const Icon(Icons.close, size: 16, color: Colors.white24),
                      splashRadius: 20,
                    ),
                  const SizedBox(width: 8),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _accentColor.withOpacity(0.5))),
      contentPadding: const EdgeInsets.all(20),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const _TypeChip({required this.label, required this.isSelected, required this.onTap, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? accentColor.withOpacity(0.4) : Colors.white.withOpacity(0.05)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
