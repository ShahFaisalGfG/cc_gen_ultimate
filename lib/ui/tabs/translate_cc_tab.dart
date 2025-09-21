import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/logs_state.dart';
import '../widgets/logs_widget/logs_panel.dart';

class TranslateCCTab extends StatefulWidget {
  final LogsState logsState;

  TranslateCCTab({super.key, LogsState? logsState})
    : logsState = logsState ?? LogsState();

  @override
  State<TranslateCCTab> createState() => _TranslateCCTabState();
}

class _TranslateCCTabState extends State<TranslateCCTab> {
  bool _showLogs = false;
  String _selectedSourceLanguage = 'English';
  String _selectedTargetLanguage = 'Spanish';
  String _selectedFormat = '.srt';
  final List<String> _files = [];

  void _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt', 'txt'],
    );
    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (!_files.contains(file.name)) {
            _files.add(file.name);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with preferences in a styled container
        Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSourceLanguage,
                  decoration: InputDecoration(labelText: 'Source Language'),
                  items: ['English', 'Spanish', 'French', 'German', 'Chinese']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedSourceLanguage = v ?? 'English'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTargetLanguage,
                  decoration: InputDecoration(labelText: 'Target Language'),
                  items: ['English', 'Spanish', 'French', 'German', 'Chinese']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedTargetLanguage = v ?? 'Spanish'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedFormat,
                  decoration: InputDecoration(labelText: 'Format'),
                  items: ['.srt', '.vtt', '.txt']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedFormat = v ?? '.srt'),
                ),
              ),
            ],
          ),
        ),
        // Main body: drag-and-drop + add button + file list
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('+ Add'),
                      onPressed: _pickFiles,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 48,
                              color: Colors.purpleAccent,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Drag & drop subtitle files here',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: Icon(Icons.add),
                              label: Text('+ Add'),
                              onPressed: _pickFiles,
                            ),
                          ],
                        ),
                      ),
                      if (_files.isNotEmpty)
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _files.map((f) => Text(f)).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Footer area
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
                icon: Icon(Icons.translate),
                label: Text('Translate Subtitles'),
                onPressed: () {},
              ),
            ],
          ),
        ),
        if (_showLogs) ...[
          const SizedBox(height: 8),
          ChangeNotifierProvider.value(
            value: widget.logsState,
            child: LogsPanel(showLogs: true),
          ),
        ],
      ],
    );
  }
}
