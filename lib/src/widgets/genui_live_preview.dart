import 'package:flutter/material.dart';
import 'package:flutter_genui_kit/src/actions/genui_action_dispatcher.dart';
import 'package:flutter_genui_kit/src/controller/genui_controller.dart';
import 'package:flutter_genui_kit/src/rendering/genui_renderer.dart';
import 'package:flutter_genui_kit/src/theming/genui_theme_tokens.dart';
import 'package:flutter_genui_kit/src/widgets/genui_builder.dart';

class GenUiLivePreview extends StatefulWidget {
  const GenUiLivePreview({
    super.key,
    required this.controller,
    this.title = 'GenUI Live Preview',
    this.renderer,
    this.actionDispatcher,
    this.themeTokens,
    this.initialPrompt,
    this.promptHint = 'Describe the UI you want to render...',
    this.submitLabel = 'Generate UI',
    this.context = const {},
  });

  final GenUiController controller;
  final String title;
  final GenUiRenderer? renderer;
  final GenUiActionDispatcher? actionDispatcher;
  final GenUiThemeTokens? themeTokens;
  final String? initialPrompt;
  final String promptHint;
  final String submitLabel;
  final Map<String, Object?> context;

  @override
  State<GenUiLivePreview> createState() => _GenUiLivePreviewState();
}

class _GenUiLivePreviewState extends State<GenUiLivePreview> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialPrompt);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prompt = _textController.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    await widget.controller.applyPrompt(prompt, context: widget.context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EFE7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            final controls = _PreviewControls(
              title: widget.title,
              controller: widget.controller,
              textController: _textController,
              promptHint: widget.promptHint,
              submitLabel: widget.submitLabel,
              onSubmit: _submit,
            );

            final preview = ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFFFDFBF8), Color(0xFFF7F1E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: GenUiBuilder(
                  controller: widget.controller,
                  renderer: widget.renderer,
                  actionDispatcher: widget.actionDispatcher,
                  themeTokens: widget.themeTokens,
                  loading: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
              ),
            );

            return Padding(
              padding: const EdgeInsets.all(24),
              child: isCompact
                  ? Column(
                      children: <Widget>[
                        controls,
                        const SizedBox(height: 20),
                        Expanded(child: preview),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        SizedBox(
                          width: 360,
                          child: controls,
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: preview),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _PreviewControls extends StatelessWidget {
  const _PreviewControls({
    required this.title,
    required this.controller,
    required this.textController,
    required this.promptHint,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String title;
  final GenUiController controller;
  final TextEditingController textController;
  final String promptHint;
  final String submitLabel;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1A17),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ValueListenableBuilder<GenUiControllerState>(
          valueListenable: controller,
          builder: (context, state, child) {
            final statusColor = switch (state.status) {
              GenUiStatus.success => const Color(0xFF6ED39B),
              GenUiStatus.loading => const Color(0xFFF6C453),
              GenUiStatus.fallback => const Color(0xFFFF9B71),
              GenUiStatus.error => const Color(0xFFFF7A7A),
              GenUiStatus.idle => const Color(0xFFD7C7B6),
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Prompt your runtime UI, validate the payload, and keep the last good screen alive when generation goes sideways.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFD7C7B6),
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Status: ${state.status.name}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: textController,
                  maxLines: 8,
                  minLines: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: promptHint,
                    hintStyle: const TextStyle(color: Color(0xFF9F968A)),
                    filled: true,
                    fillColor: const Color(0xFF26231F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.status == GenUiStatus.loading ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFA24B2A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(submitLabel),
                  ),
                ),
                const SizedBox(height: 20),
                if (state.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF33211E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA24B2A)),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Color(0xFFF8D9CC)),
                    ),
                  ),
                if (state.diagnostics.hasWarnings) ...<Widget>[
                  const SizedBox(height: 20),
                  Text(
                    'Diagnostics',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171614),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4B463F)),
                    ),
                    child: Text(
                      [
                        ...state.diagnostics.appliedMigrations.map(
                          (migration) => 'Migration applied: $migration',
                        ),
                        ...state.diagnostics.warnings,
                      ].join('\n'),
                      style: const TextStyle(color: Color(0xFFD7C7B6), height: 1.5),
                    ),
                  ),
                ],
                if (state.rawPayload != null) ...<Widget>[
                  const SizedBox(height: 20),
                  Text(
                    'Last payload',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF12110F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          state.rawPayload!,
                          style: const TextStyle(
                            color: Color(0xFFD7C7B6),
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
              ],
            );
          },
        ),
      ),
    );
  }
}
