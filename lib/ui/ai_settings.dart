import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ai/gemini_service.dart';
import '../theme.dart';
import '../store.dart';
import 'common.dart';
import 'copilot_memory.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _controller = TextEditingController();
  final _gemini = const GeminiService();
  bool _hasKey = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final value = await _gemini.hasApiKey();
    if (mounted) setState(() => _hasKey = value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      _snack('Cole uma chave do Gemini antes de testar.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _gemini.validateApiKey(key);
      await _gemini.saveApiKey(key);
      _controller.clear();
      if (!mounted) return;
      setState(() => _hasKey = true);
      _snack('Chave validada e salva com segurança neste aparelho.');
    } on GeminiApiException catch (error) {
      _snack(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    await _gemini.deleteApiKey();
    _controller.clear();
    if (!mounted) return;
    setState(() => _hasKey = false);
    _snack('Chave do Gemini removida deste aparelho.');
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finora IA')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('GEMINI', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: FinoraColors.investment.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: FinoraColors.investment,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gemini 3.5 Flash-Lite',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            _hasKey
                                ? 'Chave configurada neste aparelho'
                                : 'Nenhuma chave configurada',
                            style: const TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _hasKey
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: _hasKey
                          ? FinoraColors.income
                          : FinoraColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: _hasKey
                        ? 'Substituir chave'
                        : 'Chave da API Gemini',
                    hintText: 'Cole uma nova Auth API Key do Google AI Studio',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _saveAndTest,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_done_outlined),
                    label: Text(
                      _busy ? 'Testando...' : 'Testar e salvar chave',
                    ),
                  ),
                ),
                if (_hasKey) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _busy ? null : _remove,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Remover chave deste aparelho'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('COPILOT', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.psychology_alt_outlined,
                    color: FinoraColors.investment,
                  ),
                  title: const Text(
                    'Memória contextual',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${context.watch<FinanceStore>().data.copilotMemories.length} lembrança(s) salva(s) · você mantém o controle',
                    style: const TextStyle(fontSize: 8.5),
                  ),
                  value: context
                      .watch<FinanceStore>()
                      .data
                      .copilotMemoryEnabled,
                  onChanged: context
                      .read<FinanceStore>()
                      .setCopilotMemoryEnabled,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.memory_rounded),
                  title: const Text(
                    'Ver e editar memória',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Revise, edite ou apague tudo o que o Copilot lembra',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    PremiumRoute(page: const CopilotMemoryScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('PRIVACIDADE', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          const SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(
                  icon: Icons.lock_outline_rounded,
                  title: 'A chave não vai para o GitHub',
                  body:
                      'Ela é informada por você e armazenada pelo cofre seguro do sistema operacional.',
                ),
                Divider(),
                _InfoLine(
                  icon: Icons.visibility_off_outlined,
                  title: 'IA desligada por padrão',
                  body:
                      'O Finora só envia dados quando você toca em interpretar, analisar ou perguntar.',
                ),
                Divider(),
                _InfoLine(
                  icon: Icons.filter_alt_outlined,
                  title: 'Contexto reduzido',
                  body:
                      'O assistente envia agregados, até 35 movimentações recentes e 25 previstos. O backup completo e notas privadas não são enviados.',
                ),
                Divider(),
                _InfoLine(
                  icon: Icons.info_outline_rounded,
                  title: 'Free Tier do Gemini',
                  body:
                      'O nível gratuito pode usar o conteúdo enviado para melhorar produtos do Google. Não use a IA para dados que você não queira transmitir.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SurfaceCard(
            child: Text(
              'Crie uma nova Auth API Key no Google AI Studio. Chaves antigas do tipo Standard estão sendo descontinuadas; prefira uma chave nova criada diretamente no AI Studio.',
              style: TextStyle(
                fontSize: 9.5,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoLine({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: FinoraColors.goldBright),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 8.8, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
