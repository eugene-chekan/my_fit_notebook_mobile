import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/profile.dart';
import '../l10n/app_localizations.dart';
import '../state/profile_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../utils/metric_labels.dart';
import '../utils/units.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/pen_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileProvider _provider;
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _birthDate;
  bool _initializedFields = false;

  @override
  void initState() {
    super.initState();
    _provider = ProfileProvider()..load();
    _provider.addListener(_syncFieldsOnce);
  }

  void _syncFieldsOnce() {
    final profile = _provider.profile;
    if (_initializedFields || profile == null) return;
    _nameController.text = profile.name;
    _birthDate = profile.birthDate;
    _syncHeightField(profile);
    _initializedFields = true;
  }

  void _syncHeightField(Profile profile) {
    final heightCm = profile.heightCm;
    _heightController.text =
        heightCm == null ? '' : formatNumber(heightToDisplay(heightCm, profile.units));
  }

  @override
  void dispose() {
    _provider.removeListener(_syncFieldsOnce);
    _nameController.dispose();
    _heightController.dispose();
    _provider.dispose();
    super.dispose();
  }

  String get _units => _provider.profile?.units ?? Units.metric;

  Future<void> _saveDetails() async {
    double? heightCm;
    final heightInput = parseDisplayNumber(_heightController.text);
    if (heightInput != null) {
      heightCm = heightToCanonical(heightInput, _units);
    }
    await _provider.saveDetails(
      name: _nameController.text,
      birthDate: _birthDate,
      heightCm: heightCm,
    );
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    var initial = DateTime(now.year - 30, now.month, now.day);
    if (_birthDate != null) {
      try {
        initial = DateTime.parse(_birthDate!);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthDate =
            '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _toggleUnits() async {
    await _provider.toggleUnits();
    final profile = _provider.profile;
    if (profile != null) _syncHeightField(profile);
  }

  Future<void> _logMeasurement(BodyMetric metric) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController();
    final value = await showPaperDialog<double>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.logMetric(localizedMetric(context, metric.key)),
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: NotebookColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            cursorColor: NotebookColors.ink,
            style: const TextStyle(fontFamily: 'Caveat', fontSize: 22, color: NotebookColors.ink),
            decoration: InputDecoration(
              isDense: true,
              suffixText: unitSuffix(metric, _units),
              suffixStyle: const TextStyle(
                fontFamily: 'Caveat',
                fontSize: 18,
                color: NotebookColors.inkSoft,
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: NotebookColors.ink),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: NotebookColors.ink, width: 2),
              ),
            ),
            onSubmitted: (v) => Navigator.pop(context, parseDisplayNumber(v)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PenButton(
                label: t.cancel,
                small: true,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              PenButton(
                label: t.save,
                small: true,
                onPressed: () =>
                    Navigator.pop(context, parseDisplayNumber(controller.text)),
              ),
            ],
          ),
        ],
      ),
    );
    if (value != null) {
      await _provider.addMeasurement(metric.key, toCanonical(value, metric, _units));
    }
  }

  Future<void> _openHistory(BodyMetric metric) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NotebookColors.paper,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: NotebookColors.ink, width: 2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _MeasurementHistorySheet(provider: _provider, metric: metric),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const NotebookDrawer(),
        body: SafeArea(
          child: NotebookPage(
            marginChild: GlyphButton(
              glyph: '≡',
              size: 26,
              semanticLabel: t.menu,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            child: Consumer<ProfileProvider>(
              builder: (context, provider, _) {
                final profile = provider.profile;
                if (profile == null) return const SizedBox.shrink();
                _syncFieldsOnce();
                final age = ageFromBirthDate(_birthDate);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NotebookHeader(title: t.navProfile, leading: const BackGlyph()),
                    const SizedBox(height: 8),
                    HeadingLine(t.aboutMe),
                    _fieldLabel(t.fieldName),
                    TextField(
                      controller: _nameController,
                      maxLength: 200,
                      cursorColor: NotebookColors.ink,
                      style: const TextStyle(fontFamily: 'Caveat', fontSize: 20),
                      decoration: _underline(),
                    ),
                    const SizedBox(height: 10),
                    _fieldLabel(t.fieldBorn),
                    InkWell(
                      onTap: _pickBirthDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: NotebookColors.ink),
                          ),
                        ),
                        child: Text(
                          _birthDate == null
                              ? t.pickDateHint
                              : '${formatCompletionDt(_birthDate!)}'
                                  '${age != null ? '  ${t.ageYears(age)}' : ''}',
                          style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 20,
                            color: _birthDate == null
                                ? NotebookColors.inkSoft
                                : NotebookColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _fieldLabel(t.fieldHeight),
                    TextField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: NotebookColors.ink,
                      style: const TextStyle(fontFamily: 'Caveat', fontSize: 20),
                      decoration: _underline().copyWith(
                        suffixText: heightSuffix(profile.units),
                        suffixStyle: const TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 18,
                          color: NotebookColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _unitsLine(profile.units),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PenButton(label: t.saveDetails, onPressed: _saveDetails),
                    ),
                    const SizedBox(height: 16),
                    HeadingLine(t.measurements),
                    for (final metric in kBodyMetrics)
                      _metricRow(metric, provider),
                    const SizedBox(height: 8),
                    MutedLine(t.measurementsHint),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Caveat',
          fontSize: 17,
          fontStyle: FontStyle.italic,
          color: NotebookColors.inkSoft,
        ),
      ),
    );
  }

  InputDecoration _underline() {
    return const InputDecoration(
      isDense: true,
      counterText: '',
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: NotebookColors.ink),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: NotebookColors.ink, width: 2),
      ),
    );
  }

  /// "units: kg · cm / lb · in" — the active choice in ink, tap to switch.
  Widget _unitsLine(String units) {
    final metricActive = units == Units.metric;
    TextStyle style(bool active) => TextStyle(
      fontFamily: 'Caveat',
      fontSize: 19,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      color: active ? NotebookColors.ink : NotebookColors.inkSoft,
    );
    return Row(
      children: [
        Text(
          '${AppLocalizations.of(context).unitsLabel}  ',
          style: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 17,
            fontStyle: FontStyle.italic,
            color: NotebookColors.inkSoft,
          ),
        ),
        InkWell(
          onTap: metricActive ? null : _toggleUnits,
          child: Text('kg · cm', style: style(metricActive)),
        ),
        Text('   /   ', style: style(false)),
        InkWell(
          onTap: metricActive ? _toggleUnits : null,
          child: Text('lb · in', style: style(!metricActive)),
        ),
      ],
    );
  }

  Widget _metricRow(BodyMetric metric, ProfileProvider provider) {
    final t = AppLocalizations.of(context);
    final latest = provider.latest[metric.key];
    final target = provider.targets[metric.key];
    final label = localizedMetric(context, metric.key);
    return SizedBox(
      height: kNotebookLine,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openHistory(metric),
              child: Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.only(bottom: 3),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 20,
                      color: NotebookColors.ink,
                    ),
                    children: [
                      TextSpan(text: label),
                      TextSpan(
                        text: latest == null
                            ? '   —'
                            : '   ${formatMeasurement(latest.value, metric, _units)}',
                        style: TextStyle(
                          color: latest == null
                              ? NotebookColors.inkSoft
                              : NotebookColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (target != null)
                        TextSpan(
                          text: '  → ${formatMeasurement(target, metric, _units)}',
                          style: const TextStyle(color: NotebookColors.inkSoft),
                        ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          GlyphButton(
            glyph: '+',
            size: 24,
            color: NotebookColors.ink,
            semanticLabel: t.logMetric(label),
            onTap: () => _logMeasurement(metric),
          ),
        ],
      ),
    );
  }
}

