import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cc_gen_ultimate/models/model_info.dart';
import 'package:cc_gen_ultimate/controllers/model_controller.dart';
import 'package:intl/intl.dart';
// Add these imports for logs panel
import '../../state/logs_state.dart';
import '../../ui/widgets/logs_panel.dart';

class ModelsAndLanguagesTab extends StatefulWidget {
  const ModelsAndLanguagesTab({super.key});

  @override
  State<ModelsAndLanguagesTab> createState() => _ModelsAndLanguagesTabState();
}

class _ModelsAndLanguagesTabState extends State<ModelsAndLanguagesTab> {
  bool _showLogs = false;
  final LogsState _logsState = LogsState();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ModelController(),
      child: Consumer<ModelController>(
        builder: (context, controller, _) {
          final models = controller.models;
          return Column(
            children: [
              // Header with controls
              _buildHeader(context),
              // Search and filter bar
              _buildSearchBar(context),
              // Main content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ListView.builder(
                    itemCount: models.length,
                    itemBuilder: (context, index) => _buildModelCard(context, models[index]),
                  ),
                ),
              ),
              // Footer with Show Logs and Download button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: Icon(_showLogs ? Icons.visibility_off : Icons.visibility),
                      label: Text(_showLogs ? 'Hide Logs' : 'Show Logs'),
                      onPressed: () {
                        setState(() => _showLogs = !_showLogs);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      onPressed: () {
                        // You can implement bulk download or open download dialog here
                        // For now, just show a snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Download action triggered')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_showLogs) ...[
                const SizedBox(height: 8),
                ChangeNotifierProvider.value(
                  value: _logsState,
                  child: const LogsPanel(showLogs: true),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final controller = context.watch<ModelController>();
    final downloadedCount = controller.models
        .where((m) => m.status == ModelStatus.downloaded)
        .length;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Show: '),
              const SizedBox(width: 8),
              DropdownButton<ModelType>(
                value: controller.selectedType,
                items: ModelType.values.map((type) {
                  final name = type == ModelType.whisperAI ? 'Whisper AI' : 'LibreTranslate';
                  return DropdownMenuItem(value: type, child: Text(name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) controller.setSelectedType(val);
                },
              ),
              const Spacer(),
              Text('$downloadedCount models installed'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Sort by: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Name'),
                selected: controller.sortBy == 'name',
                onSelected: (selected) {
                  if (selected) controller.setSortBy('name');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Size'),
                selected: controller.sortBy == 'size',
                onSelected: (selected) {
                  if (selected) controller.setSortBy('size');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Last Used'),
                selected: controller.sortBy == 'date',
                onSelected: (selected) {
                  if (selected) controller.setSortBy('date');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final controller = context.watch<ModelController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        onChanged: controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search models...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.deepPurple.withAlpha(20),
        ),
      ),
    );
  }

  Widget _buildModelCard(BuildContext context, ModelInfo model) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              model.type == ModelType.libreTranslate 
                ? context.read<ModelController>().modelService.getLanguageName(model.name)
                : model.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (model.isVerified)
              const Icon(Icons.verified, color: Colors.green, size: 16),
            if (model.updateAvailable)
              const Icon(Icons.system_update, color: Colors.orange, size: 16),
          ],
        ),
        subtitle: Text(
          '${model.formattedSize} | ${model.formattedVram} VRAM required',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version: ${model.version}'),
                const SizedBox(height: 4),
                Text(model.type == ModelType.libreTranslate
                  ? 'Translate between ${context.read<ModelController>().modelService.getLanguageName(model.name)} and other downloaded languages'
                  : 'Capabilities: ${model.capabilities}'),
                const SizedBox(height: 4),
                if (model.type != ModelType.libreTranslate) 
                  Text('Languages: ${model.supportedLanguages.join(", ")}'),
                if (model.lastUsed != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last used: ${DateFormat.yMMMd().add_Hm().format(model.lastUsed!)}',
                  ),
                ],
                if (model.status == ModelStatus.downloading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: model.downloadProgress! / 100,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Downloading: ${model.downloadProgress!.toStringAsFixed(1)}% | ${model.downloadSpeed} MB/s',
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (model.status == ModelStatus.downloaded) ...[
                      TextButton.icon(
                        icon: const Icon(Icons.verified),
                        label: const Text('Verify'),
                        onPressed: () {
                          context.read<ModelController>().verifyModel(model.name);
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        onPressed: () {
                          context.read<ModelController>().deleteModel(model.name);
                        },
                      ),
                    ] else if (model.status == ModelStatus.available) ...[
                      TextButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        onPressed: () {
                          context.read<ModelController>().downloadModel(model.name);
                        },
                      ),
                    ] else if (model.status == ModelStatus.downloading) ...[
                      TextButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        onPressed: () {
                          context.read<ModelController>().cancelDownload(model.name);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
