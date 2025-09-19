import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../state/logs_state.dart';
import '../widgets/logs_widget/logs_panel.dart';


class GenerateCCTab extends StatefulWidget {
  final LogsState logsState;

  GenerateCCTab({super.key, LogsState? logsState})
      : logsState = logsState ?? LogsState();

  @override
  State<GenerateCCTab> createState() => _GenerateCCTabState();
}

class _GenerateCCTabState extends State<GenerateCCTab> {
  bool _showLogs = false;
  // Removed unused _error per lint
  String _selectedModel = 'tiny';
  String _selectedLanguage = 'English';
  String _selectedFormat = '.srt';
  final List<String> _files = [];

  void _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'mp4', 'mkv', 'avi', 'mov', 'flac', 'aac', 'ogg', 'webm'],
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

  // Removed unused _onDropFiles per lint

  @override
  Widget build(BuildContext context) {
    // Removed unused theme per lint
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
                  initialValue: _selectedModel,
                  decoration: InputDecoration(labelText: 'Model'),
                  items: ['tiny', 'base', 'small', 'medium', 'large']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedModel = v ?? 'tiny'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: InputDecoration(labelText: 'Language'),
                  items: ['English', 'Spanish', 'French', 'German', 'Chinese']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLanguage = v ?? 'English'),
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
                  onChanged: (v) => setState(() => _selectedFormat = v ?? '.srt'),
                ),
              ),
            ],
          ),
        ),
        // Main body: drag-and-drop + add button + file list
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Icon(Icons.cloud_upload, size: 48, color: Colors.purpleAccent),
                      SizedBox(height: 8),
                      Text('Drag & drop audio/video files here', style: TextStyle(fontSize: 16)),
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
                icon: Icon(Icons.subtitles),
                label: Text('Generate Subtitles'),
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