/// Paper bottom sheet with one metric's goal editor and dated history.
class _MeasurementHistorySheet extends StatefulWidget {
  const _MeasurementHistorySheet({required this.provider, required this.metric});

  final ProfileProvider provider;
  final BodyMetric metric;

  @override
  State<_MeasurementHistorySheet> createState() => _MeasurementHistorySheetState();
}

class _MeasurementHistorySheetState extends State<_MeasurementHistorySheet> {
  final _goalController = TextEditingController();

  String get _units => widget.provider.profile?.units ?? Units.metric;

  @override
  void initState() {
    super.initState();
    final target = widget.provider.targets[widget.metric.key];
    if (target != null) {
      _goalController.text = formatNumber(toDisplay(target, widget.metric, _units));
    }
    widget.provider.addListener(_onProviderChange);
  }

  void _onProviderChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderChange);
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final input = parseDisplayNumber(_goalController.text);
    if (input == null) {
      await widget.provider.clearTarget(widget.metric.key);
    } else {
      await widget.provider.setTarget(
        widget.metric.key,
        toCanonical(input, widget.metric, _units),
      );
    }
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final metric = widget.metric;
    return FutureBuilder(
      future: widget.provider.history(metric.key),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizedMetric(context, metric.key),
                style: const TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: NotebookColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${t.goalLabel}  ',
                    style: const TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 19,
                      fontStyle: FontStyle.italic,
                      color: NotebookColors.inkSoft,
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _goalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: NotebookColors.ink,
                      style: const TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 20,
                        color: NotebookColors.ink,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        suffixText: unitSuffix(metric, _units),
                        suffixStyle: const TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 17,
                          color: NotebookColors.inkSoft,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: NotebookColors.ink),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: NotebookColors.ink, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _saveGoal(),
                    ),
                  ),
                  GlyphButton(
                    glyph: '✓',
                    color: NotebookColors.ink,
                    semanticLabel: t.saveGoalSemantic,
                    onTap: _saveGoal,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (entries.isEmpty)
                Text(
                  t.noEntries,
                  style: const TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 18,
                    color: NotebookColors.inkSoft,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${formatCompletionDt(entry.measuredOn)}   '
                              '${formatMeasurement(entry.value, metric, _units)}',
                              style: const TextStyle(
                                fontFamily: 'Caveat',
                                fontSize: 19,
                                color: NotebookColors.ink,
                              ),
                            ),
                          ),
                          GlyphButton(
                            glyph: '×',
                            size: 22,
                            semanticLabel: t.deleteEntrySemantic,
                            onTap: () => widget.provider.deleteMeasurement(entry.id),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
